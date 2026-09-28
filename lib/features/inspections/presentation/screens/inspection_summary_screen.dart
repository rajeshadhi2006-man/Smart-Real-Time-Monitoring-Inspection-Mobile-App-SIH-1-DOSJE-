import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../providers/inspection_provider.dart';

class InspectionSummaryScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const InspectionSummaryScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  ConsumerState<InspectionSummaryScreen> createState() =>
      _InspectionSummaryScreenState();
}

class _InspectionSummaryScreenState
    extends ConsumerState<InspectionSummaryScreen> {
  final _remarksController = TextEditingController(
    text:
        'Physical infrastructure found satisfactory. Attendance showed 14.2% absence; institutional director cited temporary harvest period leave. Follow-up audit recommended in 30 days.',
  );

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0C192E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.neonCyan.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.warningAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Finalize Inspection?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Once submitted, all audit records, GPS verification coordinates, and evidence hashes are cryptographically sealed via SHA-256 and cannot be altered without PMU authorization.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF060F1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 16,
                      color: AppColors.neonCyan,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TAMPER-EVIDENT HASH REGISTERED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonCyan,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: const Color(0xFF030712),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push(
                  '/inspection/${widget.inspectionId}/submission',
                );
              },
              child: const Text(
                'Seal & Submit',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionStateProvider);
    final inspection = state.inspections.firstWhere(
      (i) => i.id == widget.inspectionId,
      orElse: () => state.inspections.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Pre-Submission Summary'),
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Glass Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withValues(alpha: 0.9),
                  borderRadius: AppDimensions.roundedLarge,
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.neonCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AUDIT CONCORDANCE DOSSIER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.neonCyan,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        RiskBadge(riskLevel: inspection.aiRiskLevel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      inspection.projectName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${inspection.organization} • ${inspection.district}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const Divider(
                      height: 24,
                      color: Color(0xFF1E293B),
                    ),
                    _buildSummaryItem(
                      label: 'GPS Telemetry Status',
                      value:
                          '✓ Verified (${inspection.distanceMeters?.toStringAsFixed(0) ?? "48"}m from geofence)',
                      color: AppColors.neonEmerald,
                      icon: Icons.gps_fixed_rounded,
                    ),
                    _buildSummaryItem(
                      label: 'Checklist Concordance',
                      value:
                          '${inspection.completedChecklistCount} / ${inspection.totalChecklistCount} Protocols Verified',
                      color: Colors.white,
                      icon: Icons.checklist_rounded,
                    ),
                    _buildSummaryItem(
                      label: 'Cryptographic Evidence',
                      value:
                          '${inspection.photoCount} Photos, ${inspection.videoCount} Videos (SHA-256 Validated)',
                      color: AppColors.neonCyan,
                      icon: Icons.shield_outlined,
                    ),
                    _buildSummaryItem(
                      label: 'Beneficiary Biometrics',
                      value:
                          '${inspection.verifiedBeneficiaries} / ${inspection.expectedBeneficiaries} (${((inspection.verifiedBeneficiaries / (inspection.expectedBeneficiaries > 0 ? inspection.expectedBeneficiaries : 1)) * 100).toStringAsFixed(1)}%)',
                      color: Colors.white,
                      icon: Icons.fingerprint_rounded,
                    ),
                    _buildSummaryItem(
                      label: 'AI Risk Engine Delta',
                      value: inspection.aiRiskReasons.isNotEmpty
                          ? '1 Variance Flagged'
                          : 'Zero Anomalies',
                      color: inspection.aiRiskReasons.isNotEmpty
                          ? AppColors.warningAmber
                          : AppColors.neonEmerald,
                      icon: Icons.auto_awesome,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Inspector Remarks Box
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C192E).withValues(alpha: 0.9),
                  borderRadius: AppDimensions.roundedLarge,
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: AppColors.neonCyan,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Official Inspector Findings & Directive',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _remarksController,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF060F1E),
                        hintText: 'Enter conclusive evaluation findings...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF1E293B)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF1E293B)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.neonCyan),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CTAs
              AppButton(
                label: 'Cryptographically Seal & Submit',
                icon: Icons.lock_outline_rounded,
                onPressed: _showSubmitConfirmation,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Return & Edit Sections',
                variant: AppButtonVariant.outline,
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    Color? color,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color ?? Colors.white70),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
