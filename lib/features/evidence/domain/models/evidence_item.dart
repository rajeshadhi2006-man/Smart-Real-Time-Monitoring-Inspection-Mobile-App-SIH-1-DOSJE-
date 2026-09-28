import '../../../../core/config/app_config.dart';

enum EvidenceType { photo, video }

enum EvidenceUploadStatus { pending, uploading, uploaded, failed }

class EvidenceItem {
  final String id;
  final String inspectionId;
  final EvidenceType type;
  final String localFilePath;
  final String? remoteUrl;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final String sha256Hash;
  final String categoryTag; // e.g. Infrastructure, Classrooms, Sanitation, Attendance
  final EvidenceUploadStatus status;
  final double uploadProgress; // 0.0 to 1.0

  const EvidenceItem({
    required this.id,
    required this.inspectionId,
    required this.type,
    required this.localFilePath,
    this.remoteUrl,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.sha256Hash,
    required this.categoryTag,
    this.status = EvidenceUploadStatus.uploaded,
    this.uploadProgress = 1.0,
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['image_url'] ?? json['remote_url'] ?? json['file_url'] ?? '').toString();
    final fullUrl = rawUrl.isEmpty
        ? null
        : (rawUrl.startsWith('http') ? rawUrl : '${AppConfig.mediaBaseUrl}$rawUrl');

    return EvidenceItem(
      id: json['evidence_id']?.toString() ?? json['id']?.toString() ?? '',
      inspectionId: json['assignment_id']?.toString() ?? json['inspection_id']?.toString() ?? '',
      type: (json['type']?.toString().toLowerCase() == 'video') ? EvidenceType.video : EvidenceType.photo,
      localFilePath: json['local_path']?.toString() ?? '',
      remoteUrl: fullUrl,
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0).toDouble(),
      sha256Hash: (json['geohash'] ?? json['sha256_hash'] ?? json['hash'] ?? 'VERIFIED_HASH').toString(),
      categoryTag: (json['verification_reason'] ?? json['category'] ?? json['submission_status'] ?? 'Field Evidence').toString(),
      status: EvidenceUploadStatus.uploaded,
      uploadProgress: 1.0,
    );
  }

  EvidenceItem copyWith({
    EvidenceUploadStatus? status,
    double? uploadProgress,
    String? remoteUrl,
  }) {
    return EvidenceItem(
      id: id,
      inspectionId: inspectionId,
      type: type,
      localFilePath: localFilePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      capturedAt: capturedAt,
      latitude: latitude,
      longitude: longitude,
      sha256Hash: sha256Hash,
      categoryTag: categoryTag,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

