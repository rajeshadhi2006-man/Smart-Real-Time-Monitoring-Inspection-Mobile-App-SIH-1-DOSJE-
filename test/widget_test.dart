import 'package:flutter_test/flutter_test.dart';
import 'package:sih_inspection/models/user_model.dart';
import 'package:sih_inspection/models/assignment_model.dart';
import 'package:sih_inspection/core/config/app_config.dart';
import 'package:sih_inspection/core/config/api_config.dart';

void main() {
  test('UserModel deserialization test', () {
    final json = {
      'id': 'usr-001',
      'officer_id': 'OFF-INSP-01',
      'full_name': 'Inspector Officer',
      'email': 'officer@surveillance.gov.in',
      'role': 'OFFICER',
      'department': 'Field Operations'
    };

    final user = UserModel.fromJson(json);

    expect(user.id, 'usr-001');
    expect(user.officerId, 'OFF-INSP-01');
    expect(user.fullName, 'Inspector Officer');
    expect(user.role, 'OFFICER');
  });

  test('AssignmentModel deserialization test', () {
    final json = {
      'id': 'asgn-101',
      'user_id': 'OFF-INSP-01',
      'user_name': 'Inspector Officer',
      'geofence_id': 'geo-202',
      'geofence_name': 'Coimbatore Senior Care Home',
      'scheme_name': 'DoSJE Elderly Care & Monitoring',
      'institution_name': 'Anbu Old Age Home',
      'center_latitude': 11.0168,
      'center_longitude': 76.9558,
      'radius_meters': 200.0,
      'status': 'Assigned',
      'assigned_at': '2026-09-10T12:00:00Z',
    };

    final assignment = AssignmentModel.fromJson(json);

    expect(assignment.id, 'asgn-101');
    expect(assignment.latitude, 11.0168);
    expect(assignment.longitude, 76.9558);
    expect(assignment.radiusMeters, 200.0);
    expect(assignment.status, 'Assigned');
  });

  test('API_BASE_URL and WebSocket URL construction verification', () {
    // 1. Test Production HTTPS URL with trailing /api
    AppConfig.setRuntimeBaseUrl('https://api.dosje-surveillance.gov.in/api');

    expect(AppConfig.apiBaseUrl, 'https://api.dosje-surveillance.gov.in/api');
    expect(AppConfig.serverRootUrl, 'https://api.dosje-surveillance.gov.in');
    expect(ApiConfig.baseUrl, 'https://api.dosje-surveillance.gov.in');
    expect(ApiConfig.loginUrl, 'https://api.dosje-surveillance.gov.in/api/auth/login');
    expect(ApiConfig.assignmentsUrl, 'https://api.dosje-surveillance.gov.in/api/assignments');
    expect(ApiConfig.attendanceEntryUrl, 'https://api.dosje-surveillance.gov.in/api/attendance/entry');
    expect(ApiConfig.evidenceUploadUrl, 'https://api.dosje-surveillance.gov.in/api/inspections/evidence');

    // Confirm that '/api/' path segment is added exactly once and no duplicate '/api/api' exists
    expect(RegExp(r'/api/').allMatches(ApiConfig.loginUrl).length, 1);
    expect(RegExp(r'/api/').allMatches(ApiConfig.assignmentsUrl).length, 1);
    expect(RegExp(r'/api/').allMatches(ApiConfig.attendanceEntryUrl).length, 1);
    expect(ApiConfig.loginUrl.contains('/api/api'), isFalse);

    // Confirm WebSocket URL derivation: https -> wss
    expect(AppConfig.wsUrl, 'wss://api.dosje-surveillance.gov.in');
    expect(AppConfig.wsLiveUrl, 'wss://api.dosje-surveillance.gov.in/ws/live');
    expect(AppConfig.wsLocationUrl('OFF-001'), 'wss://api.dosje-surveillance.gov.in/ws/location/OFF-001');

    // 2. Test Production HTTPS URL without trailing /api
    AppConfig.setRuntimeBaseUrl('https://api.dosje-surveillance.gov.in');
    expect(AppConfig.serverRootUrl, 'https://api.dosje-surveillance.gov.in');
    expect(ApiConfig.loginUrl, 'https://api.dosje-surveillance.gov.in/api/auth/login');
    expect(RegExp(r'/api/').allMatches(ApiConfig.loginUrl).length, 1);

    // 3. Test Development HTTP URL: http -> ws
    AppConfig.setRuntimeBaseUrl('http://localhost:8000');
    expect(AppConfig.serverRootUrl, 'http://localhost:8000');
    expect(AppConfig.wsUrl, 'ws://localhost:8000');
    expect(AppConfig.wsLiveUrl, 'ws://localhost:8000/ws/live');
    expect(AppConfig.wsLocationUrl('OFF-001'), 'ws://localhost:8000/ws/location/OFF-001');

    // Clean up
    AppConfig.clearRuntimeBaseUrl();
  });
}
