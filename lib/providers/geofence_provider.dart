import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/geofence.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';
import 'realtime_connection_provider.dart';

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GeofenceService(apiService: apiService);
});

final selectedGeofenceIdProvider = StateProvider<String?>((ref) => null);

final geofenceProvider = StateNotifierProvider<GeofenceNotifier, AsyncValue<List<Geofence>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = GeofenceNotifier(apiService);

  ref.listen<AsyncValue<Map<String, dynamic>>>(realtimeEventProvider, (previous, next) {
    if (next.hasValue && next.value != null) {
      notifier.handleRealtimeEvent(next.value!);
    }
  });

  return notifier;
});

class GeofenceNotifier extends StateNotifier<AsyncValue<List<Geofence>>> {
  final ApiService _apiService;

  GeofenceNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadGeofences();
  }

  Future<void> loadGeofences() async {
    state = const AsyncValue.loading();
    try {
      final geofences = await _apiService.getGeofences();
      state = AsyncValue.data(geofences);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void handleRealtimeEvent(Map<String, dynamic> data) {
    final String event = (data['event'] ?? data['type'] ?? '').toString().toUpperCase();
    final payload = data['payload'] ?? data['geofence'] ?? data['data'] ?? data;

    if (event == 'GEOFENCE_CREATED' || event == 'GEOFENCE_ADD') {
      try {
        final Map<String, dynamic> rawObj = payload is Map<String, dynamic> ? payload : data;
        final newGeofence = Geofence.fromJson(rawObj);
        state.whenData((currentList) {
          final updatedList = List<Geofence>.from(currentList);
          final index = updatedList.indexWhere((g) => g.id == newGeofence.id);
          if (index != -1) {
            updatedList[index] = newGeofence;
          } else {
            updatedList.insert(0, newGeofence);
          }
          state = AsyncValue.data(updatedList);
        });
      } catch (_) {}
    } else if (event == 'GEOFENCE_UPDATED' || event == 'GEOFENCE_UPDATE') {
      try {
        final Map<String, dynamic> rawObj = payload is Map<String, dynamic> ? payload : data;
        final updatedGeofence = Geofence.fromJson(rawObj);
        state.whenData((currentList) {
          final updatedList = currentList.map((g) => g.id == updatedGeofence.id ? updatedGeofence : g).toList();
          state = AsyncValue.data(updatedList);
        });
      } catch (_) {}
    } else if (event == 'GEOFENCE_DELETED' || event == 'GEOFENCE_DELETE') {
      final String deletedId = (payload is Map && payload['id'] != null)
          ? payload['id'].toString()
          : (data['id'] ?? data['geofence_id'] ?? '').toString();
      if (deletedId.isNotEmpty) {
        state.whenData((currentList) {
          final updatedList = currentList.where((g) => g.id != deletedId).toList();
          state = AsyncValue.data(updatedList);
        });
      }
    }
  }
}

/// Computes real-time live evaluation between Current Device GPS and a target geofence
final liveGeofenceEvaluationProvider = Provider.family<GeofenceEvaluation?, Geofence>((ref, geofence) {
  final locationState = ref.watch(locationTrackingProvider);
  final geofenceService = ref.watch(geofenceServiceProvider);

  final userLoc = locationState.currentLocation;
  if (userLoc == null) return null;

  return geofenceService.evaluate(userLoc, targetGeofence: geofence);
});
