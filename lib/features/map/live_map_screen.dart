import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/tactical_telemetry_bar.dart';
import '../../providers/app_providers.dart';

class LiveMapScreen extends ConsumerWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(positionStreamProvider);
    final selectedAssignment = ref.watch(selectedAssignmentProvider);
    final geofenceStatus = ref.watch(geofenceStateProvider);
    final authState = ref.watch(authProvider);

    // Listen to position changes cleanly without triggering build loops
    ref.listen(positionStreamProvider, (_, next) {
      next.whenData((pos) {
        final user = authState.valueOrNull;
        if (selectedAssignment != null && user != null) {
          ref.read(geofenceStateProvider.notifier).updatePosition(
                pos,
                selectedAssignment,
                user.officerId,
              );
        }
      });
    });

    final isInside = geofenceStatus?.state.name == 'inside' || geofenceStatus?.state.name == 'entered';

    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: SafeArea(
        child: Column(
          children: [
            // Official Sovereign Header
            const GovtEmblemHeader(
              compact: true,
              subtitle: "Geospatial Boundary & Real-Time GNSS Tracking",
            ),

            Expanded(
              child: positionAsync.when(
                data: (position) {
                  final userLocation = LatLng(position.latitude, position.longitude);

                  final targetLocation = selectedAssignment != null
                      ? LatLng(selectedAssignment.latitude, selectedAssignment.longitude)
                      : userLocation;

                  return Stack(
                    children: [
                      // Vector OpenStreetMap
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: userLocation,
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'in.gov.dosje.sih_inspection',
                          ),
                          if (selectedAssignment != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: targetLocation,
                                  color: AppColors.statusGreen.withValues(alpha: 0.18),
                                  borderColor: AppColors.statusGreen,
                                  borderStrokeWidth: 2.5,
                                  radius: selectedAssignment.radiusMeters,
                                  useRadiusInMeter: true,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              // User Live Location Marker with Pulsating Ring
                              Marker(
                                point: userLocation,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0284C7), Color(0xFF0A192F)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Icon(Icons.navigation_rounded, color: Color(0xFFFDE68A), size: 22),
                                ),
                              ),
                              // Target Location Facility Pin
                              if (selectedAssignment != null)
                                Marker(
                                  point: targetLocation,
                                  width: 44,
                                  height: 44,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A192F),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.statusGreen, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.statusGreen.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text("🏛️", style: TextStyle(fontSize: 18)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Top Tactical Telemetry HUD Overlay
                      Positioned(
                        top: 12,
                        left: 14,
                        right: 14,
                        child: TacticalTelemetryBar(
                          accuracy: position.accuracy,
                          isGpsLocked: true,
                          isAntiSpoofActive: true,
                          isCloudConnected: true,
                        ),
                      ),

                      // Bottom Floating Radar Information Card
                      Positioned(
                        bottom: 16,
                        left: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A192F).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isInside ? AppColors.statusGreen : const Color(0xFF38BDF8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (isInside ? AppColors.statusGreen : const Color(0xFF38BDF8)).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isInside ? Icons.verified_rounded : Icons.radar_rounded,
                                      color: isInside ? AppColors.statusGreen : const Color(0xFF38BDF8),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedAssignment?.institutionName ?? "Field Perimeter Standby",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                                        ),
                                        Text(
                                          geofenceStatus?.message ?? "Acquiring geofence telemetry...",
                                          style: TextStyle(
                                            color: isInside ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isInside ? AppColors.statusGreen : AppColors.statusAmber,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isInside ? "INSIDE" : "APPROACHING",
                                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "COORDINATES: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}",
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      geofenceStatus != null ? "${(geofenceStatus.distanceMeters / 1000).toStringAsFixed(2)} km" : "0.00 km",
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.statusGreen)),
                error: (e, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_rounded, size: 48, color: AppColors.statusError),
                        const SizedBox(height: 12),
                        Text("GPS Sensor Error: $e", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
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
