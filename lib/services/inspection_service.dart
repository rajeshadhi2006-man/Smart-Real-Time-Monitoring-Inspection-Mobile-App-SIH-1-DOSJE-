import 'api_service.dart';
import '../core/config/api_config.dart';
import '../models/assignment_model.dart';
import '../models/inspection_model.dart';

class InspectionService {
  final ApiService _apiService = ApiService();
  static List<AssignmentModel> _cachedAssignments = [];
  static List<InspectionModel> _cachedInspections = [];

  Future<List<AssignmentModel>> getMyAssignments({String? userId}) async {
    try {
      final url = (userId != null && userId.isNotEmpty)
          ? ApiConfig.userAssignmentsUrl(userId)
          : ApiConfig.assignmentsUrl;
      final response = await _apiService.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List).map((x) => AssignmentModel.fromJson(x)).toList();
        _cachedAssignments = list;
        return list;
      }
    } catch (_) {}

    return _cachedAssignments;
  }

  Future<List<InspectionModel>> getMyInspections() async {
    try {
      final response = await _apiService.get(ApiConfig.inspectionsUrl).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List).map((x) => InspectionModel.fromJson(x)).toList();
        _cachedInspections = list;
        return list;
      }
    } catch (_) {}

    return _cachedInspections;
  }

  Future<bool> submitInspectionReport({
    required String inspectionId,
    required String inspectorId,
    required String inspectorName,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String geofenceStatus,
    required String observations,
    required String complianceFindings,
    required String violations,
    required String beneficiarySummary,
    required String staffSummary,
    required String remarks,
  }) async {
    try {
      final response = await _apiService.post(
        "${ApiConfig.inspectionsUrl}/$inspectionId/report",
        data: {
          'inspector_id': inspectorId,
          'inspector_name': inspectorName,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'geofence_status': geofenceStatus,
          'observations': observations,
          'compliance_findings': complianceFindings,
          'violations': violations,
          'beneficiary_verification_summary': beneficiarySummary,
          'staff_verification_summary': staffSummary,
          'remarks': remarks,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
