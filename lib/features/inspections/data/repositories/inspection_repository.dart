import '../../domain/models/inspection_model.dart';

abstract class InspectionRepository {
  Future<List<InspectionModel>> getInspections();
  Future<InspectionModel?> getInspectionById(String id);
  Future<void> updateChecklistAnswer({
    required String inspectionId,
    required String itemId,
    required ChecklistOption option,
    required String remarks,
  });
  Future<void> verifyGpsLocation({
    required String inspectionId,
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required double accuracy,
  });
  Future<void> startInspection(String inspectionId);
  Future<void> submitInspection({
    required String inspectionId,
    required String inspectorRemarks,
  });
  Future<void> enrollInspection(InspectionModel inspection);
  Future<void> syncOfflineInspections();
}
