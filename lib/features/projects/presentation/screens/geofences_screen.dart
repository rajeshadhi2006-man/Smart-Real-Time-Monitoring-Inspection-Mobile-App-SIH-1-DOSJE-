import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/geofence.dart';
import '../../../../providers/geofence_provider.dart';
import '../../../../services/geofence_service.dart';
import '../../../../services/location_service.dart';

class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofencesState = ref.watch(geofenceProvider);
    final locationState = ref.watch(locationTrackingProvider);
    final geofenceService = ref.watch(geofenceServiceProvider);

    final geofences = geofencesState.asData?.value ?? [];
    final currentLoc = locationState.currentLocation;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASSIGNED LOCATIONS & GEOFENCES',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'National Command Perimeter Synchronizer',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.tricolorSaffron),
            onPressed: () {
              ref.read(geofenceProvider.notifier).loadGeofences();
            },
            tooltip: 'Sync Geofences',
          ),
        ],
      ),
      body: Column(
        children: [
          // Live GPS Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: const Border(bottom: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Icon(
                  locationState.isTracking ? Icons.my_location : Icons.location_off,
                  color: locationState.isTracking ? AppColors.statusGreen : AppColors.statusAmber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: currentLoc != null
                      ? Text(
                          'GPS: ${currentLoc.latitude.toStringAsFixed(5)}, ${currentLoc.longitude.toStringAsFixed(5)} (±${currentLoc.accuracy.toStringAsFixed(0)}m)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontFamily: 'monospace'),
                        )
                      : const Text(
                          'Acquiring real device GPS signal...',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                ),
                if (!locationState.isTracking)
                  TextButton(
                    onPressed: () => ref.read(locationTrackingProvider.notifier).startTracking(),
                    child: const Text('ENABLE GPS', style: TextStyle(fontSize: 11, color: AppColors.tricolorSaffron, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Geofences List
          Expanded(
            child: geofencesState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.statusRed, size: 48),
                      const SizedBox(height: 12),
                      Text('Error loading geofences: $err', style: const TextStyle(color: AppColors.statusRed, fontSize: 13), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.read(geofenceProvider.notifier).loadGeofences(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.tricolorSaffron),
                        child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) {
                if (geofences.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        const Text('No Assigned Geofences Found', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Perimeters configured on Government Web Dashboard appear here in real-time.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(geofenceProvider.notifier).loadGeofences(),
                          icon: const Icon(Icons.sync, size: 16, color: AppColors.tricolorSaffron),
                          label: const Text('SYNC FROM SERVER', style: TextStyle(color: AppColors.tricolorSaffron, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: geofences.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final g = geofences[index];
                    return _buildGeofenceCard(context, ref, g, currentLoc, geofenceService);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceCard(
    BuildContext context,
    WidgetRef ref,
    Geofence g,
    dynamic currentLoc,
    GeofenceService geofenceService,
  ) {
    GeofenceEvaluation? evaluation;
    if (currentLoc != null) {
      evaluation = geofenceService.evaluate(currentLoc, targetGeofence: g);
    }

    final isInside = evaluation?.isInside ?? false;
    final isLowAccuracy = evaluation?.status == GeofenceLiveStatus.accuracyLow;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    String statusText;

    if (currentLoc == null) {
      badgeBg = Colors.grey.withValues(alpha: 0.15);
      badgeBorder = Colors.grey;
      badgeText = Colors.grey;
      statusText = 'WAITING FOR GPS';
    } else if (isLowAccuracy) {
      badgeBg = AppColors.statusAmber.withValues(alpha: 0.15);
      badgeBorder = AppColors.statusAmber;
      badgeText = AppColors.statusAmber;
      statusText = '⚠ LOW GPS ACCURACY';
    } else if (isInside) {
      badgeBg = AppColors.statusGreen.withValues(alpha: 0.15);
      badgeBorder = AppColors.statusGreen;
      badgeText = AppColors.statusGreen;
      statusText = '✓ INSIDE GEOFENCE';
    } else {
      badgeBg = AppColors.statusAmber.withValues(alpha: 0.15);
      badgeBorder = AppColors.statusAmber;
      badgeText = AppColors.statusAmber;
      statusText = '○ OUTSIDE GEOFENCE';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInside ? AppColors.statusGreen.withValues(alpha: 0.5) : AppColors.borderDark,
          width: isInside ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: isInside ? AppColors.statusGreen : AppColors.tricolorSaffron,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  g.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeText),
                ),
              ),
            ],
          ),

          if (g.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              g.description,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 12),

          // Distance and Radius Metrics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distance from Location', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        evaluation != null
                            ? '${evaluation.distanceToCenterMeters.toStringAsFixed(0)} m'
                            : 'Calculating...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isInside ? AppColors.statusGreen : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.borderDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Geofence Radius', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${g.radiusMeters.toInt()} m',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (evaluation?.accuracyWarning != null) ...[
            const SizedBox(height: 8),
            Text(
              evaluation!.accuracyWarning!,
              style: const TextStyle(fontSize: 10, color: AppColors.statusAmber),
            ),
          ],

          const SizedBox(height: 12),

          // Open Map Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/geofence/map/${g.id}'),
              icon: const Icon(Icons.map_outlined, size: 16, color: AppColors.tricolorSaffron),
              label: const Text(
                'OPEN LIVE MAP',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tricolorSaffron),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.tricolorSaffron),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
