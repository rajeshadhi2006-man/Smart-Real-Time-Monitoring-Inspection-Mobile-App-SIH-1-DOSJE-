import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import 'realtime_connection_provider.dart';

final alertsProvider = StateNotifierProvider<AlertsNotifier, AsyncValue<List<AlertModel>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = AlertsNotifier(apiService);

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventProvider, (previous, next) {
    next.whenData((event) {
      final type = (event['type'] ?? event['event'] ?? '').toString();
      if (type.contains('ALERT') || type.contains('alert') || type.contains('VIOLATION') || type.contains('MISMATCH') || type == 'GEOFENCE_EVENT') {
        final data = event['data'] is Map<String, dynamic> ? event['data'] as Map<String, dynamic> : event;
        try {
          final alert = AlertModel.fromJson(data);
          notifier.addRealtimeAlert(alert);
        } catch (_) {}
      }
    });
  });

  return notifier;
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<AlertModel>>> {
  final ApiService _apiService;

  AlertsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _apiService.getAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addRealtimeAlert(AlertModel newAlert) {
    state.whenData((alerts) {
      final filtered = alerts.where((a) => a.id != newAlert.id).toList();
      state = AsyncValue.data([newAlert, ...filtered]);
    });
  }

  void updateAlertStatus(String alertId, String newStatus) {
    state.whenData((alerts) {
      final updated = alerts.map((a) {
        if (a.id == alertId) return a.copyWith(status: newStatus);
        return a;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }
}

