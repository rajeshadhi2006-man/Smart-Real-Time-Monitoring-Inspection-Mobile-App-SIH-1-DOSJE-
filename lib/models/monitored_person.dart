class MonitoredPerson {
  final String id;
  final String name;
  final String? photoUrl;
  final String status; // INSIDE, OUTSIDE, VERIFYING, VERIFIED, UNAUTHORIZED, OFFLINE
  final String assignedSite;
  final double latitude;
  final double longitude;
  final double gpsAccuracy;
  final double distanceMeters;
  final String geofenceId;
  final String geofenceName;
  final DateTime lastUpdate;
  final String todayAttendanceStatus; // PRESENT, ABSENT, PENDING
  final String deviceStatus; // ONLINE, OFFLINE

  const MonitoredPerson({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.status,
    required this.assignedSite,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracy,
    required this.distanceMeters,
    required this.geofenceId,
    required this.geofenceName,
    required this.lastUpdate,
    required this.todayAttendanceStatus,
    required this.deviceStatus,
  });

  factory MonitoredPerson.fromJson(Map<String, dynamic> json) {
    return MonitoredPerson(
      id: json['id']?.toString() ?? json['person_id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? 'Unknown Person',
      photoUrl: json['photo_url'] ?? json['avatar_url'],
      status: (json['status'] ?? 'OFFLINE').toString().toUpperCase(),
      assignedSite: json['assigned_site'] ?? json['site_name'] ?? 'Unassigned Site',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0).toDouble(),
      gpsAccuracy: (json['gps_accuracy'] ?? json['accuracy'] ?? 0.0).toDouble(),
      distanceMeters: (json['distance_meters'] ?? json['distance'] ?? 0.0).toDouble(),
      geofenceId: json['geofence_id']?.toString() ?? '',
      geofenceName: json['geofence_name'] ?? 'Default Site Geofence',
      lastUpdate: json['last_update'] != null
          ? DateTime.tryParse(json['last_update'].toString()) ?? DateTime.now()
          : DateTime.now(),
      todayAttendanceStatus: (json['today_attendance'] ?? 'PENDING').toString().toUpperCase(),
      deviceStatus: (json['device_status'] ?? 'OFFLINE').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo_url': photoUrl,
      'status': status,
      'assigned_site': assignedSite,
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy': gpsAccuracy,
      'distance_meters': distanceMeters,
      'geofence_id': geofenceId,
      'geofence_name': geofenceName,
      'last_update': lastUpdate.toIso8601String(),
      'today_attendance': todayAttendanceStatus,
      'device_status': deviceStatus,
    };
  }
}
