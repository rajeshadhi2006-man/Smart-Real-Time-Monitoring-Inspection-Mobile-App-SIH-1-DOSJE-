class AssignmentModel {
  final String id;
  final String assignmentId;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String assignedLocation;
  final String geofenceId;
  final String geofenceName;
  final String schemeName;
  final String institutionName;
  final double latitude;
  final double longitude;
  final String targetGeohash;
  final double radiusMeters;
  final String status;
  final String assignedAt;
  final String? assignedBy;
  final String? timeWindow;
  final String? scheduledDate;
  final String? startTime;
  final String? endTime;
  final String evidenceRequirement;
  final double? distanceMeters;
  final String assignmentType;
  final bool isSurprise;
  final String priority;
  final String attendanceStatus;
  final String inspectionStatus;

  AssignmentModel({
    required this.id,
    String? assignmentId,
    required this.userId,
    required this.userName,
    String? title,
    String? description,
    String? assignedLocation,
    required this.geofenceId,
    required this.geofenceName,
    required this.schemeName,
    required this.institutionName,
    required this.latitude,
    required this.longitude,
    String? targetGeohash,
    required this.radiusMeters,
    required this.status,
    required this.assignedAt,
    this.assignedBy,
    this.timeWindow,
    this.scheduledDate,
    this.startTime,
    this.endTime,
    this.evidenceRequirement = 'GEO_TAGGED_PHOTO',
    this.distanceMeters,
    this.assignmentType = 'NORMAL_INSPECTION',
    this.isSurprise = false,
    this.priority = 'MEDIUM',
    this.attendanceStatus = 'PENDING',
    this.inspectionStatus = 'PENDING',
  })  : assignmentId = assignmentId ?? id,
        title = title ?? schemeName,
        description = description ?? 'Conduct on-site physical compliance verification.',
        assignedLocation = assignedLocation ?? geofenceName,
        targetGeohash = targetGeohash ?? 't9ywxjt9';

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final asgId = json['assignment_id'] ?? json['id'] ?? '';
    final asgTitle = json['title'] ?? json['assignment_name'] ?? json['scheme_name'] ?? json['project_name'] ?? 'Inspection Assignment';
    final asgDesc = json['description'] ?? 'Conduct on-site physical compliance verification.';
    final asgLoc = json['target_location'] ?? json['assigned_location'] ?? json['geofence_name'] ?? json['location_address'] ?? 'Authorized Inspection Perimeter';
    final lat = (json['target_latitude'] ?? json['center_latitude'] ?? json['latitude'] ?? 11.016844).toDouble();
    final lon = (json['target_longitude'] ?? json['center_longitude'] ?? json['longitude'] ?? 76.955832).toDouble();
    final rad = (json['allowed_radius_meters'] ?? json['geofence_radius'] ?? json['radius_meters'] ?? 100.0).toDouble();
    
    final asgType = json['assignment_type'] ?? 'NORMAL_INSPECTION';
    final bool surpriseFlag = json['is_surprise'] == true || json['is_surprise'] == 1 || asgType == 'SURPRISE_INSPECTION';

    return AssignmentModel(
      id: asgId,
      assignmentId: asgId,
      userId: json['assigned_user_id'] ?? json['user_id'] ?? json['officer_id'] ?? '',
      userName: json['user_name'] ?? 'Field Inspector',
      title: asgTitle,
      description: asgDesc,
      assignedLocation: asgLoc,
      geofenceId: json['geofence_id'] ?? json['geofence']?['id'] ?? 'GEO-TARGET',
      geofenceName: asgLoc,
      schemeName: asgTitle,
      institutionName: json['target_location'] ?? json['institution_name'] ?? json['ngo_institute'] ?? asgLoc,
      latitude: lat,
      longitude: lon,
      targetGeohash: json['target_geohash'] ?? json['geo_hash'] ?? 't9ywxjt9',
      radiusMeters: rad,
      status: json['status'] ?? 'ACTIVE',
      assignedAt: json['created_at'] ?? json['assigned_at'] ?? DateTime.now().toIso8601String(),
      assignedBy: json['assigned_by'] ?? 'State Command Center',
      timeWindow: json['time_window'] ?? '${json['start_time'] ?? "09:00 AM"} - ${json['end_time'] ?? "05:00 PM"}',
      scheduledDate: json['scheduled_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      evidenceRequirement: json['evidence_requirement'] ?? 'GEO_TAGGED_PHOTO',
      distanceMeters: json['distance_meters']?.toDouble(),
      assignmentType: asgType,
      isSurprise: surpriseFlag,
      priority: json['priority'] ?? 'MEDIUM',
      attendanceStatus: json['attendance_status'] ?? 'PENDING',
      inspectionStatus: json['inspection_status'] ?? 'PENDING',
    );
  }

  AssignmentModel copyWith({
    String? status,
    double? distanceMeters,
    String? attendanceStatus,
    String? inspectionStatus,
  }) {
    return AssignmentModel(
      id: id,
      assignmentId: assignmentId,
      userId: userId,
      userName: userName,
      title: title,
      description: description,
      assignedLocation: assignedLocation,
      geofenceId: geofenceId,
      geofenceName: geofenceName,
      schemeName: schemeName,
      institutionName: institutionName,
      latitude: latitude,
      longitude: longitude,
      targetGeohash: targetGeohash,
      radiusMeters: radiusMeters,
      status: status ?? this.status,
      assignedAt: assignedAt,
      assignedBy: assignedBy,
      timeWindow: timeWindow,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      evidenceRequirement: evidenceRequirement,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      assignmentType: assignmentType,
      isSurprise: isSurprise,
      priority: priority,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
    );
  }
}
