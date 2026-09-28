import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';

/// Geolocation calculation and validation utilities
class GeoUtils {
  const GeoUtils._();

  /// Calculates geodesic distance between two coordinate pairs in meters using Haversine formula
  static double calculateDistanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const double earthRadius = 6371000; // meters

    final double dLat = _toRadians(endLatitude - startLatitude);
    final double dLon = _toRadians(endLongitude - startLongitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLatitude)) *
            math.cos(_toRadians(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * (math.pi / 180.0);
  }

  /// Verifies if inspector is within allowed project geofence radius
  static bool isWithinGeofence({
    required double inspectorLat,
    required double inspectorLon,
    required double projectLat,
    required double projectLon,
    double? customRadiusMeters,
  }) {
    final double radius = customRadiusMeters ?? AppConfig.maxGeofenceRadiusMeters;
    final double distance = calculateDistanceInMeters(
      startLatitude: inspectorLat,
      startLongitude: inspectorLon,
      endLatitude: projectLat,
      endLongitude: projectLon,
    );
    return distance <= radius;
  }

  /// Formats distance for display (e.g. "48 m" or "1.8 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} metres';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Validates Position object for mock location and accuracy compliance
  static (bool isValid, String? reason) validatePosition(Position position) {
    if (AppConfig.enableMockLocationDetection && position.isMocked) {
      return (false, 'Mock / Simulated GPS location detected. Real device GPS is required.');
    }
    if (position.accuracy > AppConfig.minGpsAccuracyMeters) {
      return (
        false,
        'GPS accuracy is ${position.accuracy.toStringAsFixed(1)}m. Minimum required is ${AppConfig.minGpsAccuracyMeters.toStringAsFixed(0)}m. Please move to an open area.',
      );
    }
    return (true, null);
  }
}
