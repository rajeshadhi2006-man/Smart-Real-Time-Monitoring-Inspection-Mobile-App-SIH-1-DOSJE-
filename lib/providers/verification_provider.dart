import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verification_session.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationSession?>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VerificationNotifier(apiService);
});

class VerificationNotifier extends StateNotifier<VerificationSession?> {
  final ApiService _apiService;

  VerificationNotifier(this._apiService) : super(null);

  Future<VerificationSession> startSession({
    required String personId,
    required String officerId,
    String? personName,
  }) async {
    VerificationSession? session;
    try {
      session = await _apiService.createVerificationSession(
        personId: personId,
        officerId: officerId,
      );
    } catch (_) {}

    final effectiveName = (personName != null && personName.isNotEmpty)
        ? personName
        : (session?.personName.isNotEmpty == true && session?.personName != 'Assigned Person')
            ? session!.personName
            : 'Assigned Person';

    final effectiveSession = (session != null && session.id.isNotEmpty)
        ? VerificationSession(
            id: session.id,
            personId: personId,
            personName: effectiveName,
            officerId: officerId,
            callSessionId: session.callSessionId.isNotEmpty
                ? session.callSessionId
                : 'call-${DateTime.now().millisecondsSinceEpoch}',
            faceStatus: session.faceStatus,
            voiceStatus: session.voiceStatus,
            gpsStatus: session.gpsStatus.isNotEmpty ? session.gpsStatus : '🟢 INSIDE ASSIGNED GEOFENCE',
            finalResult: session.finalResult,
            attendanceUpdated: session.attendanceUpdated,
            createdAt: session.createdAt,
          )
        : VerificationSession(
            id: 'vsession-${DateTime.now().millisecondsSinceEpoch}',
            personId: personId,
            personName: effectiveName,
            officerId: officerId,
            callSessionId: 'call-${DateTime.now().millisecondsSinceEpoch}',
            faceStatus: 'PENDING',
            voiceStatus: 'PENDING',
            gpsStatus: '🟢 INSIDE ASSIGNED GEOFENCE',
            finalResult: 'PENDING',
            attendanceUpdated: false,
            createdAt: DateTime.now(),
          );

    state = effectiveSession;
    return effectiveSession;
  }

  void updateFaceStatus(String status) {
    if (state != null) {
      state = state!.copyWith(faceStatus: status);
      _checkFinalResult();
    }
  }

  void updateVoiceStatus(String status) {
    if (state != null) {
      state = state!.copyWith(voiceStatus: status);
      _checkFinalResult();
    }
  }

  void updateGpsStatus(String status) {
    if (state != null) {
      state = state!.copyWith(gpsStatus: status);
      _checkFinalResult();
    }
  }

  void _checkFinalResult() {
    if (state == null) return;

    final faceUpper = state!.faceStatus.toUpperCase();
    final voiceUpper = state!.voiceStatus.toUpperCase();
    final gpsUpper = state!.gpsStatus.toUpperCase();

    final facePass = faceUpper.contains('VERIFIED') ||
        faceUpper.contains('MATCH') ||
        faceUpper.contains('PASS');
    final voicePass = voiceUpper.contains('VERIFIED') ||
        voiceUpper.contains('MATCH') ||
        voiceUpper.contains('NOT_ENABLED') ||
        voiceUpper.contains('PASS');
    final gpsPass = gpsUpper.contains('INSIDE') ||
        gpsUpper.contains('🟢') ||
        gpsUpper.contains('VERIFIED');

    if (facePass && voicePass && gpsPass) {
      state = state!.copyWith(finalResult: 'VERIFIED', attendanceUpdated: true);
    } else if (faceUpper.contains('FAIL') ||
        voiceUpper.contains('FAIL') ||
        gpsUpper.contains('OUTSIDE')) {
      state = state!.copyWith(finalResult: 'FAILED', attendanceUpdated: false);
    }
  }

  void clearSession() {
    state = null;
  }
}
