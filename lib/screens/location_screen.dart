import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../models/geofence.dart';
import '../models/user_location.dart';
import '../services/geofence_service.dart';
import '../services/location_service.dart';
import '../widgets/location_info_card.dart';
import '../widgets/location_map.dart';
import '../widgets/tracking_status_card.dart';
import 'permission_screen.dart';

/// Production-quality real-time location tracking screen with OpenStreetMap,
/// explicit session controls, geofence compliance, and clean enterprise UI.
class LocationScreen extends ConsumerStatefulWidget {
  final Geofence? targetGeofence;

  const LocationScreen({
    super.key,
    this.targetGeofence,
  });

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  late final GeofenceService _geofenceService;

  @override
  void initState() {
    super.initState();
    _geofenceService = GeofenceService(
      activeGeofence: widget.targetGeofence ??
          const Geofence(
            id: 'GEOFENCE-PENDING',
            name: 'Awaiting Live GPS Location',
            latitude: 0.0,
            longitude: 0.0,
            radiusMeters: 500.0,
            description: 'Geofence will automatically lock to your live position.',
          ),
    );

    // Automatically check permissions and initialize tracking on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  String _resolveOfficerIdentifier() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user != null) {
      return '${user.fullName} (${user.officerId})';
    }
    return 'Field Officer (Device ${DateTime.now().millisecond})';
  }

  Future<void> _startSession() async {
    final notifier = ref.read(locationTrackingProvider.notifier);
    await notifier.startTracking(
      userId: _resolveOfficerIdentifier(),
      geofenceId: _geofenceService.activeGeofence.id,
    );
  }

  bool _hasAutoCenteredGeofence = false;

  void _checkAutoCenterGeofence(UserLocation? loc) {
    if (widget.targetGeofence == null && !_hasAutoCenteredGeofence && loc != null) {
      _hasAutoCenteredGeofence = true;
      setState(() {
        _geofenceService.setActiveGeofence(
          Geofence.aroundUser(
            latitude: loc.latitude,
            longitude: loc.longitude,
            radiusMeters: 500.0,
            name: 'Current Field Audit Site',
          ),
        );
      });
    }
  }

  void _setGeofenceToCurrentLocation(UserLocation? loc) {
    if (loc == null) return;
    setState(() {
      _geofenceService.setActiveGeofence(
        Geofence(
          id: 'GEOFENCE-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Custom Target Facility',
          latitude: loc.latitude,
          longitude: loc.longitude,
          radiusMeters: 500.0,
          description: 'Audited at real device location',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Target geofence centered on your real GPS position (500m radius)'),
        backgroundColor: Color(0xFF0F172A),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(locationTrackingProvider);
    final notifier = ref.read(locationTrackingProvider.notifier);

    // Automatically align target geofence around real device coordinates on first fix
    _checkAutoCenterGeofence(state.currentLocation);

    // If permission is denied or missing, display the explicit PermissionScreen
    if (state.status == LocationServiceStatus.permissionDenied ||
        state.status == LocationServiceStatus.permissionPermanentlyDenied ||
        state.status == LocationServiceStatus.gpsDisabled) {
      return PermissionScreen(
        onPermissionGranted: () {
          notifier.startTracking(geofenceId: _geofenceService.activeGeofence.id);
        },
      );
    }

    final evaluation = state.currentLocation != null
        ? _geofenceService.evaluate(state.currentLocation!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Tracking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'OpenStreetMap Live Telemetry',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Set current location as geofence center
          if (state.currentLocation != null)
            IconButton(
              icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF1D4ED8)),
              tooltip: 'Set Geofence at My Location',
              onPressed: () => _setGeofenceToCurrentLocation(state.currentLocation),
            ),

          // Connection status chip (Online / Offline Sync)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isOnline ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 12,
                      color: state.isOnline ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.isOnline ? 'Online' : 'Offline Queue',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: state.isOnline ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Half: OpenStreetMap Canvas
            Expanded(
              flex: 5,
              child: ClipRRect(
                child: LocationMap(
                  userLocation: state.currentLocation,
                  history: state.locationHistory,
                  geofence: _geofenceService.activeGeofence,
                  isTracking: state.isTracking,
                ),
              ),
            ),

            // Bottom Half: Clean Enterprise Telemetry Cards & Controls
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Tracking Status & Toggle Control Card
                      TrackingStatusCard(
                        isTracking: state.isTracking,
                        userLocation: state.currentLocation,
                        lastUpdated: state.lastSyncTime,
                        offlineQueueCount: state.offlineQueueCount,
                        onToggleTracking: () {
                          if (state.isTracking) {
                            notifier.stopTracking();
                          } else {
                            notifier.startTracking(
                              userId: _resolveOfficerIdentifier(),
                              geofenceId: _geofenceService.activeGeofence.id,
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      // Geofence Audit & Telemetry Breakdown Card
                      LocationInfoCard(
                        userLocation: state.currentLocation,
                        evaluation: evaluation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
