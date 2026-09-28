import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../services/location_service.dart';

/// Clean enterprise screen that transparently explains the requirement for
/// location tracking during official MoSJE field audits and requests permissions.
class PermissionScreen extends ConsumerWidget {
  final VoidCallback onPermissionGranted;

  const PermissionScreen({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationTrackingProvider);
    final notifier = ref.read(locationTrackingProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Location Authorization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Government Shield & Location Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                  ),
                  child: const Icon(
                    Icons.share_location_rounded,
                    size: 40,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Official Field Location Verification Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'In compliance with MoSJE SIH 26095 monitoring guidelines, inspectors must verify physical presence within the designated NGO project geofence before conducting audits.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 28),

              // Privacy Safeguards Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildFeatureBullet(
                      icon: Icons.visibility_rounded,
                      title: 'Transparent & Audited',
                      subtitle: 'Location is only recorded while an inspection session is actively running.',
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildFeatureBullet(
                      icon: Icons.shield_outlined,
                      title: 'Role-Based Row Level Security',
                      subtitle: 'Only authorized PMU and ministry personnel can view verification logs.',
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _buildFeatureBullet(
                      icon: Icons.power_settings_new_rounded,
                      title: 'User-Controlled Session',
                      subtitle: 'You can halt or conclude location tracking at any point with the Stop button.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error notification if permission was denied
              if (state.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Primary Action: Request Permission
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (state.status == LocationServiceStatus.permissionPermanentlyDenied) {
                      await notifier.openAppSettings();
                    } else if (state.status == LocationServiceStatus.gpsDisabled) {
                      await notifier.openLocationSettings();
                    } else {
                      final granted = await notifier.checkPermission();
                      if (granted) {
                        onPermissionGranted();
                      }
                    }
                  },
                  child: Text(
                    state.status == LocationServiceStatus.permissionPermanentlyDenied
                        ? 'Open Device App Settings'
                        : (state.status == LocationServiceStatus.gpsDisabled
                            ? 'Enable Device GPS'
                            : 'Grant Location Permission'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
