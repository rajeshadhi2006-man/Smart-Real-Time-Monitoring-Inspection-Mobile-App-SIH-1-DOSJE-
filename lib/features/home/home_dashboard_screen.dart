import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/tactical_telemetry_bar.dart';
import '../../core/widgets/geofence_radar_card.dart';
import '../../core/widgets/govt_metric_tile.dart';
import '../../core/widgets/govt_quick_action_dock.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../providers/app_providers.dart';
import '../assignments/assignment_detail_screen.dart';
import '../assignments/assignments_screen.dart';
import '../alerts/alerts_screen.dart';
import '../verification/verification_screen.dart';
import '../evidence/live_gps_map_camera_screen.dart';
import '../inspections/inspections_screen.dart';
import '../map/live_map_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final geofenceStatus = ref.watch(geofenceStateProvider);
    final positionAsync = ref.watch(positionStreamProvider);

    final isInside = geofenceStatus?.state.name == 'inside' || geofenceStatus?.state.name == 'entered';

    return Scaffold(
      body: SovereignColorfulBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Official Sovereign Header with Ashoka Stambha & Tricolor Ribbon
              const GovtEmblemHeader(
                compact: true,
                subtitle: "National Command Console • SIH 26095",
              ),

              // Main Scrollable Area
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(assignmentsProvider);
                    ref.invalidate(inspectionsProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Officer Identity & Status Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNavy.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Gold rimmed Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.goldFoilGradient,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : 'O',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Officer Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Inspector Officer',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${user?.role ?? 'FIELD INSPECTOR'} • ${user?.department ?? 'DoSJE Operations'}",
                                      style: const TextStyle(
                                        color: Color(0xFFBAE6FD),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "OFFICER ID: ${user?.officerId ?? 'OFF-001'}",
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Notification Alert Trigger
                              IconButton(
                                icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFDE68A)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tactical Telemetry HUD Bar
                        TacticalTelemetryBar(
                          accuracy: positionAsync.valueOrNull?.accuracy,
                          isGpsLocked: positionAsync.valueOrNull != null,
                          isAntiSpoofActive: true,
                          isCloudConnected: true,
                        ),
                        const SizedBox(height: 16),

                        // Live Duty Geofence Radar Card
                        assignmentsAsync.when(
                          data: (assignments) {
                            if (assignments.isEmpty) {
                              return GeofenceRadarCard(
                                facilityName: "No Active Field Mission Assigned",
                                schemeName: "STANDBY STATUS",
                                distanceMeters: 0,
                                isInside: false,
                                onNavigate: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LiveMapScreen()),
                                  );
                                },
                              );
                            }

                            final active = assignments.first;
                            return GeofenceRadarCard(
                              facilityName: active.institutionName,
                              schemeName: active.schemeName,
                              distanceMeters: geofenceStatus?.distanceMeters ?? 450.0,
                              radiusMeters: active.radiusMeters,
                              isInside: isInside,
                              onNavigate: () {
                                ref.read(selectedAssignmentProvider.notifier).state = active;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LiveMapScreen()),
                                );
                              },
                              onVerify: () {
                                ref.read(selectedAssignmentProvider.notifier).state = active;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const VerificationScreen()),
                                );
                              },
                            );
                          },
                          loading: () => GeofenceRadarCard(
                            facilityName: "Synchronizing Field Facility...",
                            schemeName: "FETCHING LIVE ASSIGNMENT",
                            distanceMeters: 0.0,
                            radiusMeters: 300.0,
                            isInside: false,
                            onNavigate: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveMapScreen())),
                            onVerify: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen())),
                          ),
                          error: (err, stack) => GeofenceRadarCard(
                            facilityName: "No Active Field Mission Assigned",
                            schemeName: "STANDBY STATUS",
                            distanceMeters: 0.0,
                            radiusMeters: 0.0,
                            isInside: false,
                            onNavigate: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveMapScreen())),
                            onVerify: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen())),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Tactical Field Operations Dock
                        const Text(
                          "TACTICAL OPERATIONS DOCK",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GovtQuickActionDock(
                          onBiometrics: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VerificationScreen()),
                            );
                          },
                          onEvidence: () {
                            final active = ref.read(selectedAssignmentProvider) ??
                                assignmentsAsync.valueOrNull?.firstOrNull;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveGpsMapCameraScreen(assignment: active),
                              ),
                            );
                          },
                          onInspections: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InspectionsScreen()),
                            );
                          },
                          onAlerts: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AlertsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Mission KPI Grid Section
                        const Text(
                          "OPERATIONAL AUDIT METRICS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 4-Card Mission KPI Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.36,
                          children: [
                            GovtMetricTile(
                              title: "Assigned",
                              value: "${assignmentsAsync.valueOrNull?.length ?? 0}",
                              subtitle: "Facilities",
                              icon: Icons.assignment_turned_in_rounded,
                              accentColor: const Color(0xFF38BDF8),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                            ),
                            GovtMetricTile(
                              title: "Completed",
                              value: "${inspectionsAsync.valueOrNull?.where((i) => i.status == 'COMPLETED').length ?? 0}",
                              subtitle: "Audits",
                              icon: Icons.verified_rounded,
                              accentColor: AppColors.statusGreen,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionsScreen())),
                            ),
                            GovtMetricTile(
                              title: "Pending",
                              value: "${inspectionsAsync.valueOrNull?.where((i) => i.status != 'COMPLETED').length ?? 0}",
                              subtitle: "Review Needed",
                              icon: Icons.pending_actions_rounded,
                              accentColor: AppColors.tricolorSaffron,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionsScreen())),
                            ),
                            GovtMetricTile(
                              title: "Attendance",
                              value: isInside ? "100%" : "STANDBY",
                              subtitle: isInside ? "Geofence Locked" : "Outside Zone",
                              icon: isInside ? Icons.lock_rounded : Icons.my_location_rounded,
                              accentColor: isInside ? AppColors.statusGreen : const Color(0xFFF59E0B),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveMapScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Active Assignment Details Card
                        assignmentsAsync.when(
                          data: (assignments) {
                            if (assignments.isEmpty) return const SizedBox();
                            final current = assignments.first;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ACTIVE INSPECTION DOSSIER",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF38BDF8),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1E36),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3), width: 1.2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              current.institutionName,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                            ),
                                            child: Text(
                                              current.status.toUpperCase(),
                                              style: const TextStyle(
                                                color: Color(0xFF6EE7B7),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Scheme: ${current.schemeName}",
                                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: AppColors.solarSaffronGradient,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF9933).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            ref.read(selectedAssignmentProvider.notifier).state = current;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => AssignmentDetailScreen(assignment: current)),
                                            );
                                          },
                                          icon: const Icon(Icons.description_rounded, size: 18, color: Colors.white),
                                          label: const Text(
                                            "VIEW COMPLETE DOSSIER",
                                            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (err, stack) => const SizedBox(),
                        ),
                        const SizedBox(height: 20),
                      ],
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
}
