import '../core/utils/geo_utils.dart';

/// Authorized boundary region for field audits and inspections.
class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String description;
  final int assignedPersonCount;
  final bool isActive;
  final int currentInsideCount;

  const Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.description = '',
    this.assignedPersonCount = 0,
    this.isActive = true,
    this.currentInsideCount = 0,
  });

  /// Geodesic distance from any point to the geofence perimeter (0 if inside, > 0 if outside)
  double distanceTo(double targetLat, double targetLon) {
    final double centerDistance = GeoUtils.calculateDistanceInMeters(
      startLatitude: targetLat,
      startLongitude: targetLon,
      endLatitude: latitude,
      endLongitude: longitude,
    );
    return (centerDistance - radiusMeters).clamp(0.0, double.infinity);
  }

  /// Distance from target point to geofence center in meters
  double centerDistanceTo(double targetLat, double targetLon) {
    return GeoUtils.calculateDistanceInMeters(
      startLatitude: targetLat,
      startLongitude: targetLon,
      endLatitude: latitude,
      endLongitude: longitude,
    );
  }

  /// True if the coordinate is strictly within the radius
  bool isInside(double targetLat, double targetLon) {
    final double centerDistance = centerDistanceTo(targetLat, targetLon);
    return centerDistance <= radiusMeters;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'description': description,
      'assigned_person_count': assignedPersonCount,
      'is_active': isActive,
      'current_inside_count': currentInsideCount,
    };
  }

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Geofence',
      latitude: (json['latitude'] ?? json['center_latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['center_longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0).toDouble(),
      radiusMeters: (json['radius_meters'] ?? json['radius'] ?? 100.0).toDouble(),
      description: json['description']?.toString() ?? '',
      assignedPersonCount: (json['assigned_person_count'] ?? json['assigned_count'] ?? 0).toInt(),
      isActive: json['is_active'] ?? true,
      currentInsideCount: (json['current_inside_count'] ?? json['inside_count'] ?? 0).toInt(),
    );
  }

  factory Geofence.aroundUser({
    required double latitude,
    required double longitude,
    double radiusMeters = 500.0,
    String name = 'Active Audit Site',
  }) {
    return Geofence(
      id: 'GEOFENCE-REALTIME',
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      description: 'Auto-aligned with real device GPS telemetry',
      assignedPersonCount: 1,
      isActive: true,
      currentInsideCount: 1,
    );
  }

  static const Geofence defaultAuthorizedArea = Geofence(
    id: 'GEOFENCE-TN-CBE-01',
    name: 'District Rehabilitation Centre (CRC Coimbatore)',
    latitude: 11.016844,
    longitude: 76.955832,
    radiusMeters: 500.0,
    description: 'Central campus authorized perimeter for PMU officer audits.',
    assignedPersonCount: 4,
    isActive: true,
    currentInsideCount: 3,
  );
}
