import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/inspection_model.dart';
import '../providers/inspection_provider.dart';
import '../widgets/enroll_inspection_dialog.dart';

class InspectionsListScreen extends ConsumerWidget {
  const InspectionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionStateProvider);
    final notifier = ref.read(inspectionStateProvider.notifier);
    final items = state.filteredInspections;

    final filterOptions = [
      'ALL',
      'ASSIGNED',
      'IN PROGRESS',
      'COMPLETED',
      'HIGH RISK',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Field Inspections',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Official Monitoring Assignments',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Enroll Audit Site',
            onPressed: () => showEnrollInspectionDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.fetchInspections(),
          ),
        ],
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: Column(
          children: [
            // Search & Filter Header Card (Cyber Glass Header)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF081426),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0D1E36),
                      hintText: 'Search by project, ID, or district...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.neonCyan),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
                      ),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.white70),
                              onPressed: () => notifier.setSearchQuery(''),
                            )
                          : null,
                    ),
                    onChanged: (val) => notifier.setSearchQuery(val),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((filter) {
                        final isSelected = state.selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => notifier.setFilter(filter),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppColors.cyberCyanGradient
                                    : null,
                                color: isSelected ? null : const Color(0xFF0D1E36),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.neonCyan
                                      : Colors.white.withValues(alpha: 0.12),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.neonCyan.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF04101F) : Colors.white70,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Inspection List
            Expanded(
              child: state.inspections.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D213F),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.cloud_sync_rounded,
                                size: 40,
                                color: Color(0xFF00F0FF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Awaiting Field Site Enrollment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Predefined mock inspections have been removed.\nField sites enrolled via the Government Web Portal will appear here dynamically in real time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => showEnrollInspectionDialog(context, ref),
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text(
                                'Enroll Field Inspection Site',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : items.isEmpty
                      ? const EmptyState(
                          title: 'No Inspections Found',
                          message:
                              'No assignments match your active search and filter criteria.',
                          icon: Icons.assignment_late_outlined,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildInspectionCard(context, item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionCard(BuildContext context, InspectionModel item) {
    final progressPercent = (item.checklistProgress * 100).toInt();
    final statusCol = AppColors.statusColor(item.status.label);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C192E),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: statusCol.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusCol.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            onTap: () {
              context.push('/inspection/${item.id}');
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Colorful Semantic Status Accent Bar
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusCol,
                          statusCol.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),

                  // Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: ID, Priority, and Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10243E),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.neonCyan.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      item.id,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.neonCyan,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  RiskBadge(riskLevel: item.aiRiskLevel),
                                ],
                              ),
                              StatusBadge(status: item.status.label),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Project Title
                          Text(
                            item.projectName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.organization} • ${item.district}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Progress Bar with label
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Inspection Progress',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$progressPercent%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: item.checklistProgress == 1.0
                                          ? AppColors.neonEmerald
                                          : AppColors.neonCyan,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                value: item.checklistProgress,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  item.checklistProgress == 1.0
                                      ? AppColors.neonEmerald
                                      : AppColors.neonCyan,
                                ),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),

                          Divider(height: 20, color: Colors.white.withValues(alpha: 0.08)),

                          // Footer with Date, Distance, and Action link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.scheduledWindow,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    item.isGpsVerified ? Icons.location_on : Icons.near_me_outlined,
                                    size: 14,
                                    color: item.isGpsVerified
                                        ? AppColors.neonEmerald
                                        : AppColors.neonAmber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.distanceMeters != null
                                        ? '${item.distanceMeters!.toStringAsFixed(0)} m'
                                        : 'Pending GPS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: item.isGpsVerified
                                          ? AppColors.neonEmerald
                                          : AppColors.neonAmber,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.cyberCyanGradient,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text(
                                          'Dossier',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF04101F),
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 10,
                                          color: Color(0xFF04101F),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
