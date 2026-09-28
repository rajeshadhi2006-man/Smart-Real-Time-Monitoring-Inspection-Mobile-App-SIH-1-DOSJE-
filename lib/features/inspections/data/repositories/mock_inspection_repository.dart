import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../domain/models/inspection_model.dart';
import 'inspection_repository.dart';

/// Production dynamic inspection repository backed by Supabase PostgreSQL.
/// Zero hardcoded or predefined inspections: purely fetches real-time enrollments
/// and subscribes to Supabase Realtime channel for live updates.
class MockInspectionRepository implements InspectionRepository {
  final List<InspectionModel> _inspections = [];
  RealtimeChannel? _realtimeSubscription;
  void Function()? onRemoteDataChanged;

  MockInspectionRepository() {
    _initRealtimeSubscription();
  }

  void dispose() {
    _realtimeSubscription?.unsubscribe();
  }

  void _initRealtimeSubscription() {
    try {
      _realtimeSubscription = SupabaseService.client
          .channel('public:inspections')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'inspections',
            callback: (payload) {
              developer.log('Realtime inspection update received from Supabase: ${payload.eventType}');
              getInspections().then((_) {
                onRemoteDataChanged?.call();
              });
            },
          )
          .subscribe();
    } catch (e) {
      developer.log('Supabase Realtime subscription for inspections skipped or unavailable: $e');
    }
  }

  @override
  Future<List<InspectionModel>> getInspections() async {
    try {
      final data = await SupabaseService.client
          .from('inspections')
          .select('*')
          .order('created_at', ascending: false);

      _inspections.clear();
      for (final row in data) {
        _inspections.add(InspectionModel.fromMap(row));
      }
    } catch (e) {
      developer.log('Supabase inspections fetch error: $e');
    }
    return List.unmodifiable(_inspections);
  }

  @override
  Future<InspectionModel?> getInspectionById(String id) async {
    try {
      final match = _inspections.where((e) => e.id == id);
      if (match.isNotEmpty) return match.first;

      final data = await SupabaseService.client
          .from('inspections')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (data != null) {
        final loaded = InspectionModel.fromMap(data);
        _inspections.add(loaded);
        return loaded;
      }
    } catch (e) {
      developer.log('Failed to fetch inspection by id $id: $e');
    }
    return null;
  }

  @override
  Future<void> enrollInspection(InspectionModel inspection) async {
    final existingIndex = _inspections.indexWhere((e) => e.id == inspection.id);
    if (existingIndex != -1) {
      _inspections[existingIndex] = inspection;
    } else {
      _inspections.insert(0, inspection);
    }

    try {
      await SupabaseService.client.from('inspections').upsert(inspection.toMap());
      developer.log('Successfully enrolled inspection ${inspection.id} to Supabase');
    } catch (e) {
      developer.log('Offline or error enrolling inspection ${inspection.id} to Supabase: $e');
    }
  }

  @override
  Future<void> updateChecklistAnswer({
    required String inspectionId,
    required String itemId,
    required ChecklistOption option,
    required String remarks,
  }) async {
    final index = _inspections.indexWhere((e) => e.id == inspectionId);
    if (index == -1) return;

    final current = _inspections[index];
    final updatedChecklist = current.checklist.map((item) {
      if (item.id == itemId) {
        return item.copyWith(selectedOption: option, remarks: remarks);
      }
      return item;
    }).toList();

    _inspections[index] = current.copyWith(checklist: updatedChecklist);
  }

  @override
  Future<void> verifyGpsLocation({
    required String inspectionId,
    required double latitude,
    required double longitude,
    required double distanceMeters,
    required double accuracy,
  }) async {
    final index = _inspections.indexWhere((e) => e.id == inspectionId);
    if (index != -1) {
      _inspections[index] = _inspections[index].copyWith(
        isGpsVerified: true,
        distanceMeters: distanceMeters,
        verifiedLatitude: latitude,
        verifiedLongitude: longitude,
        gpsAccuracy: accuracy,
      );
    }

    try {
      await SupabaseService.client.from('inspections').update({
        'is_gps_verified': true,
        'verified_latitude': latitude,
        'verified_longitude': longitude,
        'distance_meters': distanceMeters,
        'gps_accuracy': accuracy,
      }).eq('id', inspectionId);
    } catch (e) {
      developer.log('Failed to update GPS verification in Supabase: $e');
    }
  }

  @override
  Future<void> startInspection(String inspectionId) async {
    final index = _inspections.indexWhere((e) => e.id == inspectionId);
    if (index != -1) {
      _inspections[index] = _inspections[index].copyWith(
        status: InspectionStatus.inProgress,
        startedAt: DateTime.now(),
      );
    }

    try {
      await SupabaseService.client.from('inspections').update({
        'status': InspectionStatus.inProgress.name,
      }).eq('id', inspectionId);
    } catch (_) {}
  }

  @override
  Future<void> submitInspection({
    required String inspectionId,
    required String inspectorRemarks,
  }) async {
    final index = _inspections.indexWhere((e) => e.id == inspectionId);
    if (index != -1) {
      _inspections[index] = _inspections[index].copyWith(
        status: InspectionStatus.submitted,
        submittedAt: DateTime.now(),
        inspectorRemarks: inspectorRemarks,
        isSynced: true,
      );
    }

    try {
      await SupabaseService.client.from('inspections').update({
        'status': InspectionStatus.submitted.name,
        'inspector_remarks': inspectorRemarks,
      }).eq('id', inspectionId);
    } catch (_) {}
  }

  @override
  Future<void> syncOfflineInspections() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
