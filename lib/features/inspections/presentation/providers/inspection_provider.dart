import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../data/repositories/remote_inspection_repository.dart';
import '../../domain/models/inspection_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/realtime_connection_provider.dart';

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RemoteInspectionRepository(apiService: apiService);
});

class InspectionState {
  final bool isLoading;
  final List<InspectionModel> inspections;
  final String? errorMessage;
  final String searchQuery;
  final String selectedFilter; // 'ALL', 'ASSIGNED', 'IN PROGRESS', 'COMPLETED', 'HIGH RISK'

  const InspectionState({
    this.isLoading = false,
    this.inspections = const [],
    this.errorMessage,
    this.searchQuery = '',
    this.selectedFilter = 'ALL',
  });

  List<InspectionModel> get filteredInspections {
    return inspections.where((item) {
      final matchesSearch = searchQuery.isEmpty ||
          item.projectName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.district.toLowerCase().contains(searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      switch (selectedFilter) {
        case 'ASSIGNED':
          return item.status == InspectionStatus.assigned;
        case 'IN PROGRESS':
          return item.status == InspectionStatus.inProgress;
        case 'COMPLETED':
          return item.status == InspectionStatus.completed ||
              item.status == InspectionStatus.submitted;
        case 'HIGH RISK':
          return item.aiRiskLevel.toUpperCase() == 'HIGH';
        default:
          return true;
      }
    }).toList();
  }

  InspectionModel? get todaysInspection {
    try {
      return inspections.firstWhere(
        (i) =>
            i.status == InspectionStatus.assigned ||
            i.status == InspectionStatus.inProgress,
      );
    } catch (_) {
      return inspections.isNotEmpty ? inspections.first : null;
    }
  }

  InspectionState copyWith({
    bool? isLoading,
    List<InspectionModel>? inspections,
    String? errorMessage,
    String? searchQuery,
    String? selectedFilter,
  }) {
    return InspectionState(
      isLoading: isLoading ?? this.isLoading,
      inspections: inspections ?? this.inspections,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class InspectionNotifier extends StateNotifier<InspectionState> {
  final InspectionRepository _repository;

  InspectionNotifier(this._repository) : super(const InspectionState()) {
    fetchInspections();
  }

  void handleRealtimeEvent(Map<String, dynamic> data) {
    final String event = (data['event'] ?? data['type'] ?? '').toString().toUpperCase();
    if (event.contains('INSPECTION')) {
      fetchInspections();
    }
  }

  Future<void> fetchInspections() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getInspections();
      state = state.copyWith(isLoading: false, inspections: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> enrollInspection({
    required String projectName,
    required String organization,
    required String district,
    required double latitude,
    required double longitude,
    String priority = 'MEDIUM',
  }) async {
    final newId = 'INS-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final inspection = InspectionModel(
      id: newId,
      projectId: 'PRJ-${DateTime.now().millisecond}',
      projectName: projectName,
      organization: organization,
      district: district,
      status: InspectionStatus.assigned,
      priority: priority,
      assignmentReason: 'Government Web & Device Enrollment',
      scheduledWindow: 'Today, 09:00 - 17:00 IST',
      deadline: 'Active Audit Window',
      assignedInspector: 'Field Officer',
      isGpsVerified: false,
      verifiedLatitude: latitude,
      verifiedLongitude: longitude,
      checklist: InspectionModel.defaultInspectionChecklist,
    );

    await _repository.enrollInspection(inspection);
    await fetchInspections();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> updateChecklist({
    required String inspectionId,
    required String itemId,
    required ChecklistOption option,
    required String remarks,
  }) async {
    await _repository.updateChecklistAnswer(
      inspectionId: inspectionId,
      itemId: itemId,
      option: option,
      remarks: remarks,
    );
    await fetchInspections();
  }

  Future<void> verifyLocation({
    required String inspectionId,
    required double lat,
    required double lon,
    required double distance,
    required double accuracy,
  }) async {
    await _repository.verifyGpsLocation(
      inspectionId: inspectionId,
      latitude: lat,
      longitude: lon,
      distanceMeters: distance,
      accuracy: accuracy,
    );
    await fetchInspections();
  }

  Future<void> startInspection(String inspectionId) async {
    await _repository.startInspection(inspectionId);
    await fetchInspections();
  }

  Future<void> submitInspection({
    required String inspectionId,
    required String remarks,
  }) async {
    await _repository.submitInspection(
      inspectionId: inspectionId,
      inspectorRemarks: remarks,
    );
    await fetchInspections();
  }
}

final inspectionStateProvider =
    StateNotifierProvider<InspectionNotifier, InspectionState>((ref) {
  final repo = ref.watch(inspectionRepositoryProvider);
  final notifier = InspectionNotifier(repo);

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventProvider, (previous, next) {
    if (next.hasValue && next.value != null) {
      notifier.handleRealtimeEvent(next.value!);
    }
  });

  return notifier;
});
