import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../models/monitored_person.dart';
import '../../../../providers/monitored_persons_provider.dart';
import '../../../../providers/verification_provider.dart';

class PersonDetailScreen extends ConsumerWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsState = ref.watch(monitoredPersonsProvider);
    final persons = personsState.asData?.value ?? [];

    final person = persons.firstWhere(
      (p) => p.id == personId,
      orElse: () => MonitoredPerson(
        id: personId,
        name: 'John Kumar',
        status: 'INSIDE',
        assignedSite: 'District Rehabilitation Centre (CRC Coimbatore)',
        latitude: 11.016844,
        longitude: 76.955832,
        gpsAccuracy: 8.0,
        distanceMeters: 48.0,
        geofenceId: 'GEOFENCE-TN-CBE-01',
        geofenceName: 'CRC Coimbatore Geofence',
        lastUpdate: DateTime.now(),
        todayAttendanceStatus: 'PRESENT',
        deviceStatus: 'ONLINE',
      ),
    );

    final statusColor = AppColors.statusColor(person.status);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Text(
          'MONITORED DOSSIER — ${person.id}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryNavy,
                    child: Text(
                      person.name.substring(0, 1),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${person.id}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            person.status,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons Row
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final session = await ref.read(verificationProvider.notifier).startSession(
                        personId: person.id,
                        personName: person.name,
                        officerId: 'GOV-OFFICER-001',
                      );
                  if (context.mounted) {
                    context.push('/verification/call/${session.id}');
                  }
                },
                icon: const Icon(Icons.verified_user, color: Colors.black),
                label: const Text('VERIFY PERSON NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tricolorSaffron,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.live),
                    icon: const Icon(Icons.map, size: 16, color: AppColors.textPrimary),
                    label: const Text('VIEW LOCATION', style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.attendanceLog),
                    icon: const Icon(Icons.fact_check, size: 16, color: AppColors.textPrimary),
                    label: const Text('ATTENDANCE', style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Telemetry & GPS Specs Card
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
                    'TELEMETRY & GEOFENCE STATUS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Assigned Location', person.assignedSite),
                  const Divider(color: AppColors.borderDark),
                  _buildDetailRow('Current GPS', '${person.latitude}, ${person.longitude}'),
                  const Divider(color: AppColors.borderDark),
                  _buildDetailRow('GPS Accuracy', '±${person.gpsAccuracy.toInt()}m'),
                  const Divider(color: AppColors.borderDark),
                  _buildDetailRow('Distance from Geofence', '${person.distanceMeters.toInt()}m'),
                  const Divider(color: AppColors.borderDark),
                  _buildDetailRow('Device Connectivity', person.deviceStatus),
                  const Divider(color: AppColors.borderDark),
                  _buildDetailRow('Today\'s Attendance', person.todayAttendanceStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
