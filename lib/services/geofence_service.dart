import 'dart:developer' as developer;
import '../core/config/app_config.dart';
import '../core/utils/geo_utils.dart';
import '../models/geofence.dart';
import '../models/user_location.dart';
import 'api_service.dart';

enum GeofenceLiveStatus {
  inside,
  outside,
  accuracyLow,
  unknown,
}

typedef GeofenceStatus = GeofenceLiveStatus;

enum GeofenceSessionState {
  notEntered,
  entered,
  active,
  exited,
}

class GeofenceEvaluation {
  final GeofenceLiveStatus status;
  final double distanceToCenterMeters;
  final double distanceToPerimeterMeters;
  final String statusLabel;
  final String distanceLabel;
  final bool isAccuracyValid;
  final double accuracy;
  final String? accuracyWarning;

  const GeofenceEvaluation({
    required this.status,
    required this.distanceToCenterMeters,
    required this.distanceToPerimeterMeters,
    required this.statusLabel,
    required this.distanceLabel,
    this.isAccuracyValid = true,
    this.accuracy = 5.0,
    this.accuracyWarning,
  });

  bool get isInside => status == GeofenceLiveStatus.inside;
}

/// Real-Time Geofencing Engine for MoSJE Nirikshan.
/// Handles high-precision geodesic containment, boundary debouncing,
/// and automated FastAPI attendance session transitions.
class GeofenceService {
  final ApiService _apiService;
  Geofence _activeGeofence;

  GeofenceSessionState _sessionState = GeofenceSessionState.notEntered;
  String? _activeSessionGeofenceId;
  DateTime? _lastEntryTime;
  DateTime? _lastExitTime;

  // Hysteresis counters to prevent boundary GPS bounce
  int _consecutiveInsideReadings = 0;
  int _consecutiveOutsideReadings = 0;
  static const int _requiredReadingsForTransition = 2;

  GeofenceService({
    ApiService? apiService,
    Geofence? activeGeofence,
  })  : _apiService = apiService ?? ApiService(),
        _activeGeofence = activeGeofence ?? Geofence.defaultAuthorizedArea;

  Geofence get activeGeofence => _activeGeofence;
  GeofenceSessionState get sessionState => _sessionState;
  String? get activeSessionGeofenceId => _activeSessionGeofenceId;
  DateTime? get lastEntryTime => _lastEntryTime;
  DateTime? get lastExitTime => _lastExitTime;

  void setActiveGeofence(Geofence geofence) {
    if (_activeGeofence.id != geofence.id) {
      _activeGeofence = geofence;
      _sessionState = GeofenceSessionState.notEntered;
      _consecutiveInsideReadings = 0;
      _consecutiveOutsideReadings = 0;
    } else {
      _activeGeofence = geofence;
    }
  }

  /// Evaluates GPS location against a specific geofence or the active geofence
  GeofenceEvaluation evaluate(UserLocation location, {Geofence? targetGeofence}) {
    final geo = targetGeofence ?? _activeGeofence;

    final double centerDistance = GeoUtils.calculateDistanceInMeters(
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      endLatitude: geo.latitude,
      endLongitude: geo.longitude,
    );

    final bool isInside = centerDistance <= geo.radiusMeters;
    final double perimeterDistance = isInside ? 0.0 : (centerDistance - geo.radiusMeters);

    // Accuracy validation check
    final bool isAccuracyAcceptable = location.accuracy <= AppConfig.minGpsAccuracyMeters;
    final String? accuracyWarning = !isAccuracyAcceptable
        ? 'GPS accuracy is low (±${location.accuracy.toStringAsFixed(0)}m). Move to an open area.'
        : null;

    GeofenceLiveStatus liveStatus;
    if (!isAccuracyAcceptable) {
      liveStatus = GeofenceLiveStatus.accuracyLow;
    } else if (isInside) {
      liveStatus = GeofenceLiveStatus.inside;
    } else {
      liveStatus = GeofenceLiveStatus.outside;
    }

    final String statusLabel = liveStatus == GeofenceLiveStatus.accuracyLow
        ? 'LOW GPS ACCURACY'
        : (isInside ? 'INSIDE GEOFENCE' : 'OUTSIDE GEOFENCE');

    final String distanceLabel = isInside
        ? '${centerDistance.toStringAsFixed(0)} m from center'
        : '${perimeterDistance.toStringAsFixed(0)} m outside boundary';

    return GeofenceEvaluation(
      status: liveStatus,
      distanceToCenterMeters: centerDistance,
      distanceToPerimeterMeters: perimeterDistance,
      statusLabel: statusLabel,
      distanceLabel: distanceLabel,
      isAccuracyValid: isAccuracyAcceptable,
      accuracy: location.accuracy,
      accuracyWarning: accuracyWarning,
    );
  }

  /// Processes live GPS point, applies boundary debouncing, and triggers backend entry/exit
  Future<GeofenceEvaluation> processLiveGps({
    required UserLocation location,
    required String officerId,
    Geofence? targetGeofence,
  }) async {
    final geo = targetGeofence ?? _activeGeofence;
    final evaluation = evaluate(location, targetGeofence: geo);

    if (!evaluation.isAccuracyValid) {
      developer.log('[GEOFENCE] Poor GPS accuracy (±${location.accuracy}m), ignoring boundary transition.');
      return evaluation;
    }

    if (evaluation.isInside) {
      _consecutiveInsideReadings++;
      _consecutiveOutsideReadings = 0;

      if (_consecutiveInsideReadings >= _requiredReadingsForTransition &&
          _sessionState != GeofenceSessionState.active) {
        // TRIGGER ENTRY EVENT
        _sessionState = GeofenceSessionState.active;
        _activeSessionGeofenceId = geo.id;
        _lastEntryTime = DateTime.now();

        developer.log('[GEOFENCE] Validated ENTER EVENT for geofence: ${geo.name} (${geo.id})');
        
        await _apiService.recordAttendanceEntry(
          userId: officerId,
          geofenceId: geo.id,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: location.timestamp.toUtc().toIso8601String(),
        );
      }
    } else {
      _consecutiveOutsideReadings++;
      _consecutiveInsideReadings = 0;

      if (_consecutiveOutsideReadings >= _requiredReadingsForTransition &&
          _sessionState == GeofenceSessionState.active) {
        // TRIGGER EXIT EVENT
        _sessionState = GeofenceSessionState.exited;
        _lastExitTime = DateTime.now();

        developer.log('[GEOFENCE] Validated EXIT EVENT for geofence: ${geo.name} (${geo.id})');

        await _apiService.recordAttendanceExit(
          userId: officerId,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: location.timestamp.toUtc().toIso8601String(),
        );
      }
    }

    return evaluation;
  }
}
