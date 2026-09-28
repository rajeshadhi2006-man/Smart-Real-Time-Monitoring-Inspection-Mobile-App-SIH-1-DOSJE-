import 'api_service.dart';
import '../core/config/api_config.dart';

class VerificationResult {
  final bool isGpsValid;
  final String faceStatus;
  final String voiceStatus;
  final String overallStatus; // VERIFIED, FAILED
  final String message;
  final double confidenceScore;

  VerificationResult({
    required this.isGpsValid,
    required this.faceStatus,
    required this.voiceStatus,
    required this.overallStatus,
    required this.message,
    required this.confidenceScore,
  });
}

class VerificationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> verifyFace(String userId, String imageBase64) async {
    try {
      final response = await _apiService.post(
        ApiConfig.verificationFaceUrl,
        data: {
          'user_id': userId,
          'sample_data': imageBase64,
        },
      );
      return response.data ?? {};
    } catch (e) {
      return {
        'status': 'VERIFICATION FAILED',
        'message': e.toString(),
        'confidence_score': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>> verifyVoice(String userId, String audioBase64) async {
    try {
      final response = await _apiService.post(
        ApiConfig.verificationVoiceUrl,
        data: {
          'user_id': userId,
          'sample_data': audioBase64,
        },
      );
      return response.data ?? {};
    } catch (e) {
      return {
        'status': 'VERIFICATION FAILED',
        'message': e.toString(),
        'confidence_score': 0.0,
      };
    }
  }

  Future<VerificationResult> performMultimodalVerification({
    required String userId,
    required double latitude,
    required double longitude,
    required double accuracy,
    double? faceScore,
    double? voiceScore,
  }) async {
    // GPS accuracy check
    if (accuracy > 20.0) {
      return VerificationResult(
        isGpsValid: false,
        faceStatus: "SKIPPED",
        voiceStatus: "SKIPPED",
        overallStatus: "VERIFICATION FAILED",
        message: "GPS accuracy is insufficient (${accuracy.toStringAsFixed(1)}m). Please move to an open area.",
        confidenceScore: 0.0,
      );
    }

    // FIXED: Only send real scores — do not send hardcoded defaults
    // If faceScore or voiceScore is null (no real scan), the server will mark those as NOT_SCANNED
    try {
      final response = await _apiService.post(
        ApiConfig.verificationFuseUrl,
        data: {
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          if (faceScore != null) 'face_score': faceScore,
          if (voiceScore != null) 'voice_score': voiceScore,
        },
      );

      final data = response.data ?? {};
      final finalRes = data['final_result'] ?? data['result'] ?? 'FAILED';
      final faceRes = data['face_result'] ?? 'NOT_SCANNED';
      final voiceRes = data['voice_result'] ?? 'NOT_SCANNED';
      final gpsRes = data['gps_result'] ?? 'FAILED';
      final confidence = (data['final_confidence'] ?? 0.0).toDouble();
      final isGpsOk = gpsRes == 'VERIFIED';

      return VerificationResult(
        isGpsValid: isGpsOk,
        faceStatus: faceRes,
        voiceStatus: voiceRes,
        overallStatus: finalRes,
        message: data['message'] ?? (finalRes == 'VERIFIED'
            ? 'Multi-Factor Location & Biometric Verification Succeeded'
            : 'Multi-Factor Verification Failed'),
        confidenceScore: confidence,
      );
    } catch (e) {
      // FIXED: No longer silently returns VERIFIED on network failure
      // Network error = real failure that the user must know about
      return VerificationResult(
        isGpsValid: true, // GPS was already verified locally
        faceStatus: faceScore != null ? "SCANNED" : "NOT_SCANNED",
        voiceStatus: voiceScore != null ? "SCANNED" : "NOT_SCANNED",
        overallStatus: "NETWORK_ERROR",
        message: "Cannot reach verification server: $e. Please check your connection.",
        confidenceScore: 0.0,
      );
    }
  }
}
