import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _mockLocationDetection = true;
  bool _autoSyncOnWifi = true;
  bool _highAccuracyGps = true;
  bool _biometricQuickLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('System Settings & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        children: [
          _buildSectionHeader('GEOLOCATION & ANTI-SPOOFING'),
          _buildSwitchTile(
            title: 'Mock GPS Spoofing Detection',
            subtitle:
                'Immediately block check-in when mock coordinate providers or GPS fakers are running.',
            value: _mockLocationDetection,
            onChanged: (val) => setState(() => _mockLocationDetection = val),
          ),
          _buildSwitchTile(
            title: 'High-Precision Satellite GPS',
            subtitle: 'Enforce minimum Â±25m accuracy before enabling checklist submission.',
            value: _highAccuracyGps,
            onChanged: (val) => setState(() => _highAccuracyGps = val),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('OFFLINE STORAGE & SYNCHRONIZATION'),
          _buildSwitchTile(
            title: 'Auto-Sync on Network Return',
            subtitle: 'Automatically flush encrypted drafts and evidence hashes when signal restores.',
            value: _autoSyncOnWifi,
            onChanged: (val) => setState(() => _autoSyncOnWifi = val),
          ),
          _buildSwitchTile(
            title: 'Biometric Officer Authentication',
            subtitle: 'Use fingerprint / FaceID for resuming field inspection sessions.',
            value: _biometricQuickLogin,
            onChanged: (val) => setState(() => _biometricQuickLogin = val),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('STORAGE & CACHE'),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.roundedSmall,
              side: const BorderSide(color: AppColors.borderLight),
            ),
            title: const Text(
              'Clear Cached Thumbnails',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Frees up temporary image cache without deleting encrypted audit records.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.cleaning_services_outlined, size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cached media cleared successfully.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
                    const SizedBox(height: 16),
          _buildSectionHeader('DEVELOPER & LOCAL ARCHITECTURE'),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
            leading: const Icon(Icons.developer_mode, color: AppColors.primaryNavy),
            title: const Text(
              'Developer Connection Diagnostics',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Inspect real-time health of FastAPI, Supabase, Geofence, and WebSockets.',
              style: TextStyle(fontSize: 11, color: AppColors.primaryMuted),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              context.push('/diagnostics');
            },
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Text(
                  'MoSJE Nirikshan v1.0.0 (SIH Build 26095)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Department of Social Justice and Empowerment',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.roundedSmall,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        value: value,
        activeTrackColor: AppColors.primaryNavy,
        onChanged: onChanged,
      ),
    );
  }
}


