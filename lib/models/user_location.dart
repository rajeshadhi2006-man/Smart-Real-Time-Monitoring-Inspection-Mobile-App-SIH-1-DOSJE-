/// Represents a validated GPS location update transmitted by the field officer device.
class UserLocation {
  final String userId;
  final String trackingSessionId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final bool isOfflineQueued;

  const UserLocation({
    required this.userId,
    required this.trackingSessionId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.isOfflineQueued = false,
  });

  /// Validates whether the coordinates fall within legal planetary bounds
  bool get isValidCoordinate {
    return latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  /// Formatted accuracy description
  String get accuracyLabel {
    if (accuracy <= 10.0) {
      return '${accuracy.toStringAsFixed(1)} m (High Precision)';
    } else if (accuracy <= 25.0) {
      return '${accuracy.toStringAsFixed(1)} m (Moderate)';
    } else {
      return '${accuracy.toStringAsFixed(1)} m (Low Accuracy)';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tracking_session_id': trackingSessionId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'is_offline_queued': isOfflineQueued,
    };
  }

  /// Payload format matching Supabase PostgreSQL `location_updates` schema
  Map<String, dynamic> toSupabaseMap() {
    return {
      'user_id': userId,
      'tracking_session_id': trackingSessionId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'created_at': timestamp.toUtc().toIso8601String(),
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['user_id'] as String? ?? 'unknown',
      trackingSessionId: json['tracking_session_id'] as String? ?? 'default',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      isOfflineQueued: json['is_offline_queued'] as bool? ?? false,
    );
  }

  UserLocation copyWith({
    String? userId,
    String? trackingSessionId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    bool? isOfflineQueued,
  }) {
    return UserLocation(
      userId: userId ?? this.userId,
      trackingSessionId: trackingSessionId ?? this.trackingSessionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      isOfflineQueued: isOfflineQueued ?? this.isOfflineQueued,
    );
  }
}
