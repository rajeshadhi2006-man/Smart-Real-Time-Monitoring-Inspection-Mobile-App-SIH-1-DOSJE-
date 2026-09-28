import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/geofence.dart';
import '../../../../providers/geofence_provider.dart';
import '../../../../providers/monitored_persons_provider.dart';
import '../../../../services/geofence_service.dart';
import '../../../../services/location_service.dart';

class GeofenceMapScreen extends ConsumerStatefulWidget {
  final String geofenceId;

  const GeofenceMapScreen({super.key, required this.geofenceId});

  @override
  ConsumerState<GeofenceMapScreen> createState() => _GeofenceMapScreenState();
}

class _GeofenceMapScreenState extends ConsumerState<GeofenceMapScreen> {
  final MapController _mapController = MapController();
  bool _hasCenteredOnUser = false;

  @override
  Widget build(BuildContext context) {
    final geofencesState = ref.watch(geofenceProvider);
    final locationState = ref.watch(locationTrackingProvider);
    final personsState = ref.watch(monitoredPersonsProvider);
    final geofenceService = ref.watch(geofenceServiceProvider);

    final geofences = geofencesState.asData?.value ?? [];
    final persons = personsState.asData?.value ?? [];
    final currentLoc = locationState.currentLocation;

    final targetGeofence = geofences.firstWhere(
      (g) => g.id == widget.geofenceId,
      orElse: () => Geofence.defaultAuthorizedArea,
    );

    final center = LatLng(targetGeofence.latitude, targetGeofence.longitude);

    GeofenceEvaluation? evaluation;
    if (currentLoc != null) {
      evaluation = geofenceService.evaluate(currentLoc, targetGeofence: targetGeofence);
    }

    final isInside = evaluation?.isInside ?? false;
    final isLowAccuracy = evaluation?.status == GeofenceLiveStatus.accuracyLow;

    // Auto-center once if user location is available
    if (currentLoc != null && !_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              targetGeofence.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Perimeter Radius: ${targetGeofence.radiusMeters.toInt()}m',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isInside ? AppColors.statusGreen.withValues(alpha: 0.2) : AppColors.statusAmber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isInside ? AppColors.statusGreen : AppColors.statusAmber),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isInside ? AppColors.statusGreen : AppColors.statusAmber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isInside ? 'INSIDE' : 'OUTSIDE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isInside ? AppColors.statusGreen : AppColors.statusAmber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLoc != null
                  ? LatLng(currentLoc.latitude, currentLoc.longitude)
                  : center,
              initialZoom: 16.0,
              minZoom: 4.0,
              maxZoom: 19.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.gov.mosje.sih_officer',
              ),

              // Geofence Radius Circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: targetGeofence.radiusMeters,
                    useRadiusInMeter: true,
                    color: isInside
                        ? AppColors.statusGreen.withValues(alpha: 0.18)
                        : AppColors.tricolorSaffron.withValues(alpha: 0.15),
                    borderColor: isInside ? AppColors.statusGreen : AppColors.tricolorSaffron,
                    borderStrokeWidth: 2.5,
                  ),
                  // User GPS Accuracy Circle
                  if (currentLoc != null)
                    CircleMarker(
                      point: LatLng(currentLoc.latitude, currentLoc.longitude),
                      radius: currentLoc.accuracy.clamp(3.0, 100.0),
                      useRadiusInMeter: true,
                      color: AppColors.accentTeal.withValues(alpha: 0.12),
                      borderColor: AppColors.accentTeal.withValues(alpha: 0.4),
                      borderStrokeWidth: 1.0,
                    ),
                ],
              ),

              MarkerLayer(
                markers: [
                  // Geofence Center Pin (📍)
                  Marker(
                    point: center,
                    width: 44,
                    height: 44,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryNavy,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.account_balance, color: AppColors.tricolorSaffron, size: 18),
                        ),
                      ],
                    ),
                  ),

                  // Current Officer GPS Marker (🔵)
                  if (currentLoc != null)
                    Marker(
                      point: LatLng(currentLoc.latitude, currentLoc.longitude),
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ),

                  // Other Registered Personnel Markers
                  ...persons.map((p) {
                    return Marker(
                      point: LatLng(p.latitude, p.longitude),
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.statusColor(p.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            p.name.isNotEmpty ? p.name.substring(0, 1) : 'P',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Map Control Floating Buttons
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center_geofence',
                  backgroundColor: AppColors.surfaceDark,
                  onPressed: () {
                    _mapController.move(center, 16.0);
                  },
                  tooltip: 'Center on Geofence',
                  child: const Icon(Icons.location_city, color: AppColors.tricolorSaffron),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'center_user',
                  backgroundColor: AppColors.surfaceDark,
                  onPressed: () {
                    if (currentLoc != null) {
                      _mapController.move(LatLng(currentLoc.latitude, currentLoc.longitude), 17.0);
                    }
                  },
                  tooltip: 'Center on My GPS',
                  child: const Icon(Icons.my_location, color: AppColors.accentTeal),
                ),
              ],
            ),
          ),

          // Bottom Live Telemetry HUD Overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isInside ? AppColors.statusGreen.withValues(alpha: 0.6) : AppColors.borderDark,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetGeofence.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentLoc != null
                                  ? 'Distance: ${evaluation?.distanceToCenterMeters.toStringAsFixed(0)} m | Radius: ${targetGeofence.radiusMeters.toInt()} m'
                                  : 'Acquiring GPS fix...',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isInside ? AppColors.statusGreen.withValues(alpha: 0.2) : AppColors.statusAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isInside ? AppColors.statusGreen : AppColors.statusAmber),
                        ),
                        child: Text(
                          isLowAccuracy
                              ? 'LOW ACCURACY'
                              : (isInside ? '✓ INSIDE' : '○ OUTSIDE'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isInside ? AppColors.statusGreen : AppColors.statusAmber,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (evaluation?.accuracyWarning != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      evaluation!.accuracyWarning!,
                      style: const TextStyle(fontSize: 10, color: AppColors.statusAmber),
                    ),
                  ],

                  if (currentLoc != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Accuracy: ±${currentLoc.accuracy.toStringAsFixed(1)}m',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                        Text(
                          'Speed: ${(currentLoc.speed * 3.6).toStringAsFixed(1)} km/h',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                        Text(
                          'Alt: ${currentLoc.altitude.toStringAsFixed(0)}m',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
