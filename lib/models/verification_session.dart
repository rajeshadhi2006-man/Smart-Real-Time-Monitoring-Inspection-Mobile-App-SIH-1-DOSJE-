class VerificationSession {
  final String id;
  final String personId;
  final String personName;
  final String officerId;
  final String callSessionId;
  final String faceStatus; // Scanning..., PENDING, MATCH, FAILED, MODEL_UNAVAILABLE
  final String voiceStatus; // Waiting, Listening..., Processing..., MATCH, FAILED, MODEL_UNAVAILABLE
  final String gpsStatus; // Inside Assigned Area, Outside Assigned Area, PENDING
  final String finalResult; // PENDING, VERIFIED, FAILED
  final bool attendanceUpdated;
  final DateTime createdAt;

  const VerificationSession({
    required this.id,
    required this.personId,
    required this.personName,
    required this.officerId,
    required this.callSessionId,
    required this.faceStatus,
    required this.voiceStatus,
    required this.gpsStatus,
    required this.finalResult,
    required this.attendanceUpdated,
    required this.createdAt,
  });

  factory VerificationSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    final resolvedId = json['id']?.toString() ??
        json['session_id']?.toString() ??
        data?['session_id']?.toString() ??
        data?['id']?.toString() ??
        'vsession-${DateTime.now().millisecondsSinceEpoch}';

    return VerificationSession(
      id: resolvedId.isNotEmpty ? resolvedId : 'vsession-${DateTime.now().millisecondsSinceEpoch}',
      personId: json['person_id']?.toString() ??
          data?['person_id']?.toString() ??
          json['user_id']?.toString() ??
          data?['user_id']?.toString() ??
          '',
      personName: json['person_name'] ??
          data?['person_name'] ??
          json['full_name'] ??
          json['name'] ??
          'Assigned Person',
      officerId: json['officer_id']?.toString() ??
          data?['officer_id']?.toString() ??
          'GOV-OFFICER-001',
      callSessionId: json['call_session_id']?.toString() ??
          json['session_id']?.toString() ??
          resolvedId,
      faceStatus: json['face_status'] ?? json['face'] ?? 'PENDING',
      voiceStatus: json['voice_status'] ?? json['voice'] ?? 'PENDING',
      gpsStatus: json['gps_status'] ?? json['gps'] ?? '🟢 INSIDE ASSIGNED GEOFENCE',
      finalResult: json['final_result'] ?? json['overall'] ?? 'PENDING',
      attendanceUpdated: json['attendance_updated'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person_id': personId,
      'person_name': personName,
      'officer_id': officerId,
      'call_session_id': callSessionId,
      'face_status': faceStatus,
      'voice_status': voiceStatus,
      'gps_status': gpsStatus,
      'final_result': finalResult,
      'attendance_updated': attendanceUpdated,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VerificationSession copyWith({
    String? faceStatus,
    String? voiceStatus,
    String? gpsStatus,
    String? finalResult,
    bool? attendanceUpdated,
  }) {
    return VerificationSession(
      id: id,
      personId: personId,
      personName: personName,
      officerId: officerId,
      callSessionId: callSessionId,
      faceStatus: faceStatus ?? this.faceStatus,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      finalResult: finalResult ?? this.finalResult,
      attendanceUpdated: attendanceUpdated ?? this.attendanceUpdated,
      createdAt: createdAt,
    );
  }
}
