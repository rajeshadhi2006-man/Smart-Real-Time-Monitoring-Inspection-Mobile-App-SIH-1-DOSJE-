import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/alerts_provider.dart';


class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);
    final alerts = alertsState.asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'REAL-TIME SECURITY ALERTS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: alertsState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.statusRed))),
        data: (_) {
          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.statusGreen, size: 52),
                  SizedBox(height: 12),
                  Text('No Active Security Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('System operating nominally under authorized geofence bounds.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),

            itemBuilder: (context, index) {
              final alert = alerts[index];
              final isNew = alert.status == 'NEW';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isNew ? AppColors.statusRed : AppColors.borderDark, width: isNew ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.statusRed),
                          ),
                          child: Text(
                            alert.severity,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusRed),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.category,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Person: ${alert.personName} (ID: ${alert.personId})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Location: ${alert.location}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(color: AppColors.borderDark, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (alert.status == 'NEW')
                          OutlinedButton(
                            onPressed: () {
                              ref.read(alertsProvider.notifier).updateAlertStatus(alert.id, 'ACKNOWLEDGED');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.statusAmber),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('ACKNOWLEDGE', style: TextStyle(fontSize: 11, color: AppColors.statusAmber, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(alertsProvider.notifier).updateAlertStatus(alert.id, 'RESOLVED');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('RESOLVE', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
