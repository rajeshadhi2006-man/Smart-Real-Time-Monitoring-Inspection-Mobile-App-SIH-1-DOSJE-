import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_session.dart';
import '../services/webrtc_service.dart';

final webRtcServiceProvider = Provider<WebRtcService>((ref) {
  final service = WebRtcService();
  ref.onDispose(() => service.dispose());
  return service;
});

final callSessionProvider = StreamProvider<CallSession>((ref) {
  final service = ref.watch(webRtcServiceProvider);
  return service.callSessionStream;
});
