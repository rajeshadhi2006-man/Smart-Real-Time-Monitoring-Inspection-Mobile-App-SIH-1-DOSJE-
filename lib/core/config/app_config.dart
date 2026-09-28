import 'package:flutter/foundation.dart';

enum EnvironmentTarget { emulator, physicalDevice, webLocal }

/// Application configuration handling environment values and feature flags.
class AppConfig {
  const AppConfig._();

  static const String appName = 'MoSJE Nirikshan';
  static const String appFullTitle =
      'Smart Real-Time Monitoring & Inspection System';
  static const String departmentName =
      'Ministry of Social Justice and Empowerment';
  static const String portalUrl = 'https://socialjustice.gov.in';

  // Environment defines (configurable via --dart-define)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ctmkpwwbdexwkakuqpat.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWtwd3diZGV4d2tha3VxcGF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg6MDk4MDAsImV4cCI6MjEwNDE4NTgwMH0.ilxOvgsxXQoD3Rh6pZgmfiEMET5u3RtS-B0W_kOEhLU',
  );

  // Target Backend Hosts
  static const String androidEmulatorHost = 'http://10.0.2.2:8000';
  static const String physicalDeviceHost = String.fromEnvironment(
    'PHYSICAL_DEVICE_HOST',
    defaultValue: 'http://10.77.108.231:8000',
  );
  static const String webLocalhostHost = 'http://localhost:8000';

  static const String targetHostOverride = String.fromEnvironment(
    'TARGET_HOST',
    defaultValue: '',
  );

  static String? _resolvedBaseUrl;

  /// Sets or updates the active discovered backend base URL
  static void setResolvedBaseUrl(String url) {
    _resolvedBaseUrl = url.endsWith('/api') ? url : '$url/api';
  }

  /// Dynamically computes the active FastAPI REST API base URL
  static String get apiBaseUrl {
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) {
      return _resolvedBaseUrl!;
    }

    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override.endsWith('/api') ? override : '$override/api';
    }

    const backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (backendUrl.isNotEmpty) {
      return backendUrl.endsWith('/api') ? backendUrl : '$backendUrl/api';
    }

    if (targetHostOverride == 'emulator') return '$androidEmulatorHost/api';
    if (targetHostOverride == 'physical') return '$physicalDeviceHost/api';
    if (targetHostOverride == 'localhost' || targetHostOverride == 'web') return '$webLocalhostHost/api';

    if (kIsWeb) {
      return '$webLocalhostHost/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 127.0.0.1 directly routes over USB cable when adb reverse tcp:8000 tcp:8000 is active
      return 'http://127.0.0.1:8000/api';
    }
    return '$webLocalhostHost/api';
  }

  /// Base host for serving static files, images, and evidence media
  static String get mediaBaseUrl {
    return apiBaseUrl.replaceAll('/api', '');
  }

  /// Live WebSocket stream for real-time geofence, telemetry & alert events
  static String get wsLiveUrl {
    final base = apiBaseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://').replaceAll('/api', '');
    return '$base/ws/live';
  }

  /// Location WebSocket stream for user-specific real-time telemetry
  static String wsLocationUrl(String userId) {
    final base = apiBaseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://').replaceAll('/api', '');
    return '$base/ws/location/$userId';
  }

  static const bool useMockFallback = bool.fromEnvironment(
    'USE_MOCK_FALLBACK',
    defaultValue: false,
  );

  static const bool enableMockLocationDetection = bool.fromEnvironment(
    'ENABLE_MOCK_LOCATION_DETECTION',
    defaultValue: true,
  );

  /// Geofence radius tolerance around registered project coordinates (meters)
  static const double maxGeofenceRadiusMeters = 100.0;

  /// Minimum required GPS accuracy before allowing check-in (meters)
  static const double minGpsAccuracyMeters = 25.0;

  static const String tamperEvidenceSalt = String.fromEnvironment(
    'TAMPER_EVIDENCE_SALT',
    defaultValue: 'mosje_sih_secure_salt_2026',
  );
}
