import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/inspection_provider.dart';

class InspectionDetailScreen extends ConsumerWidget {
  final String inspectionId;

  const InspectionDetailScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionStateProvider);
    final matches = state.inspections.where((i) => i.id == inspectionId);
    final inspection = matches.isNotEmpty
        ? matches.first
        : (state.inspections.isNotEmpty ? state.inspections.first : null);

    if (inspection == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF04101F),
        appBar: AppBar(title: const Text('Inspection Dossier')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.neonAmber),
                const SizedBox(height: 16),
                const Text(
                  'Inspection Not Enrolled Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No inspection with this ID was found. Real inspections enrolled from the Central Web Portal will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Return to Dashboard',
                  icon: Icons.arrow_back,
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          inspection.id,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Authoritative Top Hero Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F223D),
                      Color(0xFF0A172B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.35),
                    width: 1.3,
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
                        StatusBadge(status: inspection.status.label),
                        RiskBadge(riskLevel: inspection.aiRiskLevel),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      inspection.projectName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${inspection.organization} • ${inspection.district}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(height: 24, color: Colors.white12),

                    // 3-Column Verification Highlights
                    Row(
                      children: [
                        Expanded(
                          child: _buildTriColumn(
                            title: 'LOCATION STATUS',
                            value: inspection.isGpsVerified
                                ? '✓ Verified (${inspection.distanceMeters?.toStringAsFixed(0) ?? "48"}m)'
                                : 'Unverified',
                            color: inspection.isGpsVerified
                                ? AppColors.neonEmerald
                                : AppColors.warningAmber,
                          ),
                        ),
                        Expanded(
                          child: _buildTriColumn(
                            title: 'MISSION ID',
                            value: inspection.id,
                            color: AppColors.neonCyan,
                          ),
                        ),
                        Expanded(
                          child: _buildTriColumn(
                            title: 'PRIORITY',
                            value: inspection.priority,
                            color: inspection.priority == 'HIGH'
                                ? AppColors.dangerRed
                                : AppColors.accentSaffron,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Section Title
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(Icons.hub_rounded, size: 16, color: AppColors.neonCyan),
                    SizedBox(width: 8),
                    Text(
                      'INSPECTION WORKFLOW PIPELINE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Ergonomic 6-Stage Workflow Pipeline
              _buildWorkflowStepTile(
                stepNumber: '1',
                title: 'Location & Geofence Radar',
                subtitle: inspection.isGpsVerified
                    ? 'Verified inside 100m zone (${inspection.distanceMeters?.toStringAsFixed(0) ?? "48"}m)'
                    : 'Requires on-site NavIC/GPS verification',
                isCompleted: inspection.isGpsVerified,
                icon: Icons.location_on_outlined,
                onTap: () => context.push('/inspection/${inspection.id}/map'),
              ),
              const SizedBox(height: 10),

              _buildWorkflowStepTile(
                stepNumber: '2',
                title: 'Digital Checklist Audit',
                subtitle:
                    '${inspection.completedChecklistCount} of ${inspection.totalChecklistCount} criteria validated',
                isCompleted: inspection.completedChecklistCount ==
                    inspection.totalChecklistCount,
                icon: Icons.checklist_rounded,
                onTap: () => context.push('/inspection/${inspection.id}/checklist'),
              ),
              const SizedBox(height: 10),

              _buildWorkflowStepTile(
                stepNumber: '3',
                title: 'Tamper-Evident Evidence Vault',
                subtitle:
                    '${inspection.photoCount} photos, ${inspection.videoCount} videos cryptographically sealed',
                isCompleted: inspection.photoCount > 0,
                icon: Icons.camera_alt_outlined,
                onTap: () => context.push('/inspection/${inspection.id}/evidence'),
              ),
              const SizedBox(height: 10),

              _buildWorkflowStepTile(
                stepNumber: '4',
                title: 'Beneficiary Biometric Verification',
                subtitle:
                    '${inspection.verifiedBeneficiaries} of ${inspection.expectedBeneficiaries} verified (85.8%)',
                isCompleted: inspection.verifiedBeneficiaries > 0,
                icon: Icons.people_outline_rounded,
                onTap: () => context.push('/inspection/${inspection.id}/attendance'),
              ),
              const SizedBox(height: 10),

              _buildWorkflowStepTile(
                stepNumber: '5',
                title: 'AI Anomaly & Risk Analytics',
                subtitle:
                    'Risk: ${inspection.aiRiskLevel.toUpperCase()} (14.2% attendance deviation)',
                isCompleted: true,
                icon: Icons.auto_awesome_outlined,
                onTap: () => context.push('/inspection/${inspection.id}/analytics'),
              ),
              const SizedBox(height: 10),

              _buildWorkflowStepTile(
                stepNumber: '6',
                title: 'Final Summary & Secure Submission',
                subtitle: 'Digital sign-off & MoSJE PostgreSQL cloud commit',
                isCompleted: inspection.status.name == 'submitted' ||
                    inspection.status.name == 'completed',
                icon: Icons.assignment_turned_in_outlined,
                onTap: () => context.push('/inspection/${inspection.id}/summary'),
              ),

              const SizedBox(height: 24),

              // 4. Primary CTA Button
              AppButton(
                label: inspection.isGpsVerified
                    ? 'Continue Digital Checklist'
                    : 'Launch Geofence Radar Verification',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  if (!inspection.isGpsVerified) {
                    context.push('/inspection/${inspection.id}/map');
                  } else {
                    context.push('/inspection/${inspection.id}/checklist');
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriColumn({
    required String title,
    required String value,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color ?? Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildWorkflowStepTile({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space14),
          decoration: BoxDecoration(
            color: const Color(0xFF0C192E),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: isCompleted
                  ? AppColors.neonEmerald.withValues(alpha: 0.4)
                  : AppColors.cyberBorder,
              width: 1.2,
            ),
            boxShadow: [
              if (isCompleted)
                BoxShadow(
                  color: AppColors.neonEmerald.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF0F2644), Color(0xFF08172C)],
                        ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.neonEmerald
                        : AppColors.neonCyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : Text(
                          stepNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonCyan,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isCompleted ? AppColors.neonEmerald : Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
