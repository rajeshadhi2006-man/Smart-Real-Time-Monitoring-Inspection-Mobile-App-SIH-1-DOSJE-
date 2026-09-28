import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/api_service.dart';
import '../../domain/models/evidence_item.dart';

class EvidenceNotifier extends StateNotifier<List<EvidenceItem>> {
  final ApiService _apiService;

  EvidenceNotifier(this._apiService) : super([]) {
    loadEvidence();
  }

  Future<void> loadEvidence({String? assignmentId}) async {
    try {
      final List<Map<String, dynamic>> rawList;
      if (assignmentId != null && assignmentId.isNotEmpty) {
        rawList = await _apiService.getInspectionEvidence(assignmentId);
      } else {
        rawList = await _apiService.getAllEvidence();
      }
      final items = rawList.map((j) => EvidenceItem.fromJson(j)).toList();
      state = items;
    } catch (_) {}
  }

  Future<void> addSimulatedEvidence({
    required String inspectionId,
    required EvidenceType type,
    required String categoryTag,
    required double lat,
    required double lon,
  }) async {
    try {
      final res = await _apiService.submitInspectionEvidence(
        inspectionId: inspectionId,
        category: categoryTag,
        latitude: lat,
        longitude: lon,
        gpsAccuracy: 5.0,
      );
      if (res != null) {
        state = [EvidenceItem.fromJson(res), ...state];
        return;
      }
    } catch (_) {}

    final item = EvidenceItem(
      id: 'EVD-${DateTime.now().millisecondsSinceEpoch}',
      inspectionId: inspectionId,
      type: type,
      localFilePath: '',
      capturedAt: DateTime.now(),
      latitude: lat,
      longitude: lon,
      sha256Hash: 'VERIFIED_HASH',
      categoryTag: categoryTag,
    );
    state = [item, ...state];
  }

  void addEvidenceItem(EvidenceItem item) {
    state = [item, ...state];
  }


  void removeEvidence(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

final evidenceStateProvider =
    StateNotifierProvider<EvidenceNotifier, List<EvidenceItem>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EvidenceNotifier(apiService);
});

