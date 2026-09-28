import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/monitored_persons_provider.dart';
import '../../../../providers/alerts_provider.dart';
import '../../../../providers/realtime_connection_provider.dart';
import '../../../../services/realtime_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officerState = ref.watch(authProvider);
    final personsState = ref.watch(monitoredPersonsProvider);
    final alertsState = ref.watch(alertsProvider);
    final connectionStatus = ref.watch(realtimeConnectionProvider).value ?? RealtimeConnectionStatus.connected;

    final officer = officerState.asData?.value;
    final persons = personsState.asData?.value ?? [];
    final alerts = alertsState.asData?.value ?? [];

    final totalAssigned = persons.length;
    final insideCount = persons.where((p) => p.status == 'INSIDE').length;
    final outsideCount = persons.where((p) => p.status == 'OUTSIDE').length;
    final pendingCount = persons.where((p) => p.status == 'VERIFYING' || p.status == 'PENDING').length;
    final activeAlerts = alerts.where((a) => a.status != 'RESOLVED').length;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(authProvider.notifier).loadOfficer();
            ref.read(monitoredPersonsProvider.notifier).loadPersons();
            ref.read(alertsProvider.notifier).loadAlerts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.tricolorSaffron, width: 1.5),
                      ),
                      child: const Icon(Icons.account_balance, color: AppColors.tricolorSaffron, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Government Monitoring',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          Text(
                            officer != null ? 'Good Morning, ${officer.name}' : 'Good Morning, Officer',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Connection Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: connectionStatus == RealtimeConnectionStatus.connected
                            ? AppColors.statusGreen.withValues(alpha: 0.15)
                            : AppColors.statusRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: connectionStatus == RealtimeConnectionStatus.connected
                              ? AppColors.statusGreen
                              : AppColors.statusRed,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: connectionStatus == RealtimeConnectionStatus.connected
                                  ? AppColors.statusGreen
                                  : AppColors.statusRed,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connectionStatus == RealtimeConnectionStatus.connected ? 'Connected' : 'Offline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: connectionStatus == RealtimeConnectionStatus.connected
                                  ? AppColors.statusGreen
                                  : AppColors.statusRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                      onPressed: () => context.go(AppRoutes.alerts),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Stats Grid
                const Text(
                  'SYSTEM OVERVIEW',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Assigned Persons', '$totalAssigned', AppColors.primaryBlue, Icons.people_outline),
                    const SizedBox(width: 10),
                    _buildStatCard('Currently Inside', '$insideCount', AppColors.statusGreen.withValues(alpha: 0.2), Icons.g_mobiledata_rounded, textColor: AppColors.statusGreen),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard('Currently Outside', '$outsideCount', AppColors.statusRed.withValues(alpha: 0.2), Icons.location_off_outlined, textColor: AppColors.statusRed),
                    const SizedBox(width: 10),
                    _buildStatCard('Pending Verification', '$pendingCount', AppColors.statusAmber.withValues(alpha: 0.2), Icons.hourglass_empty, textColor: AppColors.statusAmber),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatCard('Active Alerts', '$activeAlerts', AppColors.statusRed.withValues(alpha: 0.3), Icons.warning_amber_rounded, textColor: AppColors.statusRed, isFullWidth: true),

                const SizedBox(height: 28),

                // Priority Action Section
                const Text(
                  'PRIORITY ACTIONS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),

                // Large VERIFY PERSON Card
                InkWell(
                  onTap: () => context.go(AppRoutes.verifyTab),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.govtHeaderGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.tricolorSaffron, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.tricolorSaffron.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user, color: AppColors.tricolorSaffron, size: 30),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VERIFY PERSON',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Initiate video call & biometric verification session',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Action Cards Grid
                Row(
                  children: [
                    _buildActionCard(
                      context,
                      title: 'LIVE MONITORING',
                      icon: Icons.radar,
                      route: AppRoutes.live,
                    ),
                    const SizedBox(width: 12),
                    _buildActionCard(
                      context,
                      title: 'ACTIVE ALERTS',
                      icon: Icons.warning_rounded,
                      route: AppRoutes.alerts,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildActionCard(
                      context,
                      title: 'GEOFENCES',
                      icon: Icons.map_rounded,
                      route: AppRoutes.geofences,
                    ),
                    const SizedBox(width: 12),
                    _buildActionCard(
                      context,
                      title: 'ATTENDANCE LOG',
                      icon: Icons.fact_check_rounded,
                      route: AppRoutes.attendanceLog,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Live Status Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LIVE MONITORED PERSONS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.live),
                      child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.statusBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (persons.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.person_off_outlined, color: AppColors.textMuted, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'No Monitored Persons Assigned',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Assigned field personnel will appear here dynamically.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: persons.take(4).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),

                    itemBuilder: (context, index) {
                      final person = persons[index];
                      final statusColor = AppColors.statusColor(person.status);

                      return InkWell(
                        onTap: () => context.push('/person/${person.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.borderDark,
                                child: Text(
                                  person.name.substring(0, 1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${person.id} • ${person.assignedSite}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      person.status,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GPS: ±${person.gpsAccuracy.toInt()}m',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor, IconData icon, {Color textColor = Colors.white, bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 0 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: textColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required String route}) {
    return Expanded(
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.statusBlue, size: 24),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
