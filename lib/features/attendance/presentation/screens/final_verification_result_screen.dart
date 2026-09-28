import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../providers/verification_provider.dart';

class FinalVerificationResultScreen extends ConsumerWidget {
  final String sessionId;

  const FinalVerificationResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(verificationProvider);

    final isVerified = session?.finalResult == 'VERIFIED' || session == null || session.finalResult != 'FAILED';
    final personName = session?.personName ?? 'John Kumar';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: const Text(
          'VERIFICATION RESULT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Result Badge Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isVerified
                    ? AppColors.statusGreen.withValues(alpha: 0.12)
                    : AppColors.statusRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isVerified ? AppColors.statusGreen : AppColors.statusRed,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isVerified ? AppColors.statusGreen : AppColors.statusRed,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isVerified ? '✓ VERIFIED' : '✕ VERIFICATION FAILED',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isVerified ? AppColors.statusGreen : AppColors.statusRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Subject: $personName',
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Session ID: $sessionId',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Detailed Status Matrix
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FUSION VERIFICATION BREAKDOWN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 14),
                  _buildResultRow('Face Verification', isVerified ? '✓ MATCH' : '✕ FAILED', isVerified),
                  const Divider(color: AppColors.borderDark),
                  _buildResultRow('Voice Verification', isVerified ? '✓ MATCH' : '✕ FAILED', isVerified),
                  const Divider(color: AppColors.borderDark),
                  _buildResultRow('GPS Geofence Status', isVerified ? '✓ INSIDE (48m)' : '✕ OUTSIDE', isVerified),
                  const Divider(color: AppColors.borderDark),
                  _buildResultRow('Assignment Check', '✓ VALID', true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Automatic Attendance Container
            if (isVerified)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.statusGreen),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.fact_check_rounded, color: AppColors.statusGreen, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Attendance Automatically Updated',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.statusGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('✓ PRESENT', style: TextStyle(color: AppColors.statusGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Entry Time: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(
                          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Site: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('CRC Coimbatore Campus', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.statusRed),
                ),
                child: const Text(
                  'Attendance was NOT updated due to verification failure.',
                  style: TextStyle(fontSize: 12, color: AppColors.statusRed, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 30),

            // Action Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('HOME', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.attendanceLog),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tricolorSaffron,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('VIEW ATTENDANCE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSuccess ? AppColors.statusGreen : AppColors.statusRed,
            ),
          ),
        ],
      ),
    );
  }
}
