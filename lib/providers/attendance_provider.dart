import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import 'realtime_connection_provider.dart';

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AsyncValue<List<AttendanceRecord>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = AttendanceNotifier(apiService);

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventProvider, (previous, next) {
    next.whenData((event) {
      final type = (event['type'] ?? event['event'] ?? '').toString();
      if (type == 'ATTENDANCE_VERIFIED' || type == 'ATTENDANCE_ENTRY' || type == 'attendance') {
        final data = event['data'] is Map<String, dynamic> ? event['data'] as Map<String, dynamic> : event;
        try {
          final record = AttendanceRecord.fromJson(data);
          notifier.addRecord(record);
        } catch (_) {}
      }
    });
  });

  return notifier;
});

class AttendanceNotifier extends StateNotifier<AsyncValue<List<AttendanceRecord>>> {
  final ApiService _apiService;

  AttendanceNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadAttendance();
  }

  Future<void> loadAttendance({String? dateFilter, String? personId}) async {
    state = const AsyncValue.loading();
    try {
      final records = (dateFilter == null && personId == null)
          ? await _apiService.getLiveAttendance()
          : await _apiService.getAttendance(dateFilter: dateFilter, personId: personId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addRecord(AttendanceRecord record) {
    state.whenData((records) {
      // Avoid duplicate entry if id already exists
      final filtered = records.where((r) => r.id != record.id).toList();
      state = AsyncValue.data([record, ...filtered]);
    });
  }
}

