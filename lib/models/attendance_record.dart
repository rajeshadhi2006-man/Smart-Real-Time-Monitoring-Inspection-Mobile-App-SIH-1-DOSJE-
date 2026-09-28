class AttendanceRecord {
  final String id;
  final String personId;
  final String personName;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String site;
  final String verificationStatus; // Successful, Partial, Manual Sign-off
  final String duration;
  final String status; // PRESENT, ABSENT, PENDING

  const AttendanceRecord({
    required this.id,
    required this.personId,
    required this.personName,
    required this.entryTime,
    this.exitTime,
    required this.site,
    required this.verificationStatus,
    required this.duration,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      personId: json['person_id']?.toString() ?? '',
      personName: json['person_name'] ?? json['name'] ?? 'Person',
      entryTime: json['entry_time'] != null
          ? DateTime.tryParse(json['entry_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      exitTime: json['exit_time'] != null
          ? DateTime.tryParse(json['exit_time'].toString())
          : null,
      site: json['site'] ?? json['site_name'] ?? 'Assigned Facility',
      verificationStatus: json['verification_status'] ?? 'Successful',
      duration: json['duration'] ?? '8h 00m',
      status: (json['status'] ?? 'PRESENT').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person_id': personId,
      'person_name': personName,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'site': site,
      'verification_status': verificationStatus,
      'duration': duration,
      'status': status,
    };
  }
}
