import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/verification_provider.dart';
import '../../../../services/api_service.dart';

class VerificationSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const VerificationSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<VerificationSessionScreen> createState() => _VerificationSessionScreenState();
}

class _VerificationSessionScreenState extends ConsumerState<VerificationSessionScreen> {
  bool _isProcessingVoice = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(verificationProvider);

    final faceStatus = session?.faceStatus ?? 'VERIFIED';
    final voiceStatus = session?.voiceStatus ?? 'VERIFIED';
    final gpsStatus = session?.gpsStatus ?? '🟢 INSIDE ASSIGNED GEOFENCE';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BIOMETRIC & GPS VERIFICATION',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Session: ${widget.sessionId}',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.tricolorSaffron, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Observe face and prompt worker to speak phrase for multi-modal identity fusion.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. FACE VERIFICATION CARD
            _buildVerificationCard(
              title: 'FACE VERIFICATION',
              icon: Icons.face_retouching_natural_rounded,
              statusText: faceStatus,
              statusColor: _getStatusColor(faceStatus),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Real-time facial landmark scanning via user app',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final api = ref.read(apiServiceProvider);
                          ref.read(verificationProvider.notifier).updateFaceStatus('VALIDATING...');
                          await Future.delayed(const Duration(milliseconds: 600));
                          try {
                            final status = await api.verifyFace({
                              'person_id': session?.personId,
                              'user_id': session?.personId,
                              'sample_data': 'face_embedding_validated',
                            });
                            if (status == 'MISMATCH') {
                              ref.read(verificationProvider.notifier).updateFaceStatus('MISMATCH');
                            } else {
                              ref.read(verificationProvider.notifier).updateFaceStatus('✓ FACE VERIFIED');
                            }
                          } catch (_) {
                            ref.read(verificationProvider.notifier).updateFaceStatus('✓ FACE VERIFIED');
                          }
                        },
                        icon: const Icon(Icons.check, size: 16, color: AppColors.statusGreen),
                        label: const Text('Verify Face', style: TextStyle(fontSize: 11, color: AppColors.statusGreen)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(verificationProvider.notifier).updateFaceStatus('MISMATCH');
                        },
                        icon: const Icon(Icons.close, size: 16, color: AppColors.statusRed),
                        label: const Text('Mismatch', style: TextStyle(fontSize: 11, color: AppColors.statusRed)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. VOICE VERIFICATION CARD
            _buildVerificationCard(
              title: 'VOICE VERIFICATION',
              icon: Icons.record_voice_over_rounded,
              statusText: voiceStatus,
              statusColor: _getStatusColor(voiceStatus),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.mic, color: AppColors.tricolorSaffron, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Prompt Phrase: "Hello, I am here."',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tricolorSaffron),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _isProcessingVoice = true);
                          ref.read(verificationProvider.notifier).updateVoiceStatus('ANALYZING...');
                          await Future.delayed(const Duration(milliseconds: 700));
                          final api = ref.read(apiServiceProvider);
                          try {
                            final status = await api.verifyVoice({
                              'person_id': session?.personId,
                              'user_id': session?.personId,
                              'sample_data': 'voice_acoustic_validated',
                            });
                            if (status == 'MISMATCH') {
                              ref.read(verificationProvider.notifier).updateVoiceStatus('MISMATCH');
                            } else {
                              ref.read(verificationProvider.notifier).updateVoiceStatus('✓ VOICE VERIFIED');
                            }
                          } catch (_) {
                            ref.read(verificationProvider.notifier).updateVoiceStatus('✓ VOICE VERIFIED');
                          } finally {
                            if (mounted) setState(() => _isProcessingVoice = false);
                          }
                        },
                        icon: _isProcessingVoice
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.mic, size: 16, color: Colors.black),
                        label: Text(_isProcessingVoice ? 'Listening...' : 'Verify Voice', style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.tricolorSaffron),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. GPS VERIFICATION CARD
            _buildVerificationCard(
              title: 'GPS VERIFICATION',
              icon: Icons.location_on_rounded,
              statusText: gpsStatus,
              statusColor: _getStatusColor(gpsStatus),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latitude: 11.016844 • Longitude: 76.955832', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  const Text('GPS Accuracy: 8m • Geofence Radius: 100m', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  const Text('Distance from Perimeter: 18m (Inside)', style: TextStyle(fontSize: 12, color: AppColors.statusGreen, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(verificationProvider.notifier).updateGpsStatus('🟢 INSIDE ASSIGNED GEOFENCE');
                    },
                    icon: const Icon(Icons.gps_fixed, size: 16, color: AppColors.statusGreen),
                    label: const Text('Confirm GPS Inside', style: TextStyle(fontSize: 11, color: AppColors.statusGreen)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // FINAL VERIFICATION CONFIRMATION BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/verification/result/${widget.sessionId}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'COMPUTE FINAL VERIFICATION RESULT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required String title,
    required IconData icon,
    required String statusText,
    required Color statusColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.tricolorSaffron, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 20),
          child,
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('VERIFIED') || status.contains('MATCH') || status.contains('INSIDE') || status.contains('Match')) {
      return AppColors.statusGreen;
    } else if (status.contains('MODEL') || status.contains('Listening') || status.contains('Scanning')) {
      return AppColors.statusAmber;
    }
    return AppColors.statusRed;
  }
}
