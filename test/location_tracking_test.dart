import 'package:flutter_test/flutter_test.dart';
import 'package:sih_inspection/core/utils/geo_utils.dart';
import 'package:sih_inspection/models/geofence.dart';
import 'package:sih_inspection/models/user_location.dart';
import 'package:sih_inspection/services/geofence_service.dart';

void main() {
  group('Real-Time Location Tracking & OpenStreetMap Geofence Unit Tests', () {
    const testGeofence = Geofence(
      id: 'GEOFENCE-TEST-01',
      name: 'CRC Coimbatore Facility',
      latitude: 11.016844,
      longitude: 76.955832,
      radiusMeters: 500.0,
      description: 'Test inspection perimeter',
    );

    test('UserLocation validates coordinate boundary limits', () {
      final validLocation = UserLocation(
        userId: 'OFFICER-01',
        trackingSessionId: 'SESSION-01',
        latitude: 11.016844,
        longitude: 76.955832,
        accuracy: 8.0,
        altitude: 412.0,
        speed: 1.5,
        heading: 90.0,
        timestamp: DateTime.now(),
      );
      expect(validLocation.isValidCoordinate, isTrue);

      final invalidLocation = UserLocation(
        userId: 'OFFICER-02',
        trackingSessionId: 'SESSION-02',
        latitude: 95.0, // Invalid latitude (> 90)
        longitude: 76.955832,
        accuracy: 8.0,
        altitude: 412.0,
        speed: 1.5,
        heading: 90.0,
        timestamp: DateTime.now(),
      );
      expect(invalidLocation.isValidCoordinate, isFalse);
    });

    test('UserLocation correctly formats accuracy descriptions', () {
      final highPrec = UserLocation(
        userId: 'U1',
        trackingSessionId: 'S1',
        latitude: 11.0,
        longitude: 76.0,
        accuracy: 7.5,
        altitude: 0,
        speed: 0,
        heading: 0,
        timestamp: DateTime.now(),
      );
      expect(highPrec.accuracyLabel, contains('High Precision'));

      final lowPrec = UserLocation(
        userId: 'U2',
        trackingSessionId: 'S2',
        latitude: 11.0,
        longitude: 76.0,
        accuracy: 45.0,
        altitude: 0,
        speed: 0,
        heading: 0,
        timestamp: DateTime.now(),
      );
      expect(lowPrec.accuracyLabel, contains('Low Accuracy'));
    });

    test('UserLocation serializes to JSON and Supabase format accurately', () {
      final now = DateTime.utc(2026, 9, 5, 12, 0, 0);
      final loc = UserLocation(
        userId: 'OFFICER-SIH-26095',
        trackingSessionId: 'SESSION-XYZ',
        latitude: 11.016500,
        longitude: 76.955600,
        accuracy: 5.2,
        altitude: 410.0,
        speed: 1.1,
        heading: 180.0,
        timestamp: now,
      );

      final json = loc.toJson();
      expect(json['user_id'], 'OFFICER-SIH-26095');
      expect(json['tracking_session_id'], 'SESSION-XYZ');
      expect(json['latitude'], 11.016500);
      expect(json['longitude'], 76.955600);

      final supabaseMap = loc.toSupabaseMap();
      expect(supabaseMap.containsKey('created_at'), isTrue);
      expect(supabaseMap['accuracy'], 5.2);

      final deserialized = UserLocation.fromJson(json);
      expect(deserialized.userId, loc.userId);
      expect(deserialized.latitude, loc.latitude);
      expect(deserialized.longitude, loc.longitude);
    });

    test('Geofence determines containment using Haversine calculation', () {
      // 1. Point ~48m away from center (Inside 500m radius)
      const nearbyLat = 11.016500;
      const nearbyLon = 76.955600;
      expect(testGeofence.isInside(nearbyLat, nearbyLon), isTrue);
      expect(testGeofence.distanceTo(nearbyLat, nearbyLon), equals(0.0));

      // 2. Point ~1.8km away (Outside 500m radius)
      const distantLat = 11.032000;
      const distantLon = 76.968000;
      expect(testGeofence.isInside(distantLat, distantLon), isFalse);
      expect(testGeofence.distanceTo(distantLat, distantLon), greaterThan(1000.0));
    });

    test('GeofenceService evaluates inside/outside status labels correctly', () {
      final service = GeofenceService(activeGeofence: testGeofence);

      // Nearby user location
      final insideLoc = UserLocation(
        userId: 'U1',
        trackingSessionId: 'S1',
        latitude: 11.016500,
        longitude: 76.955600,
        accuracy: 8.0,
        altitude: 412.0,
        speed: 0.0,
        heading: 0.0,
        timestamp: DateTime.now(),
      );

      final evaluationInside = service.evaluate(insideLoc);
      expect(evaluationInside.isInside, isTrue);
      expect(evaluationInside.status, GeofenceStatus.inside);
      expect(evaluationInside.statusLabel, contains('INSIDE'));
      expect(evaluationInside.distanceToPerimeterMeters, equals(0.0));

      // Distant user location
      final outsideLoc = UserLocation(
        userId: 'U2',
        trackingSessionId: 'S2',
        latitude: 11.032000,
        longitude: 76.968000,
        accuracy: 10.0,
        altitude: 418.0,
        speed: 2.0,
        heading: 45.0,
        timestamp: DateTime.now(),
      );

      final evaluationOutside = service.evaluate(outsideLoc);
      expect(evaluationOutside.isInside, isFalse);
      expect(evaluationOutside.status, GeofenceStatus.outside);
      expect(evaluationOutside.statusLabel, contains('OUTSIDE'));
      expect(evaluationOutside.distanceToPerimeterMeters, greaterThan(1000.0));
    });

    test('GeoUtils distance calculation matches expected physical measurements', () {
      final distance = GeoUtils.calculateDistanceInMeters(
        startLatitude: 11.016844,
        startLongitude: 76.955832,
        endLatitude: 11.016844,
        endLongitude: 76.955832,
      );
      expect(distance, equals(0.0));

      final formatted = GeoUtils.formatDistance(48.2);
      expect(formatted, equals('48 metres'));

      final formattedKm = GeoUtils.formatDistance(1850.0);
      expect(formattedKm, equals('1.9 km'));
    });
  });
}
