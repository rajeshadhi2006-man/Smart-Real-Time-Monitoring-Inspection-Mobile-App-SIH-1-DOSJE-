enum InspectionStatus {
  assigned('Assigned'),
  accepted('Accepted'),
  inProgress('In Progress'),
  submitted('Submitted'),
  underReview('Under Review'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const InspectionStatus(this.label);
}

enum ChecklistCategory {
  infrastructure('Infrastructure'),
  services('Services'),
  beneficiaries('Beneficiaries'),
  documentation('Documentation');

  final String label;
  const ChecklistCategory(this.label);
}

enum ChecklistOption { pass, fail, notApplicable }

class ChecklistItemModel {
  final String id;
  final ChecklistCategory category;
  final String question;
  final ChecklistOption? selectedOption;
  final String remarks;
  final bool isMandatory;

  const ChecklistItemModel({
    required this.id,
    required this.category,
    required this.question,
    this.selectedOption,
    this.remarks = '',
    this.isMandatory = true,
  });

  ChecklistItemModel copyWith({
    ChecklistOption? selectedOption,
    String? remarks,
  }) {
    return ChecklistItemModel(
      id: id,
      category: category,
      question: question,
      selectedOption: selectedOption ?? this.selectedOption,
      remarks: remarks ?? this.remarks,
      isMandatory: isMandatory,
    );
  }
}

/// Official Inspection Entity with full tracking metadata
class InspectionModel {
  final String id;
  final String projectId;
  final String projectName;
  final String organization;
  final String district;
  final InspectionStatus status;
  final String priority;
  final String assignmentReason;
  final String scheduledWindow;
  final String deadline;
  final String assignedInspector;

  // Location Verification
  final bool isGpsVerified;
  final double? distanceMeters;
  final double? verifiedLatitude;
  final double? verifiedLongitude;
  final double? gpsAccuracy;

  // Checklist
  final List<ChecklistItemModel> checklist;

  // Evidence & Attendance
  final int photoCount;
  final int videoCount;
  final int expectedBeneficiaries;
  final int verifiedBeneficiaries;

  // AI Anomaly Data
  final String aiRiskLevel;
  final List<String> aiRiskReasons;

  // Inspector Notes
  final String inspectorRemarks;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final bool isOfflineDraft;
  final bool isSynced;

  const InspectionModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.organization,
    required this.district,
    required this.status,
    required this.priority,
    required this.assignmentReason,
    required this.scheduledWindow,
    required this.deadline,
    required this.assignedInspector,
    this.isGpsVerified = false,
    this.distanceMeters,
    this.verifiedLatitude,
    this.verifiedLongitude,
    this.gpsAccuracy,
    required this.checklist,
    this.photoCount = 0,
    this.videoCount = 0,
    this.expectedBeneficiaries = 120,
    this.verifiedBeneficiaries = 0,
    this.aiRiskLevel = 'Medium',
    this.aiRiskReasons = const [],
    this.inspectorRemarks = '',
    this.startedAt,
    this.submittedAt,
    this.isOfflineDraft = false,
    this.isSynced = true,
  });

  int get completedChecklistCount =>
      checklist.where((item) => item.selectedOption != null).length;

  int get totalChecklistCount => checklist.length;

  double get checklistProgress =>
      totalChecklistCount == 0 ? 0.0 : completedChecklistCount / totalChecklistCount;

  InspectionModel copyWith({
    InspectionStatus? status,
    bool? isGpsVerified,
    double? distanceMeters,
    double? verifiedLatitude,
    double? verifiedLongitude,
    double? gpsAccuracy,
    List<ChecklistItemModel>? checklist,
    int? photoCount,
    int? videoCount,
    int? verifiedBeneficiaries,
    String? aiRiskLevel,
    List<String>? aiRiskReasons,
    String? inspectorRemarks,
    DateTime? startedAt,
    DateTime? submittedAt,
    bool? isOfflineDraft,
    bool? isSynced,
  }) {
    return InspectionModel(
      id: id,
      projectId: projectId,
      projectName: projectName,
      organization: organization,
      district: district,
      status: status ?? this.status,
      priority: priority,
      assignmentReason: assignmentReason,
      scheduledWindow: scheduledWindow,
      deadline: deadline,
      assignedInspector: assignedInspector,
      isGpsVerified: isGpsVerified ?? this.isGpsVerified,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      verifiedLatitude: verifiedLatitude ?? this.verifiedLatitude,
      verifiedLongitude: verifiedLongitude ?? this.verifiedLongitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      checklist: checklist ?? this.checklist,
      photoCount: photoCount ?? this.photoCount,
      videoCount: videoCount ?? this.videoCount,
      expectedBeneficiaries: expectedBeneficiaries,
      verifiedBeneficiaries: verifiedBeneficiaries ?? this.verifiedBeneficiaries,
      aiRiskLevel: aiRiskLevel ?? this.aiRiskLevel,
      aiRiskReasons: aiRiskReasons ?? this.aiRiskReasons,
      inspectorRemarks: inspectorRemarks ?? this.inspectorRemarks,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      isOfflineDraft: isOfflineDraft ?? this.isOfflineDraft,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'organization': organization,
      'district': district,
      'status': status.name,
      'priority': priority,
      'assignment_reason': assignmentReason,
      'scheduled_window': scheduledWindow,
      'deadline': deadline,
      'assigned_inspector': assignedInspector,
      'is_gps_verified': isGpsVerified,
      'distance_meters': distanceMeters,
      'verified_latitude': verifiedLatitude,
      'verified_longitude': verifiedLongitude,
      'gps_accuracy': gpsAccuracy,
      'photo_count': photoCount,
      'video_count': videoCount,
      'expected_beneficiaries': expectedBeneficiaries,
      'verified_beneficiaries': verifiedBeneficiaries,
      'ai_risk_level': aiRiskLevel,
      'inspector_remarks': inspectorRemarks,
    };
  }

  factory InspectionModel.fromMap(Map<String, dynamic> map) {
    InspectionStatus parsedStatus = InspectionStatus.assigned;
    final statusStr = map['status']?.toString() ?? 'assigned';
    for (final s in InspectionStatus.values) {
      if (s.name == statusStr || s.label.toLowerCase() == statusStr.toLowerCase()) {
        parsedStatus = s;
        break;
      }
    }

    return InspectionModel(
      id: map['id']?.toString() ?? map['assignment_id']?.toString() ?? 'INS-${DateTime.now().millisecondsSinceEpoch}',
      projectId: map['project_id']?.toString() ?? map['assignment_id']?.toString() ?? 'PRJ-${DateTime.now().millisecond}',
      projectName: map['project_name']?.toString() ?? map['title']?.toString() ?? 'Enrolled Audit Site',
      organization: map['ngo_institute']?.toString() ?? map['organization']?.toString() ?? 'Enrolled Welfare Org',
      district: map['district']?.toString() ?? map['assigned_location']?.toString() ?? 'Field District',
      status: parsedStatus,
      priority: map['priority']?.toString() ?? 'MEDIUM',
      assignmentReason: map['reason']?.toString() ?? map['assignment_reason']?.toString() ?? map['description']?.toString() ?? 'Government Portal Enrollment',
      scheduledWindow: map['scheduled_window']?.toString() ?? 'Today, 09:00 - 17:00 IST',
      deadline: map['deadline']?.toString() ?? 'Active Audit Window',
      assignedInspector: map['assigned_inspector']?.toString() ?? map['assigned_user_id']?.toString() ?? map['inspector_name']?.toString() ?? 'Field Inspector',
      isGpsVerified: map['is_gps_verified'] == true,
      distanceMeters: map['distance_meters'] != null ? (map['distance_meters'] as num).toDouble() : null,
      verifiedLatitude: map['verified_latitude'] != null
          ? (map['verified_latitude'] as num).toDouble()
          : (map['target_latitude'] != null ? (map['target_latitude'] as num).toDouble() : null),
      verifiedLongitude: map['verified_longitude'] != null
          ? (map['verified_longitude'] as num).toDouble()
          : (map['target_longitude'] != null ? (map['target_longitude'] as num).toDouble() : null),
      gpsAccuracy: map['gps_accuracy'] != null ? (map['gps_accuracy'] as num).toDouble() : null,
      checklist: defaultInspectionChecklist,
      photoCount: (map['photo_count'] as num?)?.toInt() ?? 0,
      videoCount: (map['video_count'] as num?)?.toInt() ?? 0,
      expectedBeneficiaries: (map['expected_beneficiaries'] as num?)?.toInt() ?? 100,
      verifiedBeneficiaries: (map['verified_beneficiaries'] as num?)?.toInt() ?? 0,
      aiRiskLevel: map['ai_risk_level']?.toString() ?? 'Low',
      aiRiskReasons: map['ai_risk_reasons'] is List
          ? List<String>.from(map['ai_risk_reasons'])
          : const [],
      inspectorRemarks: map['inspector_remarks']?.toString() ?? '',
      startedAt: map['started_at'] != null ? DateTime.tryParse(map['started_at'].toString()) : null,
      submittedAt: map['submitted_at'] != null ? DateTime.tryParse(map['submitted_at'].toString()) : null,
      isSynced: true,
    );
  }

  static const List<ChecklistItemModel> defaultInspectionChecklist = [
    ChecklistItemModel(
      id: 'chk_infra_01',
      category: ChecklistCategory.infrastructure,
      question: 'Building structure is stable, weatherproof, and properly ventilated.',
    ),
    ChecklistItemModel(
      id: 'chk_infra_02',
      category: ChecklistCategory.infrastructure,
      question: 'Adequate sanitation facilities, segregated washrooms, and clean drinking water.',
    ),
    ChecklistItemModel(
      id: 'chk_infra_03',
      category: ChecklistCategory.infrastructure,
      question: 'Barrier-free accessibility: Ramps with handrails and tactile paving.',
    ),
    ChecklistItemModel(
      id: 'chk_infra_04',
      category: ChecklistCategory.infrastructure,
      question: 'Fire safety: Active extinguishers, unobstructed exits, and emergency alarms.',
    ),
    ChecklistItemModel(
      id: 'chk_serv_01',
      category: ChecklistCategory.services,
      question: 'Approved welfare and training curriculum actively being conducted.',
    ),
    ChecklistItemModel(
      id: 'chk_serv_02',
      category: ChecklistCategory.services,
      question: 'Full complement of certified vocational trainers and counselors present.',
    ),
    ChecklistItemModel(
      id: 'chk_serv_03',
      category: ChecklistCategory.services,
      question: 'Nutritional food provided per MoSJE dietary guidelines.',
    ),
    ChecklistItemModel(
      id: 'chk_ben_01',
      category: ChecklistCategory.beneficiaries,
      question: 'Physical presence matches biometric and register headcounts.',
    ),
    ChecklistItemModel(
      id: 'chk_ben_02',
      category: ChecklistCategory.beneficiaries,
      question: 'Beneficiary admission forms verified with Aadhaar/UDID cards.',
    ),
    ChecklistItemModel(
      id: 'chk_ben_03',
      category: ChecklistCategory.beneficiaries,
      question: 'Grievance register maintained and accessible to beneficiaries.',
    ),
    ChecklistItemModel(
      id: 'chk_doc_01',
      category: ChecklistCategory.documentation,
      question: 'NGO registration under Societies/Trust Act and Darpan Portal valid.',
    ),
    ChecklistItemModel(
      id: 'chk_doc_02',
      category: ChecklistCategory.documentation,
      question: 'Staff salary disbursement records through PFMS/bank transfer verified.',
    ),
  ];
}
