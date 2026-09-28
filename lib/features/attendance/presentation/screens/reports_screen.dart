import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'GOVERNMENT AUDIT REPORTS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportTile(context, title: 'Attendance Audit Report', subtitle: 'Daily & weekly verification compliance logs', icon: Icons.fact_check),
          _buildReportTile(context, title: 'Biometric Verification Report', subtitle: 'Face, Voice, and GPS accuracy telemetry', icon: Icons.fingerprint),
          _buildReportTile(context, title: 'Geofence Breach Event Log', subtitle: 'Unauthorized boundary entry and exit history', icon: Icons.map_rounded),
          _buildReportTile(context, title: 'Security Alert Summary', subtitle: 'System-generated anomaly logs and resolutions', icon: Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _buildReportTile(BuildContext context, {required String title, required String subtitle, required IconData icon}) {
    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderDark)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.tricolorSaffron, size: 24),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.download_rounded, color: AppColors.textPrimary, size: 20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloading $title...')),
          );
        },
      ),
    );
  }
}
