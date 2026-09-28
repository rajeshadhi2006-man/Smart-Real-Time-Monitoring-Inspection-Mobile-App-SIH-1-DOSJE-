class AlertModel {
  final String id;
  final String title;
  final String message;
  final String alertType; // ASSIGNMENT, GEOFENCE_ENTRY, GEOFENCE_EXIT, VERIFICATION_REQUEST, EMERGENCY
  final String severity; // INFO, WARNING, CRITICAL
  final String timestamp;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.alertType,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      title: json['title'] ?? json['event_type'] ?? 'System Notification',
      message: json['message'] ?? json['details'] ?? json['reason'] ?? '',
      alertType: json['alert_type'] ?? json['event_type'] ?? 'INFO',
      severity: json['severity'] ?? json['risk_level'] ?? 'INFO',
      timestamp: json['timestamp'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] == 1 || json['status'] == 'ACKNOWLEDGED',
    );
  }
}
