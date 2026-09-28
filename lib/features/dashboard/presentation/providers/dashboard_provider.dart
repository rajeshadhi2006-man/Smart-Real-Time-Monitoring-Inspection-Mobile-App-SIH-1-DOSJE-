import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inspections/domain/models/inspection_model.dart';
import '../../../inspections/presentation/providers/inspection_provider.dart';

class DashboardMetrics {
  final int assignedCount;
  final int pendingCount;
  final int completedCount;
  final int alertsCount;

  const DashboardMetrics({
    required this.assignedCount,
    required this.pendingCount,
    required this.completedCount,
    required this.alertsCount,
  });
}

final dashboardMetricsProvider = Provider<DashboardMetrics>((ref) {
  final state = ref.watch(inspectionStateProvider);
  final all = state.inspections;

  final assigned = all.where((i) => i.status == InspectionStatus.assigned).length;
  final pending = all.where((i) => i.status == InspectionStatus.inProgress || i.status == InspectionStatus.accepted).length;
  final completed = all.where((i) => i.status == InspectionStatus.completed || i.status == InspectionStatus.submitted).length;
  final alerts = all.where((i) => i.aiRiskLevel.toUpperCase() == 'HIGH' || i.aiRiskReasons.isNotEmpty).length;

  return DashboardMetrics(
    assignedCount: assigned,
    pendingCount: pending,
    completedCount: completed,
    alertsCount: alerts,
  );
});
