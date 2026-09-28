import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/attendance_record.dart';

class AttendanceVerificationScreen extends StatefulWidget {
  final String inspectionId;

  const AttendanceVerificationScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  State<AttendanceVerificationScreen> createState() =>
      _AttendanceVerificationScreenState();
}

class _AttendanceVerificationScreenState
    extends State<AttendanceVerificationScreen> {
  final int _expected = 120;
  int _verified = 103;
  bool _isProcessingBiometric = false;
  String? _lastScanResult;

  final List<BeneficiaryRecord> _beneficiaries = [
    const BeneficiaryRecord(
      id: 'BEN-001',
      udidNumber: 'UDID-TN-2024-8891',
      name: 'M. Selvakumar',
      category: 'Divyangjan (Locomotor)',
      isPresent: true,
      method: VerificationMethod.faceRecognition,
      faceConfidence: 0.94,
    ),
    const BeneficiaryRecord(
      id: 'BEN-002',
      udidNumber: 'UDID-TN-2023-1104',
      name: 'R. Ananthi',
      category: 'Divyangjan (Visual Impairment)',
      isPresent: true,
      method: VerificationMethod.qrCode,
    ),
    const BeneficiaryRecord(
      id: 'BEN-003',
      udidNumber: 'UDID-TN-2025-4421',
      name: 'K. Balakrishnan',
      category: 'Senior Citizen Support',
      isPresent: true,
      method: VerificationMethod.manual,
    ),
    const BeneficiaryRecord(
      id: 'BEN-004',
      udidNumber: 'UDID-TN-2024-9982',
      name: 'P. Vijayalakshmi',
      category: 'Rehabilitation Trainee',
      isPresent: false,
    ),
    const BeneficiaryRecord(
      id: 'BEN-005',
      udidNumber: 'UDID-TN-2025-3310',
      name: 'S. Vigneshwaran',
      category: 'Divyangjan (Hearing Impairment)',
      isPresent: true,
      method: VerificationMethod.faceRecognition,
      faceConfidence: 0.91,
    ),
  ];

  void _triggerFaceScan() async {
    setState(() {
      _isProcessingBiometric = true;
      _lastScanResult = 'Camera active... Detecting face & quality score...';
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() {
      _lastScanResult =
          'Face Quality: 96% • Liveness check PASSED • Embedding matched with UDID registry (Confidence: 93.8%)';
      _isProcessingBiometric = false;
      _verified = (_verified < _expected) ? _verified + 1 : _verified;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _expected - _verified;
    final percentage = ((_verified / _expected) * 100).toStringAsFixed(1);
    final progressValue = _verified / _expected;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Beneficiary Attendance Audit'),
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.analytical,
        child: Column(
          children: [
            // 1. Circular / Gauge Progress Hero Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0C192E).withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Circular Ring Gauge
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progressValue,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFF162A45),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.neonCyan,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Counts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BENEFICIARY ATTENDANCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonCyan,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_verified / $_expected verified',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildMiniTag(
                              'Verified: $_verified',
                              AppColors.neonEmerald,
                              AppColors.neonEmerald.withValues(alpha: 0.15),
                              AppColors.neonEmerald.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            _buildMiniTag(
                              'Pending: $pending',
                              AppColors.solarSaffron,
                              AppColors.solarSaffron.withValues(alpha: 0.15),
                              AppColors.solarSaffron.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Privacy & Biometric Consent Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF081C30),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.4),
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.neonCyan),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MoSJE Data Protection: Facial embeddings processed in isolated memory. Zero raw biometrics stored.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Verification Action Buttons
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(
                          color: AppColors.neonCyan,
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isProcessingBiometric
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.neonCyan,
                              ),
                            )
                          : const Icon(Icons.face_retouching_natural, size: 16),
                      label: const Text('Face Audit'),
                      onPressed: _isProcessingBiometric ? null : _triggerFaceScan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentSaffron,
                        side: const BorderSide(
                          color: AppColors.accentSaffron,
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('UDID Scan'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('UDID Card Scanner ready for optical barcode.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (_lastScanResult != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09231D),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                      color: AppColors.neonEmerald.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonEmerald.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.neonEmerald,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastScanResult!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neonEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 4. Beneficiary Roster Sample
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _beneficiaries.length,
                itemBuilder: (context, index) {
                  final b = _beneficiaries[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C192E).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(
                        color: b.isPresent
                            ? AppColors.neonEmerald.withValues(alpha: 0.3)
                            : AppColors.cyberBorder.withValues(alpha: 0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: b.isPresent
                              ? AppColors.neonEmerald.withValues(alpha: 0.15)
                              : AppColors.dangerRed.withValues(alpha: 0.15),
                          child: Icon(
                            b.isPresent ? Icons.check : Icons.person_off_outlined,
                            size: 18,
                            color: b.isPresent
                                ? AppColors.neonEmerald
                                : AppColors.dangerRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${b.udidNumber} • ${b.category}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (b.faceConfidence != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.neonCyan.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'Face: ${(b.faceConfidence! * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // 5. Proceed Action Bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: const Color(0xFF071224).withValues(alpha: 0.96),
                border: Border(
                  top: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: AppButton(
                label: 'Proceed to AI Anomaly Analytics',
                icon: Icons.auto_awesome_outlined,
                onPressed: () {
                  context.push('/inspection/${widget.inspectionId}/analytics');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(
    String label,
    Color textColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
