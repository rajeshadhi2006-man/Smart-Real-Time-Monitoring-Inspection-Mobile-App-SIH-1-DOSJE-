import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/user_location.dart';
import 'api_service.dart';
import 'geofence_service.dart';
import '../providers/auth_provider.dart';
import '../providers/geofence_provider.dart';

enum LocationServiceStatus {
  idle,
  checkingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  trackingActive,
  trackingPaused,
  error,
}

class LocationTrackingState {
  final LocationServiceStatus status;
  final UserLocation? currentLocation;
  final List<UserLocation> locationHistory;
  final String? errorMessage;
  final int offlineQueueCount;
  final String? activeSessionId;
  final DateTime? lastSyncTime;
  final bool isOnline;

  const LocationTrackingState({
    required this.status,
    this.currentLocation,
    this.locationHistory = const [],
    this.errorMessage,
    this.offlineQueueCount = 0,
    this.activeSessionId,
    this.lastSyncTime,
    this.isOnline = true,
  });

  bool get isTracking => status == LocationServiceStatus.trackingActive;

  LocationTrackingState copyWith({
    LocationServiceStatus? status,
    UserLocation? currentLocation,
    List<UserLocation>? locationHistory,
    String? errorMessage,
    int? offlineQueueCount,
    String? activeSessionId,
    DateTime? lastSyncTime,
    bool? isOnline,
  }) {
    return LocationTrackingState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      locationHistory: locationHistory ?? this.locationHistory,
      errorMessage: errorMessage,
      offlineQueueCount: offlineQueueCount ?? this.offlineQueueCount,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Production Location Service managing GPS stream, offline queue,
/// battery-optimized distance filter, and FastAPI REST endpoint transmission.
class LocationTrackingNotifier extends StateNotifier<LocationTrackingState> {
  final ApiService _apiService;
  final GeofenceService? _geofenceService;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const int maxOfflineQueueCapacity = 100;
  final Queue<UserLocation> _offlineQueue = Queue<UserLocation>();

  static const int distanceFilterMeters = 10;
  static const int minTimeBetweenUpdatesSeconds = 5;
  DateTime? _lastDispatchedTime;

  LocationTrackingNotifier({
    ApiService? apiService,
    GeofenceService? geofenceService,
  })  : _apiService = apiService ?? ApiService(),
        _geofenceService = geofenceService,
        super(const LocationTrackingState(status: LocationServiceStatus.idle)) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final bool online = !results.contains(ConnectivityResult.none);
      state = state.copyWith(isOnline: online);
      if (online && _offlineQueue.isNotEmpty) {
        _flushOfflineQueue();
      }
    });
  }

  Future<bool> checkPermission() async {
    state = state.copyWith(status: LocationServiceStatus.checkingPermission);

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        status: LocationServiceStatus.gpsDisabled,
        errorMessage: 'GPS is disabled on this device. Please turn on Location Services.',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          status: LocationServiceStatus.permissionDenied,
          errorMessage: 'Location permission was denied. Tap to grant permission.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: LocationServiceStatus.permissionPermanentlyDenied,
        errorMessage: 'Location permissions are permanently denied. Please enable them in App Settings.',
      );
      return false;
    }

    return true;
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> startTracking({
    String userId = 'GOV-OFFICER-001',
    String? geofenceId,
  }) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return;

    final sessionId = const Uuid().v4();

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _handleNewPosition(initialPosition, userId, sessionId);
    } catch (e) {
      developer.log('Initial location fetch failed: $e. Falling back to stream.');
    }

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );

    await _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) => _handleNewPosition(position, userId, sessionId),
      onError: (err) {
        state = state.copyWith(
          status: LocationServiceStatus.error,
          errorMessage: 'Location error: $err',
        );
      },
    );

    state = state.copyWith(
      status: LocationServiceStatus.trackingActive,
      activeSessionId: sessionId,
      errorMessage: null,
    );
  }

  void _handleNewPosition(Position pos, String userId, String sessionId) {
    final now = DateTime.now();

    final userLocation = UserLocation(
      userId: userId,
      trackingSessionId: sessionId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      speed: pos.speed,
      heading: pos.heading,
      timestamp: pos.timestamp,
    );

    final updatedHistory = List<UserLocation>.from(state.locationHistory)..add(userLocation);
    if (updatedHistory.length > 50) {
      updatedHistory.removeAt(0);
    }

    state = state.copyWith(
      currentLocation: userLocation,
      locationHistory: updatedHistory,
      status: LocationServiceStatus.trackingActive,
      errorMessage: null,
    );

    if (_lastDispatchedTime != null &&
        now.difference(_lastDispatchedTime!).inSeconds < minTimeBetweenUpdatesSeconds) {
      return;
    }
    _lastDispatchedTime = now;

    _dispatchLocationUpdate(userLocation);
  }

  Future<void> _dispatchLocationUpdate(UserLocation location) async {
    if (!state.isOnline) {
      _enqueueOffline(location);
      return;
    }

    final success = await _apiService.sendLocationUpdate(
      userId: location.userId,
      lat: location.latitude,
      lng: location.longitude,
      accuracy: location.accuracy,
      altitude: location.altitude,
      speed: location.speed,
    );

    if (_geofenceService != null) {
      try {
        await _geofenceService.processLiveGps(
          location: location,
          officerId: location.userId,
        );
      } catch (e) {
        developer.log('[LOCATION] Geofence evaluation error: $e');
      }
    }

    if (!success) {
      _enqueueOffline(location);
    } else {
      state = state.copyWith(lastSyncTime: DateTime.now());
    }
  }

  void _enqueueOffline(UserLocation location) {
    if (_offlineQueue.length >= maxOfflineQueueCapacity) {
      _offlineQueue.removeFirst();
    }
    _offlineQueue.add(location.copyWith(isOfflineQueued: true));
    state = state.copyWith(offlineQueueCount: _offlineQueue.length);
  }

  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    final batch = _offlineQueue.toList();
    int count = 0;
    for (var location in batch) {
      final ok = await _apiService.sendLocationUpdate(
        userId: location.userId,
        lat: location.latitude,
        lng: location.longitude,
        accuracy: location.accuracy,
        altitude: location.altitude,
        speed: location.speed,
      );
      if (ok) count++;
    }

    if (count > 0) {
      for (int i = 0; i < count; i++) {
        if (_offlineQueue.isNotEmpty) {
          _offlineQueue.removeFirst();
        }
      }
      state = state.copyWith(
        offlineQueueCount: _offlineQueue.length,
        lastSyncTime: DateTime.now(),
      );
    }
  }

  Future<void> stopTracking() async {
    await _positionStreamSub?.cancel();
    _positionStreamSub = null;

    state = state.copyWith(
      status: LocationServiceStatus.trackingPaused,
      errorMessage: 'Tracking stopped by officer',
    );
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}

final locationTrackingProvider =
    StateNotifierProvider<LocationTrackingNotifier, LocationTrackingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final geofenceService = ref.watch(geofenceServiceProvider);
  return LocationTrackingNotifier(
    apiService: apiService,
    geofenceService: geofenceService,
  );
});
