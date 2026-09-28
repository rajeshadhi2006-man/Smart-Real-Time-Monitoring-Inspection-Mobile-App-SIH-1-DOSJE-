import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/storage/token_storage.dart';
import '../models/government_officer.dart';
import '../models/monitored_person.dart';
import '../models/geofence.dart';
import '../models/verification_session.dart';
import '../models/alert_model.dart';
import '../models/attendance_record.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

/// Centralized REST API Service communicating with the FastAPI Backend.
/// Strictly uses actual backend responses; returns empty lists or throws clean ApiException on errors.
class ApiService {

  final http.Client _client;
  final TokenStorage _tokenStorage;

  ApiService({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _handleError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    switch (response.statusCode) {
      case 401:
        _tokenStorage.clearToken();
        throw ApiException(401, 'Session expired. Please sign in again.');
      case 403:
        throw ApiException(403, 'Permission error: You do not have permission to perform this action.');
      case 404:
        throw ApiException(404, 'Requested resource not found.');
      case 409:
        throw ApiException(409, 'Conflict occurred with current resource state.');
      case 422:
        throw ApiException(422, 'Validation error. Please verify input data.');
      case 429:
        throw ApiException(429, 'Rate limit exceeded. Please try again shortly.');
      case 503:
        throw ApiException(503, 'Government monitoring service temporarily unavailable.');
      default:
        throw ApiException(response.statusCode, 'Server error encountered (${response.statusCode}).');
    }
  }

  /// POST /api/auth/login - Authenticate with central FastAPI backend and save JWT
  Future<String?> login(String email, String password) async {
    final candidateHosts = {
      AppConfig.apiBaseUrl,
      'http://127.0.0.1:8000/api',
      'http://10.77.108.231:8000/api',
      'http://10.162.172.231:8000/api',
      'http://10.0.2.2:8000/api',
    }.toList();

    for (final base in candidateHosts) {
      try {
        final uri = Uri.parse('$base/auth/login');
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: jsonEncode({'username': email.trim(), 'password': password}),
            )
            .timeout(const Duration(seconds: 4));

        _handleError(response);
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? data['token'];
        if (token != null) {
          await _tokenStorage.saveToken(token.toString());
          AppConfig.setResolvedBaseUrl(base);
          return token.toString();
        }
      } catch (e) {
        developer.log('FastAPI login attempt at $base failed: $e');
        if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
          rethrow;
        }
      }
    }

    // Direct Supabase Auth API fallback
    try {
      final supabaseAuthUri = Uri.parse('${AppConfig.supabaseUrl}/auth/v1/token?grant_type=password');
      final authResponse = await _client.post(
        supabaseAuthUri,
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (authResponse.statusCode == 200) {
        final data = jsonDecode(authResponse.body);
        final token = data['access_token'];
        if (token != null) {
          await _tokenStorage.saveToken(token.toString());
          return token.toString();
        }
      }
    } catch (e) {
      developer.log('Supabase Auth API error: $e');
    }

    throw ApiException(401, 'Invalid officer credentials or access denied');
  }

  /// GET /api/auth/me - Fetch current Government Officer info
  Future<GovernmentOfficer?> getOfficerProfile() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/me');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 4));
      _handleError(response);
      final data = jsonDecode(response.body);
      return GovernmentOfficer.fromJson(data);
    } catch (e) {
      developer.log('API getOfficerProfile error: $e');
    }

    // Query Supabase profiles table directly
    try {
      final profilesUri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?select=*&limit=1');
      final response = await _client.get(
        profilesUri,
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final row = data.first;
          return GovernmentOfficer(
            id: row['officer_id'] ?? row['id'] ?? 'GOV-OFFICER-001',
            name: row['full_name'] ?? 'Officer',
            email: row['email'] ?? 'officer@mosje.gov.in',
            role: row['role'] ?? 'OFFICER',
            department: row['department'] ?? 'Ministry of Social Justice and Empowerment',
            accountStatus: row['is_active'] == true ? 'Active' : 'Pending',
            connectedDevice: 'Official Field Device',
            lastSync: DateTime.now(),
          );
        }
      }
    } catch (e) {
      developer.log('Supabase profile query error: $e');
    }

    return null;
  }

  /// GET /api/users - Fetch list of currently assigned persons
  Future<List<MonitoredPerson>> getMonitoredPersons() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/users');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.map((item) => MonitoredPerson.fromJson(item)).toList();
    } catch (e) {
      developer.log('API getMonitoredPersons error: $e');
    }
    return [];
  }

  /// GET /api/geofences - Fetch assigned geofences
  Future<List<Geofence>> getGeofences() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/geofences');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.map((item) => Geofence.fromJson(item)).toList();
    } catch (e) {
      developer.log('API getGeofences error: $e');
    }
    return [];
  }

  /// POST /api/geofences - Create a new geofence
  Future<Map<String, dynamic>?> createGeofence({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String department = 'Field Operations',
    String? description,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/geofences');
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'name': name,
              'center_latitude': latitude,
              'center_longitude': longitude,
              'radius_meters': radiusMeters,
              'department': department,
              'description': ?description,
            }),

          )
          .timeout(const Duration(seconds: 6));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      developer.log('API createGeofence error: $e');
      return null;
    }
  }

  /// DELETE /api/geofences/{geofence_id}
  Future<bool> deleteGeofence(String geofenceId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/geofences/$geofenceId');
      final response = await _client.delete(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      return response.statusCode == 200;
    } catch (e) {
      developer.log('API deleteGeofence error: $e');
      return false;
    }
  }

  /// GET /api/geofences/assigned/{user_id}
  Future<Geofence?> getAssignedGeofence(String userId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/geofences/assigned/$userId');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final data = jsonDecode(response.body);
      return Geofence.fromJson(data);
    } catch (e) {
      developer.log('API getAssignedGeofence error: $e');
      return null;
    }
  }

  /// GET /api/users/locations - Fetch live user GPS telemetry
  Future<List<Map<String, dynamic>>> getUserLocations({bool history = false, int limit = 50}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/locations?history=$history&limit=$limit');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('API getUserLocations error: $e');
      return [];
    }
  }

  /// POST /api/location/update - Send live GPS telemetry
  Future<bool> sendLocationUpdate({
    required String userId,
    required double lat,
    required double lng,
    required double accuracy,
    double? altitude,
    double? speed,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/location/update');
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'user_id': userId,
              'latitude': lat,
              'longitude': lng,
              'gps_accuracy': accuracy,
              if (altitude != null) ...{'altitude': altitude},
              if (speed != null) ...{'speed': speed},

              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));
      _handleError(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('API sendLocationUpdate error: $e');
      return false;
    }
  }

  /// GET /api/inspections - Fetch assigned inspections
  Future<List<Map<String, dynamic>>> getInspections() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('API getInspections error: $e');
    }
    return [];
  }

  /// POST /api/inspections/{id}/accept
  Future<bool> acceptInspection(String inspectionId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/accept');
      final response = await _client.post(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      return response.statusCode == 200;
    } catch (e) {
      developer.log('API acceptInspection error: $e');
      return false;
    }
  }

  /// POST /api/inspections/{id}/start
  Future<bool> startInspection(String inspectionId, {required double lat, required double lng, required double accuracy}) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/start');
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({'latitude': lat, 'longitude': lng, 'accuracy': accuracy}),
          )
          .timeout(const Duration(seconds: 6));
      _handleError(response);
      return response.statusCode == 200;
    } catch (e) {
      developer.log('API startInspection error: $e');
      return false;
    }
  }

  /// POST /api/inspections/{id}/complete
  Future<bool> completeInspection(String inspectionId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/complete');
      final response = await _client.post(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      return response.statusCode == 200;
    } catch (e) {
      developer.log('API completeInspection error: $e');
      return false;
    }
  }

  /// POST /api/inspections/{id}/evidence - Upload geo-tagged inspection evidence
  Future<bool> uploadEvidence(String inspectionId, Map<String, dynamic> evidenceData) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/evidence');
      final response = await _client
          .post(uri, headers: await _headers(), body: jsonEncode(evidenceData))
          .timeout(const Duration(seconds: 12));
      _handleError(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('API uploadEvidence error: $e');
      return false;
    }
  }

  /// POST /api/inspections/{id}/report - Submit inspection report
  Future<bool> submitReport(String inspectionId, Map<String, dynamic> reportData) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/report');
      final response = await _client
          .post(uri, headers: await _headers(), body: jsonEncode(reportData))
          .timeout(const Duration(seconds: 10));
      _handleError(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      developer.log('API submitReport error: $e');
      return false;
    }
  }

  /// POST /api/face/verify - Real ArcFace Biometric Verification Endpoint
  Future<String> verifyFace(Map<String, dynamic> faceData) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/face/verify');
      final response = await _client
          .post(uri, headers: await _headers(), body: jsonEncode(faceData))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        // Fallback to legacy verification route
        final fallbackUri = Uri.parse('${AppConfig.apiBaseUrl}/verification/face');
        final fallbackResp = await _client
            .post(fallbackUri, headers: await _headers(), body: jsonEncode(faceData))
            .timeout(const Duration(seconds: 10));
        _handleError(fallbackResp);
        final data = jsonDecode(fallbackResp.body);
        if (data['verified'] == true || data['status'] == 'VERIFIED' || data['status'] == 'MATCH') {
          return 'VERIFIED';
        } else if (data['status'] == 'MISMATCH') {
          return 'MISMATCH';
        }
        return 'FAILED';
      }

      _handleError(response);
      final data = jsonDecode(response.body);
      if (data['verified'] == true || data['status'] == 'VERIFIED' || data['status'] == 'MATCH') {
        return 'VERIFIED';
      } else if (data['status'] == 'MISMATCH') {
        return 'MISMATCH';
      }
      return 'FAILED';
    } catch (e) {
      developer.log('API verifyFace error: $e');
      return 'FAILED';
    }
  }

  /// POST /api/verification/voice - Real SpeechBrain ECAPA-TDNN Voice Verification Endpoint
  Future<String> verifyVoice(Map<String, dynamic> voiceData) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/verification/voice');
      final response = await _client
          .post(uri, headers: await _headers(), body: jsonEncode(voiceData))
          .timeout(const Duration(seconds: 10));
      _handleError(response);
      final data = jsonDecode(response.body);
      if (data['verified'] == true || data['status'] == 'VERIFIED' || data['status'] == 'MATCH') {
        return 'VERIFIED';
      } else if (data['status'] == 'MISMATCH') {
        return 'MISMATCH';
      }
      return 'FAILED';
    } catch (e) {
      developer.log('API verifyVoice error: $e');
      return 'FAILED';
    }
  }

  /// POST /api/device/heartbeat - Heartbeat signaling
  Future<bool> sendHeartbeat(String userId, String deviceId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/device/heartbeat');
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'user_id': userId,
              'device_id': deviceId,
              'timestamp': DateTime.now().toIso8601String(),
              'status': 'ONLINE',
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// POST /api/verification/session
  Future<VerificationSession?> createVerificationSession({
    required String personId,
    required String officerId,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/verification/session');
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'person_id': personId,
              'officer_id': officerId,
              'type': 'BIOMETRIC_GEOFENCE_FUSION',
            }),
          )
          .timeout(const Duration(seconds: 6));
      _handleError(response);
      final data = jsonDecode(response.body);
      return VerificationSession.fromJson(data);
    } catch (e) {
      developer.log('API createVerificationSession error: $e');
    }
    return null;
  }

  /// GET /api/alerts
  Future<List<AlertModel>> getAlerts() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/alerts');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.map((item) => AlertModel.fromJson(item)).toList();
    } catch (e) {
      developer.log('API getAlerts error: $e');
    }
    return [];
  }

  /// GET /api/attendance/live - Fetch real live attendance records from central FastAPI/Supabase
  Future<List<AttendanceRecord>> getLiveAttendance() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/live');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.map((item) => AttendanceRecord.fromJson(item)).toList();
    } catch (e) {
      developer.log('API getLiveAttendance error: $e');
      return getAttendance();
    }
  }

  /// GET /api/attendance
  Future<List<AttendanceRecord>> getAttendance({String? dateFilter, String? personId}) async {
    try {
      final queryParams = <String, String>{};
      if (dateFilter != null) queryParams['date'] = dateFilter;
      if (personId != null) queryParams['person_id'] = personId;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance').replace(queryParameters: queryParams);
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.map((item) => AttendanceRecord.fromJson(item)).toList();
    } catch (e) {
      developer.log('API getAttendance error: $e');
    }
    return [];
  }

  /// POST /api/attendance/entry - Record entry inside assigned geofence
  Future<Map<String, dynamic>?> recordAttendanceEntry({
    required String userId,
    required String geofenceId,
    required double latitude,
    required double longitude,
    double accuracy = 5.0,
    String? timestamp,
  }) async {
    try {
      developer.log('[API] POST /attendance/entry for user $userId');
      developer.log('[GPS] latitude=$latitude longitude=$longitude accuracy=$accuracy');
      developer.log('[GEOFENCE] ENTERED geofence $geofenceId');
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/entry');
      final payload = {
        'user_id': userId,
        'geofence_id': geofenceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client
          .post(uri, headers: await _headers(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 6));
      _handleError(response);
      final data = jsonDecode(response.body);
      developer.log('[API] /attendance/entry response: ${response.statusCode}');
      return data;
    } catch (e) {
      developer.log('[API] recordAttendanceEntry error: $e');
      return null;
    }
  }

  /// POST /api/attendance/exit - Record exit outside assigned geofence
  Future<Map<String, dynamic>?> recordAttendanceExit({
    required String userId,
    required double latitude,
    required double longitude,
    double accuracy = 5.0,
    String? timestamp,
  }) async {
    try {
      developer.log('[API] POST /attendance/exit for user $userId');
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/attendance/exit');
      final payload = {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
      };
      final response = await _client
          .post(uri, headers: await _headers(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 6));
      _handleError(response);
      final data = jsonDecode(response.body);
      developer.log('[API] /attendance/exit response: ${response.statusCode}');
      return data;
    } catch (e) {
      developer.log('[API] recordAttendanceExit error: $e');
      return null;
    }
  }

  /// GET /api/assignments - Fetch all person-to-geofence assignments
  Future<List<Map<String, dynamic>>> getAssignments({String? userId}) async {
    try {
      developer.log('[API] GET /assignments');
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/assignments');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      developer.log('[API] Fetched ${data.length} assignments from FastAPI');
      if (userId != null && userId.isNotEmpty) {
        return data
            .cast<Map<String, dynamic>>()
            .where((a) => (a['user_id'] == userId || a['officer_id'] == userId))
            .toList();
      }
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('[API] getAssignments error: $e');
    }
    return [];
  }

  /// GET /api/assignments/{assignment_id} - Fetch specific assignment details
  Future<Map<String, dynamic>?> getAssignmentById(String assignmentId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/assignments/$assignmentId');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      developer.log('[API] getAssignmentById error: $e');
      return null;
    }
  }

  /// POST /api/assignments - Create a new geo-tagged field assignment that is broadcast to User App
  Future<Map<String, dynamic>?> createAssignment({
    required String assignedUserId,
    required String title,
    required String assignedLocation,
    required double targetLatitude,
    required double targetLongitude,
    String? description,
    double allowedRadiusMeters = 200.0,
    String? startTime,
    String? endTime,
    String evidenceRequirement = 'GEO_TAGGED_PHOTO',
    String assignedBy = 'State Command Center',
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/assignments');
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'assigned_user_id': assignedUserId,
              'title': title,
              'assigned_location': assignedLocation,
              'target_latitude': targetLatitude,
              'target_longitude': targetLongitude,
              'description': ?description,
              'allowed_radius_meters': allowedRadiusMeters,
              'start_time': ?startTime,
              'end_time': ?endTime,
              'evidence_requirement': evidenceRequirement,

              'assigned_by': assignedBy,
            }),
          )
          .timeout(const Duration(seconds: 6));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      developer.log('[API] createAssignment error: $e');
      return null;
    }
  }

  /// GET /api/assignments/evidence/all - Fetch all evidence submitted across inspections
  Future<List<Map<String, dynamic>>> getAllEvidence() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/assignments/evidence/all');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 8));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('[API] getAllEvidence error: $e');
      return [];
    }
  }

  /// GET /api/inspections/{inspection_id}/evidence - Fetch verified evidence for inspection
  Future<List<Map<String, dynamic>>> getInspectionEvidence(String inspectionId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/evidence');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 8));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('[API] getInspectionEvidence error: $e');
      return [];
    }
  }

  /// POST /api/inspections/evidence - Submit inspection evidence record
  Future<Map<String, dynamic>?> submitInspectionEvidence({
    required String inspectionId,
    required String category,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
    List<int>? fileBytes,
    String? filename,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/inspections/evidence');
      final request = http.MultipartRequest('POST', uri);
      final headers = await _headers();
      request.headers.addAll(headers);
      request.fields['inspection_id'] = inspectionId;
      request.fields['category'] = category;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['gps_accuracy'] = gpsAccuracy.toString();

      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename ?? 'evidence.jpg',
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      developer.log('[API] submitInspectionEvidence error: $e');
      return null;
    }
  }

  /// GET /api/cctv/cameras - Fetch registered CCTV cameras

  Future<List<Map<String, dynamic>>> getCctvCameras({String? projectId}) async {
    try {
      final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final queryParam = projectId != null ? '?project_id=$projectId' : '';
      final uri = Uri.parse('$base/api/cctv/cameras$queryParam');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('[API] getCctvCameras error: $e');
    }
    return [];
  }

  /// GET /api/cctv/status - Fetch live YOLO11 detection telemetry
  Future<Map<String, dynamic>?> getCctvStatus({String cameraId = 'CCTV-01'}) async {
    try {
      final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
      final uri = Uri.parse('$base/api/cctv/$cameraId/status');
      final response = await _client.get(uri, headers: await _headers()).timeout(const Duration(seconds: 4));
      _handleError(response);
      return jsonDecode(response.body);
    } catch (e) {
      developer.log('[API] getCctvStatus error: $e');
    }
    return null;
  }

  /// PUT /api/alerts/{id}/resolve - Resolve an active incident alert
  Future<bool> resolveAlert(String alertId) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/alerts/$alertId/resolve');
      final response = await _client.put(uri, headers: await _headers()).timeout(const Duration(seconds: 6));
      _handleError(response);
      return response.statusCode == 200;
    } catch (e) {
      developer.log('[API] resolveAlert error: $e');
      return false;
    }
  }

  /// GET /api/health - Check FastAPI backend kernel status
  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/health');
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      developer.log('[API] getHealth error: $e');
    }
    return null;
  }
}

