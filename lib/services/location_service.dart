import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Default Sovereign coordinates (National Command Center) when hardware GPS satellite is unreachable
  static Position get fallbackPosition => Position(
    latitude: 28.61390,
    longitude: 77.20900,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 215.0,
    altitudeAccuracy: 4.0,
    heading: 0.0,
    headingAccuracy: 5.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  static Future<bool> isLocationServiceEnabled() async {
    try {
      if (kIsWeb) return true;
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true;
    }
  }

  static Future<Position?> getCurrentPosition({bool allowFallback = true}) async {
    try {
      if (!kIsWeb) {
        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            try {
              final last = await Geolocator.getLastKnownPosition();
              if (last != null) return last;
            } catch (_) {}
            if (allowFallback) return fallbackPosition;
          }
        } catch (_) {}
      }

      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (_) {}

      if (!kIsWeb && (permission == LocationPermission.denied || permission == LocationPermission.deniedForever)) {
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) return last;
        } catch (_) {}
        if (allowFallback) return fallbackPosition;
      }

      // 1. Try to get recent cached position on native
      Position? lastPos;
      if (!kIsWeb) {
        try {
          lastPos = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      // 2. Query live position with fast-resolving medium accuracy
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {
        // Fallback to low-power network location
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 3),
          );
        } catch (_) {
          if (lastPos != null) return lastPos;
          if (allowFallback) return fallbackPosition;
          return null;
        }
      }
    } catch (e) {
      if (allowFallback) return fallbackPosition;
      return null;
    }
  }

  static Stream<Position> getPositionStream() async* {
    // 1. Instantly yield current position so real-time maps and UI load without delay
    final initial = await getCurrentPosition(allowFallback: true);
    if (initial != null) {
      yield initial;
    }

    // 2. Stream subsequent real-time satellite updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Emit every 2 meters for smooth real-time map tracking
    );
    yield* Geolocator.getPositionStream(locationSettings: locationSettings).handleError((_) {});
  }

  static double calculateDistanceMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
