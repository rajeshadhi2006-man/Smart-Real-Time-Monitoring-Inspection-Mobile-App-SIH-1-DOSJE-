class AttendanceRecord {
  final String id;
  final String userId;
  final String date;
  final String checkInTime;
  final String? checkOutTime;
  final double entryLat;
  final double entryLng;
  final String status; // PRESENT, ABSENT, FLAGGED_ENTRY, DEPARTED
  final bool geofenceVerified;
  final bool faceVerified;
  final bool voiceVerified;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
    required this.entryLat,
    required this.entryLng,
    required this.status,
    required this.geofenceVerified,
    required this.faceVerified,
    required this.voiceVerified,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['officer_id'] ?? '',
      date: json['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      checkInTime: json['check_in_time'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      checkOutTime: json['check_out_time'],
      entryLat: (json['entry_lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      entryLng: (json['entry_lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'PRESENT',
      geofenceVerified: json['geofence_verified'] == 1 || json['geofence_verified'] == true,
      faceVerified: json['face_verified'] == 1 || json['face_verified'] == true,
      voiceVerified: json['voice_verified'] == 1 || json['voice_verified'] == true,
    );
  }
}
