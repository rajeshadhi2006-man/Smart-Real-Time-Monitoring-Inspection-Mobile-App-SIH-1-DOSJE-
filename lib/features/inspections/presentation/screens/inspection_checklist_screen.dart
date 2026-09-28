import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/inspection_model.dart';
import '../providers/inspection_provider.dart';

class InspectionChecklistScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const InspectionChecklistScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  ConsumerState<InspectionChecklistScreen> createState() =>
      _InspectionChecklistScreenState();
}

class _InspectionChecklistScreenState
    extends ConsumerState<InspectionChecklistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Digital Checklist Audit'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonCyan,
          indicatorWeight: 3,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Infrastructure'),
            Tab(text: 'Services'),
            Tab(text: 'Beneficiary'),
            Tab(text: 'Records'),
          ],
        ),
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: Column(
          children: [
            // Progress tracker bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C192E).withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
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
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonCyan,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AUDIT PROGRESS (${inspection.completedChecklistCount}/${inspection.totalChecklistCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(inspection.checklistProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: inspection.checklistProgress,
                      backgroundColor: const Color(0xFF162A45),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonCyan,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Checklist Tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(
                    inspection,
                    ChecklistCategory.infrastructure,
                  ),
                  _buildCategoryList(
                    inspection,
                    ChecklistCategory.services,
                  ),
                  _buildCategoryList(
                    inspection,
                    ChecklistCategory.beneficiaries,
                  ),
                  _buildCategoryList(
                    inspection,
                    ChecklistCategory.documentation,
                  ),
                ],
              ),
            ),

            // Bottom Action Bar
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
                label: 'Proceed to Evidence Capture',
                icon: Icons.camera_alt_outlined,
                onPressed: () {
                  context.push('/inspection/${widget.inspectionId}/evidence');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    InspectionModel inspection,
    ChecklistCategory category,
  ) {
    final items =
        inspection.checklist.where((c) => c.category == category).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isAnswered = item.selectedOption != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: const Color(0xFF0C192E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: isAnswered
                  ? AppColors.neonCyan.withValues(alpha: 0.45)
                  : AppColors.cyberBorder.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isAnswered
                    ? AppColors.neonCyan.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? AppColors.neonCyan.withValues(alpha: 0.2)
                          : const Color(0xFF162A45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAnswered ? AppColors.neonCyan : Colors.white24,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isAnswered ? AppColors.neonCyan : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Option Selector (Pass, Fail, N/A)
              Row(
                children: [
                  Expanded(
                    child: _buildOptionChip(
                      label: 'PASS',
                      icon: Icons.check_circle_rounded,
                      isSelected: item.selectedOption == ChecklistOption.pass,
                      color: AppColors.neonEmerald,
                      onTap: () {
                        ref
                            .read(inspectionStateProvider.notifier)
                            .updateChecklist(
                              inspectionId: widget.inspectionId,
                              itemId: item.id,
                              option: ChecklistOption.pass,
                              remarks: item.remarks,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOptionChip(
                      label: 'FAIL',
                      icon: Icons.cancel_rounded,
                      isSelected: item.selectedOption == ChecklistOption.fail,
                      color: AppColors.dangerRed,
                      onTap: () {
                        ref
                            .read(inspectionStateProvider.notifier)
                            .updateChecklist(
                              inspectionId: widget.inspectionId,
                              itemId: item.id,
                              option: ChecklistOption.fail,
                              remarks: item.remarks,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildOptionChip(
                      label: 'N/A',
                      icon: Icons.remove_circle_outline_rounded,
                      isSelected:
                          item.selectedOption == ChecklistOption.notApplicable,
                      color: const Color(0xFF94A3B8),
                      onTap: () {
                        ref
                            .read(inspectionStateProvider.notifier)
                            .updateChecklist(
                              inspectionId: widget.inspectionId,
                              itemId: item.id,
                              option: ChecklistOption.notApplicable,
                              remarks: item.remarks,
                            );
                      },
                    ),
                  ),
                ],
              ),

              // Remarks TextField
              const SizedBox(height: 12),
              TextFormField(
                initialValue: item.remarks,
                decoration: InputDecoration(
                  hintText: 'Add inspector observation note...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF071224),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    borderSide: BorderSide(
                      color: AppColors.cyberBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    borderSide: const BorderSide(
                      color: AppColors.neonCyan,
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 12, color: Colors.white),
                onChanged: (text) {
                  if (item.selectedOption != null) {
                    ref.read(inspectionStateProvider.notifier).updateChecklist(
                          inspectionId: widget.inspectionId,
                          itemId: item.id,
                          option: item.selectedOption!,
                          remarks: text,
                        );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF081528),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.cyberBorder.withValues(alpha: 0.4),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : Colors.white60,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : Colors.white60,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
