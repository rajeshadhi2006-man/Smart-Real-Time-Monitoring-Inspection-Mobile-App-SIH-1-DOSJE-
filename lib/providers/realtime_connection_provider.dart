import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

final realtimeConnectionProvider = StreamProvider<RealtimeConnectionStatus>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.statusStream;
});

final realtimeEventProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.eventStream;
});
