/// Lifecycle state and metadata for an authorized location tracking session.
class TrackingSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final String deviceModel;
  final String? geofenceId;

  const TrackingSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.isActive = true,
    this.deviceModel = 'Mobile Client',
    this.geofenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'is_active': isActive,
      'device_model': deviceModel,
      'geofence_id': geofenceId,
    };
  }

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    return TrackingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      deviceModel: json['device_model'] as String? ?? 'Mobile Client',
      geofenceId: json['geofence_id'] as String?,
    );
  }

  TrackingSession copyWith({
    String? id,
    String? userId,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isActive,
    String? deviceModel,
    String? geofenceId,
  }) {
    return TrackingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isActive: isActive ?? this.isActive,
      deviceModel: deviceModel ?? this.deviceModel,
      geofenceId: geofenceId ?? this.geofenceId,
    );
  }
}
