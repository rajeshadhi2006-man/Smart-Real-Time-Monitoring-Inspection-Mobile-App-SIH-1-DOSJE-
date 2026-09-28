import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/location_status_card.dart';
import '../../../../models/user_location.dart';
import '../../../../services/supabase_service.dart';
import '../../../inspections/domain/models/inspection_model.dart';
import '../../../inspections/presentation/providers/inspection_provider.dart';

class MapVerificationScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const MapVerificationScreen({
    super.key,
    this.inspectionId = '',
  });

  @override
  ConsumerState<MapVerificationScreen> createState() =>
      _MapVerificationScreenState();
}

class _MapVerificationScreenState extends ConsumerState<MapVerificationScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Target geofence coordinates
  late double _targetLat;
  late double _targetLon;
  bool _isAutoAligned = false;

  // Live inspector coordinates from real device GPS
  double? _currentLat;
  double? _currentLon;
  double? _gpsAccuracy;
  double? _gpsSpeed;
  double? _gpsAltitude;
  bool _isDetecting = false;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final inspectionState = ref.read(inspectionStateProvider);
    final inspection = inspectionState.inspections.cast<InspectionModel?>().firstWhere(
          (i) => i?.id == widget.inspectionId,
          orElse: () => inspectionState.todaysInspection ?? inspectionState.inspections.firstOrNull,
        );
    _targetLat = inspection?.verifiedLatitude ?? 12.9716;
    _targetLon = inspection?.verifiedLongitude ?? 77.5946;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Acquire real GPS position on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLocation();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _hasFix => _currentLat != null && _currentLon != null;

  double get _calculatedDistance => _hasFix
      ? GeoUtils.calculateDistanceInMeters(
          startLatitude: _currentLat!,
          startLongitude: _currentLon!,
          endLatitude: _targetLat,
          endLongitude: _targetLon,
        )
      : 0.0;

  bool get _isVerified =>
      _hasFix && _calculatedDistance <= AppConfig.maxGeofenceRadiusMeters;

  void _alignGeofenceToCurrentLocation() {
    if (!_hasFix) return;
    setState(() {
      _targetLat = _currentLat!;
      _targetLon = _currentLon!;
      _isAutoAligned = true;
    });

    _mapController.move(LatLng(_currentLat!, _currentLon!), 16.5);

    ref.read(inspectionStateProvider.notifier).verifyLocation(
          inspectionId: widget.inspectionId,
          lat: _currentLat!,
          lon: _currentLon!,
          distance: 0.0,
          accuracy: _gpsAccuracy ?? 5.0,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Target geofence locked to your real GPS coordinates (100m radius). Geofence verified!'),
        backgroundColor: Color(0xFF0F172A),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isDetecting = false;
          _errorMessage = 'GPS location services are disabled on this device. Please turn on Location.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isDetecting = false;
          _errorMessage = 'Location permission is required to verify geofence presence.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _isDetecting = false;
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        _gpsAccuracy = pos.accuracy;
        _gpsSpeed = pos.speed;
        _gpsAltitude = pos.altitude;
        _errorMessage = null;

        // Auto-align geofence with user's real-time position if target coordinates not preset
        if (!_isAutoAligned && _targetLat == 0.0) {
          _targetLat = pos.latitude;
          _targetLon = pos.longitude;
          _isAutoAligned = true;
        }
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.5);

      // Update inspection state with live device coordinates
      ref.read(inspectionStateProvider.notifier).verifyLocation(
            inspectionId: widget.inspectionId,
            lat: pos.latitude,
            lon: pos.longitude,
            distance: _calculatedDistance,
            accuracy: pos.accuracy,
          );

      // Broadcast real-time location update to Supabase
      SupabaseService().sendLocationUpdate(
        UserLocation(
          userId: 'Field Officer (${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)})',
          trackingSessionId: 'SESSION-${widget.inspectionId}',
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          altitude: pos.altitude,
          speed: pos.speed,
          heading: pos.heading,
          timestamp: pos.timestamp,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _errorMessage = 'Unable to acquire real GPS fix: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Geofence Verification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'OpenStreetMap Live Telemetry • 100m Geofence Audit',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: AppColors.neonCyan),
            onPressed: () => context.push(AppRoutes.map),
            tooltip: 'Live Tracking Module',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isDetecting ? null : _refreshLocation,
            tooltip: 'Resync GPS',
          ),
        ],
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Real OpenStreetMap Container with Live Overlays
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(
                    color: _isVerified
                        ? AppColors.neonCyan.withValues(alpha: 0.6)
                        : AppColors.dangerRed.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isVerified ? AppColors.neonCyan : AppColors.dangerRed)
                          .withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge - 1),
                  child: Stack(
                    children: [
                      // OpenStreetMap View
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _hasFix
                              ? LatLng(_currentLat!, _currentLon!)
                              : LatLng(_targetLat, _targetLon),
                          initialZoom: 16.5,
                          minZoom: 4.0,
                          maxZoom: 19.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'in.gov.mosje.sih_officer',
                          ),

                          // Geofence Circle & User Accuracy Circle
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: LatLng(_targetLat, _targetLon),
                                radius: AppConfig.maxGeofenceRadiusMeters,
                                useRadiusInMeter: true,
                                color: _isVerified
                                    ? const Color(0x2510B981)
                                    : const Color(0x25EF4444),
                                borderColor: _isVerified
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                                borderStrokeWidth: 2.0,
                              ),
                              if (_hasFix && _gpsAccuracy != null)
                                CircleMarker(
                                  point: LatLng(_currentLat!, _currentLon!),
                                  radius: _gpsAccuracy!.clamp(5.0, 50.0),
                                  useRadiusInMeter: true,
                                  color: const Color(0x202563EB),
                                  borderColor: const Color(0x602563EB),
                                  borderStrokeWidth: 1.0,
                                ),
                            ],
                          ),

                          // Markers: Facility Anchor & Live User Dot
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_targetLat, _targetLon),
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                    border: Border.all(color: AppColors.accentTeal, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.domain_rounded,
                                    size: 20,
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                              ),

                              if (_hasFix)
                                Marker(
                                  point: LatLng(_currentLat!, _currentLon!),
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: (_isVerified
                                                    ? AppColors.successGreen
                                                    : AppColors.dangerRed)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _isVerified
                                              ? AppColors.successGreen
                                              : AppColors.dangerRed,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.person_pin,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Top-Left HUD Telemetry Overlay
                      Positioned(
                        top: 12,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081426).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _isVerified
                                          ? AppColors.successGreen
                                          : (_hasFix ? AppColors.dangerRed : AppColors.warningAmber),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _hasFix
                                        ? (_isVerified ? 'GEOFENCE LOCKED' : 'OUTSIDE 100M ZONE')
                                        : 'SEARCHING FOR GPS...',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: _isVerified
                                          ? AppColors.successGreen
                                          : (_hasFix ? AppColors.dangerRed : AppColors.warningAmber),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _gpsAccuracy != null
                                    ? 'ACCURACY: ±${_gpsAccuracy!.toStringAsFixed(1)}m'
                                    : 'AWAITING SATELLITE FIX',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top-Right Range Scale Indicator
                      Positioned(
                        top: 12,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF081426).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'GEOFENCE: ${AppConfig.maxGeofenceRadiusMeters.toInt()}m',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.neonCyan,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Right Map Control Action (Center on User)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'recenter_gps',
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: AppColors.neonCyan,
                          onPressed: _hasFix
                              ? () {
                                  _mapController.move(
                                    LatLng(_currentLat!, _currentLon!),
                                    16.5,
                                  );
                                }
                              : null,
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ),

                      // Bottom Left Action (Align geofence to current GPS)
                      if (_hasFix && !_isVerified)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: InkWell(
                            onTap: _alignGeofenceToCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.neonCyan),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_location_alt_rounded, size: 14, color: AppColors.neonCyan),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lock Geofence Here',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Real-Time Telemetry Breakdown Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildTelemetryItem(
                          label: 'LIVE LATITUDE',
                          value: _currentLat != null ? _currentLat!.toStringAsFixed(6) : '--',
                        ),
                        _buildTelemetryItem(
                          label: 'LIVE LONGITUDE',
                          value: _currentLon != null ? _currentLon!.toStringAsFixed(6) : '--',
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    Row(
                      children: [
                        _buildTelemetryItem(
                          label: 'DISTANCE TO TARGET',
                          value: _hasFix ? GeoUtils.formatDistance(_calculatedDistance) : '--',
                          highlightColor: _isVerified ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                        _buildTelemetryItem(
                          label: 'GPS ACCURACY',
                          value: _gpsAccuracy != null ? '±${_gpsAccuracy!.toStringAsFixed(1)}m' : '--',
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    Row(
                      children: [
                        _buildTelemetryItem(
                          label: 'MOVEMENT SPEED',
                          value: _gpsSpeed != null ? '${(_gpsSpeed! * 3.6).toStringAsFixed(1)} km/h' : '--',
                        ),
                        _buildTelemetryItem(
                          label: 'ALTITUDE (MSL)',
                          value: _gpsAltitude != null ? '${_gpsAltitude!.toStringAsFixed(1)} m' : '--',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Location Status Card
              LocationStatusCard(
                isVerified: _isVerified,
                distanceMeters: _calculatedDistance,
                accuracyMeters: _gpsAccuracy,
                isDetecting: _isDetecting || !_hasFix,
                errorMessage: _errorMessage,
                onRetry: _refreshLocation,
              ),

              const SizedBox(height: 16),

              // 4. Force GPS Refresh & Telemetry Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C192E), Color(0xFF091424)],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(
                    color: AppColors.cyberBorder,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.sensors_rounded, size: 16, color: AppColors.neonCyan),
                              SizedBox(width: 6),
                              Text(
                                'REAL-TIME HARDWARE TELEMETRY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hasFix
                                ? 'Live GPS fix acquired • Streamed to OpenStreetMap & Supabase'
                                : 'Acquiring satellite lock from device hardware...',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan),
                      onPressed: _isDetecting ? null : _refreshLocation,
                      tooltip: 'Force GPS refresh',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Action Button to Launch Inspection
              AppButton(
                label: _isVerified
                    ? 'Confirm Geofence & Start Audit'
                    : 'Awaiting Geofence Verification (100m)',
                icon: _isVerified ? Icons.check_circle_outline : Icons.lock_outline,
                onPressed: _isVerified
                    ? () {
                        context.push('/inspection/${widget.inspectionId}/start');
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryItem({
    required String label,
    required String value,
    Color? highlightColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlightColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
