import 'app_config.dart';

/// Centralized API Endpoints Configuration
/// All endpoints are derived dynamically from AppConfig.serverRootUrl.
class ApiConfig {
  const ApiConfig._();

  /// Root URL of the backend (e.g. http://10.0.2.2:8000 or https://api.domain.gov.in)
  static String get baseUrl => AppConfig.serverRootUrl;

  /// Update backend host at runtime (for physical device local LAN testing)
  static Future<void> setCustomHost(String host, {int port = 8000}) async {
    if (host.startsWith('http://') || host.startsWith('https://')) {
      await AppConfig.setRuntimeBaseUrl(host);
    } else {
      await AppConfig.setRuntimeBaseUrl('http://$host:$port');
    }
  }

  static String get customHost => AppConfig.serverRootUrl;
  static int get port => 8000;

  static String get wsUrl => AppConfig.wsUrl;

  // 1. Authentication
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get meUrl => '$baseUrl/api/auth/me';
  static String get logoutUrl => '$baseUrl/api/auth/logout';

  // 2. Assignments & Inspections
  static String get assignmentsUrl => '$baseUrl/api/assignments';
  static String get myAssignmentsUrl => '$baseUrl/api/assignments/my-assignments';
  static String userAssignmentsUrl(String userId) => '$baseUrl/api/assignments?user_id=$userId';
  static String get inspectionsUrl => '$baseUrl/api/inspections';
  static String get myInspectionsUrl => '$baseUrl/api/inspections/my-inspections';
  static String get evidenceUploadUrl => '$baseUrl/api/inspections/evidence';

  // 3. Attendance
  static String get attendanceUrl => '$baseUrl/api/attendance';
  static String get attendanceEntryUrl => '$baseUrl/api/attendance/entry';
  static String get attendanceLiveUrl => '$baseUrl/api/attendance/live';

  // 4. Geofences
  static String get geofencesUrl => '$baseUrl/api/geofences';
  static String assignedGeofenceUrl(String userId) => '$baseUrl/api/geofences/assigned/$userId';

  // 5. Location Telemetry & Geofence Events
  static String get locationUpdateUrl => '$baseUrl/api/location/update';
  static String get geofenceEntryUrl => '$baseUrl/api/location/geofence/entry';
  static String get geofenceExitUrl => '$baseUrl/api/location/geofence/exit';

  // 6. Face Biometric (ArcFace neural engine)
  static String get faceEnrollUrl => '$baseUrl/api/face/enroll';
  static String get faceVerifyUrl => '$baseUrl/api/face/verify';
  static String get faceStatusUrl => '$baseUrl/api/face/status';

  // 7. Voice Biometric (SpeechBrain ECAPA-TDNN)
  static String get voiceEnrollUrl => '$baseUrl/api/verification/voice/enroll';
  static String get voiceVerifyUrl => '$baseUrl/api/verification/voice';
  static String get voiceStatusUrl => '$baseUrl/api/verification/voice/status';
  static String get voiceChallengeUrl => '$baseUrl/api/verification/voice/challenge';

  // 8. Multi-modal Verification
  static String get verificationFaceUrl => '$baseUrl/api/verification/face';
  static String get verificationVoiceUrl => '$baseUrl/api/verification/voice';
  static String get verificationFuseUrl => '$baseUrl/api/verification/fuse';

  // 9. Alerts & Notifications
  static String get alertsUrl => '$baseUrl/api/alerts';
  static String get myAlertsUrl => '$baseUrl/api/alerts/my-alerts';

  // 10. WebSockets & Health
  static String get healthUrl => '$baseUrl/api/health';
  static String userWsUrl(String userId) => AppConfig.wsLocationUrl(userId);
}
