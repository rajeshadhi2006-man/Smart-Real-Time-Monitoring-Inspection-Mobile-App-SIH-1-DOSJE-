import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../inspections/domain/models/inspection_model.dart';
import '../../../inspections/presentation/providers/inspection_provider.dart';
import '../../domain/models/project_model.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionState = ref.watch(inspectionStateProvider);
    final inspection = inspectionState.inspections.cast<InspectionModel?>().firstWhere(
          (i) => i?.projectId == projectId || i?.id == projectId,
          orElse: () => inspectionState.todaysInspection ?? inspectionState.inspections.firstOrNull,
        );
    final project = inspection != null
        ? ProjectModel.fromInspection(inspection)
        : ProjectModel.demo(id: projectId);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Project Dossier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Header Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.roundedMedium,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.id,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      RiskBadge(riskLevel: project.riskLevel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.organization,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniKpi('Beneficiaries', '${project.registeredBeneficiaries}'),
                      _buildMiniKpi('Compliance', '${project.complianceScore}%'),
                      _buildMiniKpi('Last Inspected', project.lastInspectionDate),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Expandable Info Cards
            _buildExpandableTile(
              title: 'Location & Anchor Coordinates',
              icon: Icons.location_on_outlined,
              initiallyExpanded: true,
              children: [
                _buildRow('District', project.district),
                _buildRow('State', project.state),
                _buildRow('Full Address', project.address),
                _buildRow(
                  'Geo Coordinates',
                  '${project.registeredLatitude.toStringAsFixed(6)}, ${project.registeredLongitude.toStringAsFixed(6)}',
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildExpandableTile(
              title: 'Administration & Nodal Contact',
              icon: Icons.person_outline_rounded,
              children: [
                _buildRow('Authorized Head', project.contactPerson),
                _buildRow('Official Phone', project.contactPhone),
                _buildRow('Grant Scheme', 'MoSJE De-addiction & Divyang Rehabilitation'),
              ],
            ),

            const SizedBox(height: 12),

            _buildExpandableTile(
              title: 'Surveillance & CCTV Stream',
              icon: Icons.videocam_outlined,
              children: [
                _buildRow(
                  'CCTV Available',
                  project.cctvAvailable ? 'YES (Operational)' : 'NO',
                  color: project.cctvAvailable ? AppColors.successGreen : AppColors.dangerRed,
                ),
                _buildRow('Active IP Cameras', '${project.activeCamerasCount} Feeds Online'),
                _buildRow('Stream Latency', '1.2s to Central MoSJE Command Dashboard'),
              ],
            ),

            const SizedBox(height: 24),

            AppButton(
              label: 'Proceed to GPS Location Verification',
              icon: Icons.navigation_rounded,
              onPressed: () {
                context.push('/inspection/${project.id}/map');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKpi(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableTile({
    required String title,
    required IconData icon,
    bool initiallyExpanded = false,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.roundedMedium,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: AppColors.primaryNavy, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
