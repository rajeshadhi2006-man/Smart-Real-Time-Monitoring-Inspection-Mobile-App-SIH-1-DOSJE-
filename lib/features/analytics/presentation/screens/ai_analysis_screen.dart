import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../domain/models/anomaly_report.dart';

class AiAnalysisScreen extends StatelessWidget {
  final String inspectionId;

  const AiAnalysisScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context) {
    final report = AnomalyReport.mockForInspection(inspectionId);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Monitoring Analysis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Autonomous Anomaly Detection Engine',
              style: TextStyle(fontSize: 11, color: AppColors.neonCyan),
            ),
          ],
        ),
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.analytical,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Intelligence Risk Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(
                    color: AppColors.warningAmber.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warningAmber.withValues(alpha: 0.12),
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.warningAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: AppColors.warningAmber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI TELEMETRY EVALUATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warningAmber,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        RiskBadge(riskLevel: report.riskLevel),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Attendance Deviation Detected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Model Confidence: 87.4% • Engine: MoSJE-ANOMALY-v2.4',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(
                      height: 24,
                      color: Color(0xFF1E293B),
                    ),

                    _buildMetricRow('Overall Compliance Index', '${report.overallScore} / 100', color: Colors.white),
                    _buildMetricRow(
                      'Attendance Variance',
                      '${report.attendanceVariancePercent}% vs 90-day baseline',
                      color: AppColors.warningAmber,
                    ),
                    _buildMetricRow('Geofence Telemetry', '48m (Validated)', color: AppColors.neonEmerald),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Numbered Explanation Cards: "Why this was flagged"
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(Icons.hub_outlined, size: 16, color: AppColors.neonCyan),
                    SizedBox(width: 8),
                    Text(
                      'Automated Flag Diagnostic Reasons',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _buildExplanationCard(
                number: '01',
                title: 'Attendance Variance Deviation',
                description:
                    'Today’s verified headcount of 103 beneficiaries is 14.2% lower than historical baseline (118.4). Cross-check leaves.',
                tag: 'High Impact',
                tagColor: AppColors.warningAmber,
              ),
              const SizedBox(height: 8),

              _buildExplanationCard(
                number: '02',
                title: 'Pending Mandatory Evidence',
                description:
                    'Two required verification photo categories (Fire Safety NOC & Workshop Equipment) await cryptographic SHA-256 seal.',
                tag: 'Medium Impact',
                tagColor: AppColors.neonCyan,
              ),
              const SizedBox(height: 8),

              _buildExplanationCard(
                number: '03',
                title: 'Past Quarterly Audit Discrepancy',
                description:
                    'Previous audit on 12 Aug 2026 flagged a documentation backlog in PFMS staff disbursement records.',
                tag: 'Historical',
                tagColor: Colors.white60,
              ),

              const SizedBox(height: 20),

              // 3. Recommended Action Directive Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C192E),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: AppColors.neonCyan,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Recommended Course of Action',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.recommendedAction,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. CTA
              AppButton(
                label: 'Proceed to Final Summary Dossier',
                icon: Icons.checklist_rtl_rounded,
                onPressed: () {
                  context.push('/inspection/$inspectionId/summary');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard({
    required String number,
    required String title,
    required String description,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF060F1E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.neonCyan,
              ),
            ),
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
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
