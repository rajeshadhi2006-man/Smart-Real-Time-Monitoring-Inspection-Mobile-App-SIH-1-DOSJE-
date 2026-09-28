import 'dart:convert';
import 'dart:developer' as developer;
import '../../../../services/api_service.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/models/inspection_model.dart';
import 'inspection_repository.dart';

/// Real Remote Repository for DoSJE Government Inspections.
/// Communicates directly with FastAPI Backend (/api/inspections) and Supabase Database.
class RemoteInspectionRepository implements InspectionRepository {
  final ApiService _apiService;

  // In-memory cache for active checklist edits during inspection
  final Map<String, List<ChecklistItemModel>> _activeChecklists = {};
  final Map<String, Map<String, dynamic>> _activeGpsData = {};

  RemoteInspectionRepository({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  @override
  Future<List<InspectionModel>> getInspections() async {
    final Map<String, InspectionModel> inspectionMap = {};

    try {
      final rawList = await _apiService.getInspections();
      for (final item in rawList) {
        final model = InspectionModel.fromMap(item);
        inspectionMap[model.id] = _activeChecklists.containsKey(model.id)
            ? model.copyWith(checklist: _activeChecklists[model.id])
            : model;
      }
    } catch (e) {
      developer.log('RemoteInspectionRepository getInspections API error: $e');
    }

    // Fetch and merge field assignments from FastAPI
    try {
      final assignments = await _apiService.getAssignments();
      for (final asgn in assignments) {
        final model = InspectionModel.fromMap(asgn);
        if (!inspectionMap.containsKey(model.id)) {
          inspectionMap[model.id] = model;
        }
      }
    } catch (e) {
      developer.log('RemoteInspectionRepository getAssignments error: $e');
    }

    if (inspectionMap.isNotEmpty) {
      return inspectionMap.values.toList();
    }

    // Direct Supabase Fallback
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('inspections')
          .select('*')
          .order('created_at', ascending: false);
      if (response.isNotEmpty) {
        return response.map((item) {
          final map = Map<String, dynamic>.from(item);
          final model = InspectionModel.fromMap(map);
          if (_activeChecklists.containsKey(model.id)) {
            return model.copyWith(checklist: _activeChecklists[model.id]);
          }
          return model;
        }).toList();
      }
    } catch (e) {
      developer.log('RemoteInspectionRepository getInspections Supabase error: $e');
    }

    return [];
  }

  @override
  Future<InspectionModel?> getInspectionById(String id) async {
    final list = await getInspections();
    try {
      return list.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateChecklistAnswer({
    required String inspectionId,
    required String itemId,
    required ChecklistOption option,
    required String remarks,
  }) async {
    final inspection = await getInspectionById(inspectionId);
    final checklist = List<ChecklistItemModel>.from(
      _activeChecklists[inspectionId] ??
          inspection?.checklist ??
          InspectionModel.defaultInspectionChecklist,
    );

    final index = checklist.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      checklist[index] = checklist[index].copyWith(
        selectedOption: option,
        remarks: remarks,
      );
      _activeChecklists[inspectionId] = checklist;
    }
  }

  @override
  Future<void> verifyGpsLocation({
    required String inspectionId,
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required double accuracy,
  }) async {
    _activeGpsData[inspectionId] = {
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': distanceMeters,
      'accuracy': accuracy,
      'verified': true,
    };
  }

  @override
  Future<void> startInspection(String inspectionId) async {
    final gps = _activeGpsData[inspectionId];
    final lat = gps?['latitude'] as double? ?? 0.0;
    final lng = gps?['longitude'] as double? ?? 0.0;
    final acc = gps?['accuracy'] as double? ?? 5.0;

    await _apiService.startInspection(
      inspectionId,
      lat: lat,
      lng: lng,
      accuracy: acc,
    );
  }

  @override
  Future<void> submitInspection({
    required String inspectionId,
    required String inspectorRemarks,
  }) async {
    final inspection = await getInspectionById(inspectionId);
    final gps = _activeGpsData[inspectionId];
    final checklist = _activeChecklists[inspectionId] ??
        inspection?.checklist ??
        InspectionModel.defaultInspectionChecklist;

    int passedCount = 0;
    int failedCount = 0;
    final List<Map<String, dynamic>> findings = [];

    for (final item in checklist) {
      if (item.selectedOption == ChecklistOption.pass) {
        passedCount++;
      } else if (item.selectedOption == ChecklistOption.fail) {
        failedCount++;
        findings.add({
          'question': item.question,
          'category': item.category.label,
          'remarks': item.remarks,
        });
      }
    }

    final reportPayload = {
      'inspector_id': inspection?.assignedInspector ?? 'OFF-INSP-01',
      'inspector_name': inspection?.assignedInspector ?? 'Field Officer',
      'latitude': gps?['latitude'] ?? inspection?.verifiedLatitude ?? 0.0,
      'longitude': gps?['longitude'] ?? inspection?.verifiedLongitude ?? 0.0,
      'accuracy': gps?['accuracy'] ?? inspection?.gpsAccuracy ?? 5.0,
      'geofence_status': (gps?['distanceMeters'] as num? ?? 0.0) <= 100.0 ? 'INSIDE' : 'OUTSIDE',
      'observations': inspectorRemarks.isNotEmpty
          ? inspectorRemarks
          : 'Inspection conducted per DoSJE guidelines. Checklist passed: $passedCount, failed: $failedCount.',
      'compliance_findings': jsonEncode(findings),
      'violations': failedCount > 0 ? '$failedCount checklist non-compliances noted' : 'None',
      'beneficiary_verification_summary': 'Verified: ${inspection?.verifiedBeneficiaries ?? 0} of ${inspection?.expectedBeneficiaries ?? 0}',
      'staff_verification_summary': 'Institutional staff present and documented',
      'remarks': inspectorRemarks,
    };

    final success = await _apiService.submitReport(inspectionId, reportPayload);
    if (!success) {
      throw Exception('Failed to submit inspection report to server');
    }

    _activeChecklists.remove(inspectionId);
    _activeGpsData.remove(inspectionId);
  }

  @override
  Future<void> enrollInspection(InspectionModel inspection) async {
    // 1. Create on central FastAPI backend so it broadcasts to User App
    try {
      final lat = inspection.verifiedLatitude ?? 12.9716;
      final lng = inspection.verifiedLongitude ?? 77.5946;
      await _apiService.createAssignment(
        assignedUserId: inspection.assignedInspector.isNotEmpty && inspection.assignedInspector != 'Field Inspector'
            ? inspection.assignedInspector
            : 'officer@surveillance.gov.in',
        title: inspection.projectName,
        assignedLocation: '${inspection.district} Operational Zone',
        targetLatitude: lat,
        targetLongitude: lng,
        description: inspection.assignmentReason.isNotEmpty
            ? inspection.assignmentReason
            : 'Physical on-site audit enrolled from Government Command App',
        allowedRadiusMeters: 200.0,
      );
    } catch (e) {
      developer.log('RemoteInspectionRepository createAssignment error: $e');
    }

    // 2. Also register in Supabase inspections table
    try {
      final client = SupabaseService.client;
      await client.from('inspections').insert({
        'id': inspection.id,
        'inspection_code': 'INSP-${DateTime.now().millisecondsSinceEpoch}',
        'project_id': inspection.projectId,
        'project_name': inspection.projectName,
        'ngo_institute': inspection.organization,
        'inspection_type': 'SURPRISE',
        'reason': inspection.assignmentReason,
        'priority': inspection.priority,
        'status': 'ASSIGNED',
        'inspector_name': inspection.assignedInspector,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('RemoteInspectionRepository enrollInspection Supabase error: $e');
    }
  }

  @override
  Future<void> syncOfflineInspections() async {
    await getInspections();
  }
}
