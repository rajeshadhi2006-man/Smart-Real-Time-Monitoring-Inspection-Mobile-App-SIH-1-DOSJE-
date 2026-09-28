class FaceEnrollmentStatus {
  final bool isEnrolled;
  final String userId;
  final String? modelVersion;
  final double? qualityScore;
  final String? enrolledAt;
  final String? message;

  FaceEnrollmentStatus({
    required this.isEnrolled,
    required this.userId,
    this.modelVersion,
    this.qualityScore,
    this.enrolledAt,
    this.message,
  });

  factory FaceEnrollmentStatus.fromJson(Map<String, dynamic> json) {
    return FaceEnrollmentStatus(
      isEnrolled: json['enrolled'] == true || json['success'] == true,
      userId: json['user_id'] ?? '',
      modelVersion: json['model_version'],
      qualityScore: (json['quality_score'] as num?)?.toDouble(),
      enrolledAt: json['enrolled_at'],
      message: json['message'],
    );
  }
}
