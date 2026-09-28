import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/geohash_helper.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../models/assignment_model.dart';
import '../../providers/app_providers.dart';
import 'assignment_detail_screen.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final positionAsync = ref.watch(positionStreamProvider);
    final currentPos = positionAsync.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: SovereignColorfulBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Sovereign Official Header
              const GovtEmblemHeader(
                compact: true,
                subtitle: "National Field Inspection Assignments & Target Geofences",
                backgroundColor: Color(0xCC07152B),
              ),

              // Real-time GPS Telemetry Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: currentPos != null ? const Color(0x3310B981) : const Color(0x33F59E0B),
                child: Row(
                  children: [
                    Icon(
                      currentPos != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                      size: 14,
                      color: currentPos != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentPos != null
                            ? "REAL GPS ACTIVE: ${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)} (±${currentPos.accuracy.toStringAsFixed(1)}m)"
                            : "ACQUIRING REAL GPS SATELLITE FIX...",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentPos != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Assignments List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.tricolorSaffron,
                  backgroundColor: const Color(0xFF0A192F),
                  onRefresh: () async {
                    ref.invalidate(assignmentsProvider);
                  },
                  child: assignmentsAsync.when(
                    data: (assignments) {
                      if (assignments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0x3338BDF8)),
                                  ),
                                  child: const Icon(Icons.assignment_outlined, size: 36, color: Color(0xFF38BDF8)),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No Field Inspections Assigned",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Normal & surprise inspection dispatches from Government Web Portal will appear here in real time.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final item = assignments[index];
                          return _buildAssignmentTile(context, ref, item, currentPos);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron)),
                    error: (err, stack) => Center(
                      child: Text("Unable to connect to backend server: $err", style: const TextStyle(color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentTile(
    BuildContext context,
    WidgetRef ref,
    AssignmentModel assignment,
    dynamic currentPos,
  ) {
    final bool isSurprise = assignment.isSurprise || assignment.assignmentType == 'SURPRISE_INSPECTION';
    final bool isAttVerified = assignment.attendanceStatus == 'VERIFIED';
    final bool isInspDone = assignment.inspectionStatus == 'COMPLETED';

    double? distanceMeters;
    bool isInside = false;

    if (currentPos != null) {
      distanceMeters = GeoHashHelper.distanceMeters(
        currentPos.latitude,
        currentPos.longitude,
        assignment.latitude,
        assignment.longitude,
      );
      isInside = distanceMeters <= assignment.radiusMeters;
    }

    final distanceText = distanceMeters != null
        ? distanceMeters < 1000
            ? "${distanceMeters.toStringAsFixed(0)} m"
            : "${(distanceMeters / 1000).toStringAsFixed(2)} km"
        : "Calculating...";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSurprise
              ? [const Color(0xD93B0712), const Color(0xBF1E0A12)]
              : [const Color(0xD90A1B33), const Color(0xBF071324)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSurprise
              ? const Color(0xFFEF4444)
              : (isInside ? const Color(0xFF10B981) : const Color(0x3338BDF8)),
          width: isSurprise ? 1.8 : (isInside ? 1.8 : 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(selectedAssignmentProvider.notifier).state = assignment;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssignmentDetailScreen(assignment: assignment)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type Badge / Surprise Badge & Priority
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isSurprise)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x33EF4444),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFEF4444)),
                            SizedBox(width: 4),
                            Text(
                              "🚨 SURPRISE INSPECTION",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          "ID: ${assignment.assignmentId}",
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    // Attendance & Inspection Status Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isAttVerified ? const Color(0x2610B981) : const Color(0x26F59E0B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isAttVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAttVerified ? Icons.check_circle_rounded : Icons.pending_outlined,
                            size: 11,
                            color: isAttVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAttVerified ? (isInspDone ? "COMPLETED ✓" : "ATTENDANCE VERIFIED") : "ATTENDANCE PENDING",
                            style: TextStyle(
                              color: isAttVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Task / Inspection Title
                Text(
                  assignment.title,
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),

                // Target Location
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        assignment.assignedLocation,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Telemetry Data Box: Distance, Geofence Radius, GPS Accuracy, Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x59040D1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 5),
                              Text(
                                "Distance: $distanceText",
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            isInside ? "INSIDE GEO-FENCE ✓" : "OUTSIDE GEO-FENCE",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isInside ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.adjust_rounded, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 5),
                              Text(
                                "Geofence: ${assignment.radiusMeters.toInt()}m",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          Text(
                            currentPos != null ? "GPS ACCURACY: ${currentPos.accuracy.toStringAsFixed(0)}m" : "GPS: None",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInside ? const Color(0xFF10B981) : const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      ref.read(selectedAssignmentProvider.notifier).state = assignment;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssignmentDetailScreen(assignment: assignment)),
                      );
                    },
                    icon: Icon(
                      isInside ? Icons.touch_app_rounded : Icons.navigation_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isInside
                          ? (isAttVerified ? "VIEW INSPECTION & EVIDENCE" : "ENTERED: MARK ATTENDANCE")
                          : "NAVIGATE TO LOCATION",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
