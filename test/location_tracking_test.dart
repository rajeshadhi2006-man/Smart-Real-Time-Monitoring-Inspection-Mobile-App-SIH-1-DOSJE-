import 'package:flutter_test/flutter_test.dart';
import 'package:sih_inspection/services/location_service.dart';

void main() {
  test('Location distance calculation test', () {
    // Distance between two close points (approx 111 meters for 0.001 deg lat change)
    final distance = LocationService.calculateDistanceMeters(
      11.0168,
      76.9558,
      11.0178,
      76.9558,
    );

    expect(distance > 100 && distance < 120, isTrue);
  });
}
