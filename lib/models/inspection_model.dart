class InspectionModel {
  final String id;
  final String inspectionCode;
  final String projectId;
  final String projectName;
  final String ngoInstitute;
  final String inspectionType;
  final String priority;
  final String status;
  final String? inspectorId;
  final String? inspectorName;
  final String createdAt;

  InspectionModel({
    required this.id,
    required this.inspectionCode,
    required this.projectId,
    required this.projectName,
    required this.ngoInstitute,
    required this.inspectionType,
    required this.priority,
    required this.status,
    this.inspectorId,
    this.inspectorName,
    required this.createdAt,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'] ?? '',
      inspectionCode: json['inspection_code'] ?? 'INSP-000',
      projectId: json['project_id'] ?? '',
      projectName: json['project_name'] ?? 'DoSJE Scheme',
      ngoInstitute: json['ngo_institute'] ?? 'Inspection Facility',
      inspectionType: json['inspection_type'] ?? 'SURPRISE_ROUTINE',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'PENDING',
      inspectorId: json['inspector_id'],
      inspectorName: json['inspector_name'],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class EvidenceItemModel {
  final String id;
  final String inspectionId;
  final String evidenceType; // PHOTO, VIDEO, DOCUMENT
  final String fileUrl;
  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;
  final double? distanceMeters;
  final String? sha256Hash;
  final String? submissionStatus;
  final String timestamp;
  final String? inspectorId;
  final String? description;
  final String category; // Infrastructure, Attendance, Beneficiary, Document, Safety, Other

  EvidenceItemModel({
    required this.id,
    required this.inspectionId,
    required this.evidenceType,
    required this.fileUrl,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.distanceMeters,
    this.sha256Hash,
    this.submissionStatus = 'VERIFIED',
    required this.timestamp,
    this.inspectorId,
    this.description,
    this.category = 'Infrastructure',
  });

  factory EvidenceItemModel.fromJson(Map<String, dynamic> json) {
    return EvidenceItemModel(
      id: (json['evidence_id'] ?? json['id'] ?? '').toString(),
      inspectionId: (json['inspection_id'] ?? '').toString(),
      evidenceType: (json['evidence_type'] ?? 'PHOTO').toString(),
      fileUrl: (json['image_url'] ?? json['file_url'] ?? '').toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      gpsAccuracy: json['gps_accuracy'] != null ? double.tryParse(json['gps_accuracy'].toString()) : null,
      distanceMeters: json['distance_meters'] != null ? double.tryParse(json['distance_meters'].toString()) : null,
      sha256Hash: json['sha256_hash']?.toString(),
      submissionStatus: (json['submission_status'] ?? 'VERIFIED').toString(),
      timestamp: (json['captured_at'] ?? json['timestamp'] ?? json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      inspectorId: (json['officer_id'] ?? json['inspector_id'])?.toString(),
      description: json['description']?.toString(),
      category: (json['category'] ?? 'Infrastructure').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evidence_id': id,
      'inspection_id': inspectionId,
      'evidence_type': evidenceType,
      'file_url': fileUrl,
      'image_url': fileUrl,
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy': gpsAccuracy,
      'distance_meters': distanceMeters,
      'sha256_hash': sha256Hash,
      'submission_status': submissionStatus,
      'timestamp': timestamp,
      'captured_at': timestamp,
      'inspector_id': inspectorId,
      'officer_id': inspectorId,
      'description': description,
      'category': category,
    };
  }
}
