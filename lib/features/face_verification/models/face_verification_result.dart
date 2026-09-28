import 'dart:typed_data';

class FaceVerificationResult {
  final bool verified;
  final String status; // MATCH, MISMATCH, LOW_CONFIDENCE, NO_FACE, MULTIPLE_FACES, BLURRY, TOO_DARK, TOO_BRIGHT, OFF_CENTER, NOT_ENROLLED, ERROR
  final double similarity; // [0.0 - 1.0]
  final double threshold;
  final bool isLive;
  final double qualityScore;
  final String message;
  final Map<String, dynamic>? qualityMetrics;
  final Uint8List? imageBytes;

  FaceVerificationResult({
    required this.verified,
    required this.status,
    required this.similarity,
    required this.threshold,
    required this.isLive,
    required this.qualityScore,
    required this.message,
    this.qualityMetrics,
    this.imageBytes,
  });

  FaceVerificationResult copyWith({
    bool? verified,
    String? status,
    double? similarity,
    double? threshold,
    bool? isLive,
    double? qualityScore,
    String? message,
    Map<String, dynamic>? qualityMetrics,
    Uint8List? imageBytes,
  }) {
    return FaceVerificationResult(
      verified: verified ?? this.verified,
      status: status ?? this.status,
      similarity: similarity ?? this.similarity,
      threshold: threshold ?? this.threshold,
      isLive: isLive ?? this.isLive,
      qualityScore: qualityScore ?? this.qualityScore,
      message: message ?? this.message,
      qualityMetrics: qualityMetrics ?? this.qualityMetrics,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  factory FaceVerificationResult.fromJson(Map<String, dynamic> json, [Uint8List? imageBytes]) {
    final livenessData = json['liveness'] as Map<String, dynamic>?;
    final metricsData = json['quality_metrics'] as Map<String, dynamic>?;

    return FaceVerificationResult(
      verified: json['verified'] == true,
      status: json['status'] ?? (json['verified'] == true ? 'MATCH' : 'MISMATCH'),
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.88,
      isLive: livenessData?['is_live'] == true || livenessData == null,
      qualityScore: (metricsData?['quality_score'] as num?)?.toDouble() ?? 1.0,
      message: json['message'] ?? (json['verified'] == true ? 'Face verified successfully.' : 'Verification failed.'),
      qualityMetrics: metricsData,
      imageBytes: imageBytes,
    );
  }

  factory FaceVerificationResult.error(String message, [String status = 'ERROR', Uint8List? imageBytes]) {
    return FaceVerificationResult(
      verified: false,
      status: status,
      similarity: 0.0,
      threshold: 0.88,
      isLive: false,
      qualityScore: 0.0,
      message: message,
      imageBytes: imageBytes,
    );
  }
}
