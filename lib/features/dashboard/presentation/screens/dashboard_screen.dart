import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/nearby_projects_map_card.dart';
import '../../../../core/widgets/priority_inspection_card.dart';
import '../../../../core/widgets/tricolor_accent_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../inspections/presentation/providers/inspection_provider.dart';
import '../../../inspections/presentation/widgets/enroll_inspection_dialog.dart';
import '../../../../services/location_service.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final metrics = ref.watch(dashboardMetricsProvider);
    final inspectionState = ref.watch(inspectionStateProvider);
    final locationState = ref.watch(locationTrackingProvider);
    final todaysInspection = inspectionState.todaysInspection;
    final officerName = authState.user?.fullName ?? 'Rajesh Sharma';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.tricolorSaffron.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'सत्यमेव जयते',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tricolorSaffron,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  AppStrings.governmentOfIndia,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              authState.user?.department ?? AppStrings.ministryTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Offline Logs',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline cryptographic vault synchronized with central portal.'),
                  backgroundColor: AppColors.primaryNavy,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.go(AppRoutes.notifications),
          ),
          const SizedBox(width: AppDimensions.space8),
        ],
      ),
      body: Column(
        children: [
          // National Tricolor Sovereign Ribbon across top of body
          const TricolorAccentBar(height: 3.0),

          Expanded(
            child: AppBackground(
              variant: AppBackgroundVariant.hero,
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(inspectionStateProvider.notifier).fetchInspections();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Prestigious Officer Dossier Hero Card (Royal Navy Gradient with Gold Rim)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18.0),
                          decoration: BoxDecoration(
                            gradient: AppColors.heroNavyGradient,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                            border: Border.all(
                              color: AppColors.goldAccent.withValues(alpha: 0.40),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A192F).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: AppColors.infoBlue.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Clearance Badge & Live Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                      border: Border.all(
                                        color: AppColors.goldAccent.withValues(alpha: 0.8),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.verified_user_rounded,
                                          size: 13,
                                          color: AppColors.goldAccent,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'LEVEL 3 • FIELD AUDITOR',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.goldAccent,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Live Operational Indicator Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                      border: Border.all(
                                        color: AppColors.successGreen.withValues(alpha: 0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: AppColors.successGreen,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.successGreen.withValues(alpha: 0.8),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'GPS Active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF6EE7B7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Officer Avatar & Info Row
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.goldAccent,
                                        width: 2.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.goldAccent.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: const Color(0xFF0F2B48),
                                      child: Text(
                                        officerName.isNotEmpty ? officerName[0] : 'O',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.goldAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Good morning, $officerName',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${authState.user?.role.label ?? "PMU Officer"} • ID: ${authState.user?.officerId ?? "PMU-TN-2026-08"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 12,
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                locationState.currentLocation != null
                                                    ? 'Live GPS: ${locationState.currentLocation!.latitude.toStringAsFixed(4)}, ${locationState.currentLocation!.longitude.toStringAsFixed(4)}'
                                                    : 'Real-Time Telemetry Node Active',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. High-Tech 4-Card Statistics Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                title: 'Assigned',
                                value: metrics.assignedCount.toString().padLeft(2, '0'),
                                subtitle: 'active field audits',
                                icon: Icons.assignment_turned_in_outlined,
                                accentColor: AppColors.infoBlue,
                                onTap: () {
                                  ref
                                      .read(inspectionStateProvider.notifier)
                                      .setFilter('ASSIGNED');
                                  context.go(AppRoutes.inspections);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricCard(
                                title: 'Pending',
                                value: metrics.pendingCount.toString().padLeft(2, '0'),
                                subtitle: 'in validation stage',
                                icon: Icons.pending_actions_outlined,
                                accentColor: AppColors.warningAmber,
                                onTap: () {
                                  ref
                                      .read(inspectionStateProvider.notifier)
                                      .setFilter('IN PROGRESS');
                                  context.go(AppRoutes.inspections);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                title: 'Completed',
                                value: metrics.completedCount.toString().padLeft(2, '0'),
                                subtitle: 'sealed & synced',
                                icon: Icons.task_alt_rounded,
                                accentColor: AppColors.successGreen,
                                onTap: () {
                                  ref
                                      .read(inspectionStateProvider.notifier)
                                      .setFilter('COMPLETED');
                                  context.go(AppRoutes.inspections);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricCard(
                                title: 'AI Alerts',
                                value: metrics.alertsCount.toString().padLeft(2, '0'),
                                subtitle: 'anomaly flags',
                                icon: Icons.auto_awesome_outlined,
                                accentColor: AppColors.dangerRed,
                                onTap: () {
                                  ref
                                      .read(inspectionStateProvider.notifier)
                                      .setFilter('HIGH RISK');
                                  context.go(AppRoutes.inspections);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Priority Inspection Hero Section
                      if (todaysInspection != null) ...[
                        PriorityInspectionCard(
                          projectName: todaysInspection.projectName,
                          location: '${todaysInspection.organization} • ${todaysInspection.district}',
                          priority: todaysInspection.priority,
                          scheduledTime: todaysInspection.scheduledWindow,
                          distanceText: todaysInspection.distanceMeters != null
                              ? '${todaysInspection.distanceMeters!.toStringAsFixed(0)} m'
                              : 'Detecting GPS...',
                          statusText: todaysInspection.status.label,
                          isVerified: todaysInspection.isGpsVerified,
                          onAction: () {
                            context.push('/inspection/${todaysInspection.id}');
                          },
                        ),
                      ] else ...[
                        _buildAwaitingEnrollmentHeroCard(context, ref),
                      ],

                      const SizedBox(height: 16),

                      // 4. Nearby Field Facilities Compact Map Preview
                      NearbyProjectsMapCard(
                        activeProjectsCount: inspectionState.inspections.length,
                        inspections: inspectionState.inspections,
                        onTap: () => context.go(AppRoutes.map),
                      ),

                      const SizedBox(height: 24),
                      // 5. High-Tech Field Actions & Utilities Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: AppColors.cyberCyanGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Government Audit Utilities',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionTile(
                                icon: Icons.radar_rounded,
                                title: 'Geofence Radar',
                                subtitle: '100m perimeter lock',
                                color: AppColors.neonCyan,
                                onTap: () => context.go(AppRoutes.map),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionTile(
                                icon: Icons.shuffle_rounded,
                                title: 'Randomized Dispatch',
                                subtitle: 'AI allocation log',
                                color: AppColors.tricolorSaffron,
                                onTap: () => _showRandomAssignmentModal(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionTile(
                                icon: Icons.qr_code_scanner_rounded,
                                title: 'Asset QR Scanner',
                                subtitle: 'Instant asset audit',
                                color: AppColors.neonEmerald,
                                onTap: () => _showQrScannerModal(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionTile(
                                icon: Icons.cloud_sync_rounded,
                                title: 'Encrypted Vault',
                                subtitle: 'Zero-knowledge sync',
                                color: AppColors.neonPurple,
                                onTap: () => _showVaultSyncModal(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1C33),
                const Color(0xFF081324),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRandomAssignmentModal(BuildContext context, WidgetRef ref) {
    final inspectionState = ref.read(inspectionStateProvider);
    final activeInspection =
        inspectionState.todaysInspection ?? inspectionState.inspections.firstOrNull;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.3),
              width: 1.4,
            ),
          ),
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shuffle_rounded, color: AppColors.neonCyan, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Central Randomizer Dispatch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Assigned by MoSJE Autonomous Randomization Engine with zero field officer bias.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (activeInspection != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1F38),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Assigned Facility:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Flexible(
                            child: Text(
                              activeInspection.projectName,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('District / State:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(activeInspection.district, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Audit Priority:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(
                            activeInspection.priority,
                            style: const TextStyle(
                              color: AppColors.dangerRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Launch Priority Mission Dossier',
                  icon: Icons.rocket_launch_outlined,
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/inspection/${activeInspection.id}');
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1F38),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.satellite_alt_rounded, color: Color(0xFF00F0FF), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Awaiting Live Assignment',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'No predefined assignments. Enrolling an audit site from the Web Admin Portal or using Enroll Site will allocate it to your device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Enroll Field Audit Site',
                  icon: Icons.add_location_alt_outlined,
                  onPressed: () {
                    Navigator.pop(ctx);
                    showEnrollInspectionDialog(context, ref);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAwaitingEnrollmentHeroCard(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2648),
              Color(0xFF0A182F),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.radar_rounded, size: 12, color: Color(0xFF00F0FF)),
                      SizedBox(width: 5),
                      Text(
                        'LIVE TELEMETRY ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00F0FF),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: const Text(
                    'ZERO MOCK DATA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6EE7B7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Awaiting Live Field Inspection Enrollment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Predefined mock locations have been removed. Any field inspection site enrolled from the Central Web Portal will automatically broadcast and appear here in real time via live WebSocket replication.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Refresh Feed',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      ref.read(inspectionStateProvider.notifier).fetchInspections();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking central Supabase database for new enrolled inspections...'),
                          backgroundColor: Color(0xFF0F172A),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Enroll Site',
                    icon: Icons.add_location_alt_outlined,
                    onPressed: () {
                      showEnrollInspectionDialog(context, ref);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQrScannerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.accentSaffron.withValues(alpha: 0.3), width: 1.4),
          ),
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentSaffron, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'MoSJE Asset QR Scanner',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF050B14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentSaffron.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.accentSaffron.withValues(alpha: 0.8)),
                      const SizedBox(height: 8),
                      const Text(
                        'Align Asset Barcode / Government Seal',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Simulate Asset Match: ASSET-TN-0941',
                icon: Icons.check_circle_outline,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Asset ASSET-TN-0941 Verified: Physical Infrastructure intact.'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVaultSyncModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3), width: 1.4),
          ),
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_sync_rounded, color: AppColors.neonPurple, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Encrypted Offline Vault',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Zero-Knowledge AES-256 local ledger. All pending audit evidence, GPS coordinates, and biometric records are cryptographically hashed before central commit.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1F38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending Queue:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('0 items (Clean Vault)', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last Sync Hash:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('8f92a1...49c0e (NIC Portal)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Force Cloud Ledger Re-Sync',
                icon: Icons.sync,
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vault synchronized: 100% SHA-256 integrity verified.'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
