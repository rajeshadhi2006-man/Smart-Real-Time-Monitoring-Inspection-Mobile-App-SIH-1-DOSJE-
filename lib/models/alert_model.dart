class AlertModel {
  final String id;
  final String category; // UNAUTHORIZED ENTRY, VERIFICATION FAILED, FACE MISMATCH, VOICE MISMATCH, GPS OUTSIDE, DEVICE OFFLINE, REPEATED VERIFICATION FAILURE, SUSPICIOUS LOCATION
  final String severity; // HIGH, MEDIUM, LOW, CRITICAL
  final String personId;
  final String personName;
  final String location;
  final DateTime timestamp;
  final String description;
  final String status; // NEW, ACKNOWLEDGED, RESOLVED

  const AlertModel({
    required this.id,
    required this.category,
    required this.severity,
    required this.personId,
    required this.personName,
    required this.location,
    required this.timestamp,
    required this.description,
    required this.status,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      category: json['category'] ?? json['type'] ?? 'UNAUTHORIZED ENTRY',
      severity: (json['severity'] ?? 'HIGH').toString().toUpperCase(),
      personId: json['person_id']?.toString() ?? '',
      personName: json['person_name'] ?? 'Monitored Subject',
      location: json['location'] ?? 'Site A',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] ?? 'Security alert triggered',
      status: (json['status'] ?? 'NEW').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'severity': severity,
      'person_id': personId,
      'person_name': personName,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'status': status,
    };
  }

  AlertModel copyWith({String? status}) {
    return AlertModel(
      id: id,
      category: category,
      severity: severity,
      personId: personId,
      personName: personName,
      location: location,
      timestamp: timestamp,
      description: description,
      status: status ?? this.status,
    );
  }
}
