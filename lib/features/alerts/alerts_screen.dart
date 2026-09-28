import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../models/alert_model.dart';
import '../../providers/app_providers.dart';
import 'random_verification_dialog.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsList = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Sovereign Official Header
            const GovtEmblemHeader(
              compact: true,
              subtitle: "National Command Incident & Dispatch Alerts",
            ),

            Expanded(
              child: alertsList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none_rounded, size: 36, color: AppColors.primaryNavy),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No Active Incident Alerts",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Automated anomaly triggers and surprise audit dispatches will appear here.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const RandomVerificationDialog(sessionData: {
                                    'project_name': 'DoSJE Real-Time Monitoring',
                                    'reason': 'Surprise Random Biometric Verification Request',
                                  }),
                                );
                              },
                              icon: const Icon(Icons.security_rounded, size: 18),
                              label: const Text("TRIGGER RANDOM VERIFICATION"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alertsList.length,
                      itemBuilder: (context, index) {
                        return _buildAlertTile(context, alertsList[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, AlertModel item) {
    Color severityColor;
    switch (item.severity.toUpperCase()) {
      case 'CRITICAL':
        severityColor = AppColors.statusRed;
        break;
      case 'WARNING':
        severityColor = AppColors.statusAmber;
        break;
      default:
        severityColor = const Color(0xFF0284C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A192F),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: severityColor.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.notifications_active_rounded, color: severityColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.severity.toUpperCase(),
                          style: TextStyle(color: severityColor, fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.timestamp.length >= 19 ? item.timestamp.substring(0, 19) : item.timestamp,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
