import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/realtime_connection_provider.dart';
import '../../../../services/realtime_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officerState = ref.watch(authProvider);
    final connectionStatus = ref.watch(realtimeConnectionProvider).value ?? RealtimeConnectionStatus.connected;
    final officer = officerState.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'GOVERNMENT OFFICER DOSSIER',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Officer Profile Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryNavy,
                    child: Text(
                      officer != null ? officer.name.substring(0, 1) : 'O',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    officer?.name ?? 'Officer Rajesh Sharma',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    officer?.role ?? 'Senior PMU Field Inspector',
                    style: const TextStyle(fontSize: 12, color: AppColors.tricolorSaffron, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    officer?.department ?? 'Ministry of Social Justice & Empowerment',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Credentials Specification
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OFFICIAL CREDENTIALS & SYSTEM STATUS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow('Officer ID', officer?.id ?? 'GOV-OFFICER-001'),
                  const Divider(color: AppColors.borderDark),
                  _buildProfileRow('Official Email', officer?.email ?? 'rajesh.sharma@socialjustice.gov.in'),
                  const Divider(color: AppColors.borderDark),
                  _buildProfileRow('Account Clearances', officer?.accountStatus ?? 'ACTIVE'),
                  const Divider(color: AppColors.borderDark),
                  _buildProfileRow('Connected Device', officer?.connectedDevice ?? 'Official Field Node #4'),
                  const Divider(color: AppColors.borderDark),
                  _buildProfileRow(
                    'Backend WebSocket',
                    connectionStatus == RealtimeConnectionStatus.connected ? '🟢 Connected' : '🔴 Offline',
                    isStatus: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings & Quick Menu Actions
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security, color: AppColors.tricolorSaffron),
                    title: const Text('System Permissions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Location, Camera, Microphone, Notifications', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: () => context.push(AppRoutes.permissions),
                  ),
                  const Divider(color: AppColors.borderDark, height: 1),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: AppColors.statusBlue),
                    title: const Text('Audit Reports & Logs', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: () => context.push(AppRoutes.reports),
                  ),
                  const Divider(color: AppColors.borderDark, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.statusRed),
                    title: const Text('Log Out', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold, fontSize: 14)),
                    onTap: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isStatus ? (value.contains('Connected') ? AppColors.statusGreen : AppColors.statusRed) : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
