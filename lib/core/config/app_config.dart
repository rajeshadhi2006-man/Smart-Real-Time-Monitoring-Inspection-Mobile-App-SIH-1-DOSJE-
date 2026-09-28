import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central application configuration handling API endpoints, environments, and feature flags.
/// Supports zero-code switching between Development, Staging, and Production via:
/// `--dart-define=API_BASE_URL=https://api.yourdomain.gov.in/api`
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
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWtwd3diZGV4d2tha3VxcGF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2MDk4MDAsImV4cCI6MjEwNDE4NTgwMH0.ilxOvgsxXQoD3Rh6pZgmfiEMET5u3RtS-B0W_kOEhLU',
  );

  static const bool enableMockLocationDetection = bool.fromEnvironment(
    'ENABLE_MOCK_LOCATION_DETECTION',
    defaultValue: true,
  );

  // Runtime overrides for local device testing without rebuild
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _storageKey = 'custom_api_base_url';
  
  /// Current Active PC Wi-Fi IP
  static const String localLanIp = '10.77.108.231';
  /// Phone Hotspot Subnet Fallback IP
  static const String hotspotLanIp = '10.35.253.231';
  
  static String? _runtimeBaseUrl;

  static String _cleanUrl(String url) {
    String clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.endsWith('/api')) {
      clean = '$clean/api';
    }
    return clean;
  }

  /// Primary Local Wi-Fi Endpoint
  static const String localWifiUrl = 'http://10.77.108.231:8000/api';

  /// Active Cloud Tunnel Endpoint (Accessible anywhere over 4G/5G mobile data)
  static const String activeCloudUrl = 'https://reg-lucky-hire-retrieve.trycloudflare.com/api';

  static const String usbLoopbackUrl = 'http://127.0.0.1:8000/api';

  /// Ordered list of candidate endpoints for seamless connection (USB prioritized for instant real-time)
  static List<String> get candidateEndpoints => [
    usbLoopbackUrl,                  // 1. Direct USB Cable Loopback (0ms latency, Instant Real-Time)
    if (_runtimeBaseUrl != null && _runtimeBaseUrl!.isNotEmpty && _runtimeBaseUrl != usbLoopbackUrl) _runtimeBaseUrl!,
    localWifiUrl,                    // 2. Current High-Speed Wi-Fi LAN (PC IP: 10.77.108.231)
    activeCloudUrl,                  // 3. High-speed Cloudflare Tunnel (Works on Airtel 4G/5G mobile data)
    'http://10.35.253.231:8000/api', // 4. Mobile Hotspot Subnet
    'http://192.168.43.1:8000/api',   // 5. Android Hotspot Default Gateway
    'http://10.0.2.2:8000/api',      // 6. Android Emulator
  ];

  /// Initialize persistent runtime configuration on startup with auto-discovery
  static Future<void> init() async {
    try {
      final savedUrl = await _storage.read(key: _storageKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        // Purge dead tunnel hostnames that cause host lookup failure loops
        if (savedUrl.contains('mall-inline-clark-textiles') ||
            savedUrl.contains('sih-mosje-gateway.loca.lt')) {
          await _storage.delete(key: _storageKey);
          _runtimeBaseUrl = null;
        } else {
          _runtimeBaseUrl = _cleanUrl(savedUrl.trim());
        }
      }
    } catch (_) {}

    // Auto-probe in background if on physical device to guarantee zero-disconnects
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      autoDiscoverWorkingEndpoint().catchError((_) => null);
    }
  }

  /// Automatically tests candidate endpoints and binds to the first working one
  static Future<String?> autoDiscoverWorkingEndpoint() async {
    final candidates = candidateEndpoints;
    for (final candidate in candidates) {
      final isWorking = await probeEndpoint(candidate);
      if (isWorking) {
        debugPrint("[AppConfig] Auto-discovered reachable backend: $candidate");
        await setRuntimeBaseUrl(candidate);
        return candidate;
      }
    }
    return null;
  }

  /// Probe with 4-second timeout and TLS certificate tolerance
  static Future<bool> probeEndpoint(String baseUrl) async {
    try {
      final clean = _cleanUrl(baseUrl);
      final testUri = Uri.parse('$clean/face/status?user_id=health_ping');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4)
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final request = await client.getUrl(testUri).timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(const Duration(seconds: 4));
      client.close(force: true);
      return response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setRuntimeBaseUrl(String url) async {
    final clean = _cleanUrl(url);
    _runtimeBaseUrl = clean;
    try {
      await _storage.write(key: _storageKey, value: clean);
    } catch (_) {}
  }

  static Future<void> clearRuntimeBaseUrl() async {
    _runtimeBaseUrl = null;
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }

  /// Primary centralized API Base URL
  static String get apiBaseUrl {
    if (_runtimeBaseUrl != null && _runtimeBaseUrl!.isNotEmpty) {
      return _runtimeBaseUrl!;
    }

    const envDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envDefine.isNotEmpty) {
      return _cleanUrl(envDefine);
    }

    // Default development platform addresses
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return localWifiUrl;
    }
    return 'http://localhost:8000/api';
  }

  /// Root server host URL without trailing /api
  static String get serverRootUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  /// Base WebSocket server URL
  static String get wsUrl {
    final root = serverRootUrl;
    return root.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  }

  /// Live WebSocket stream for real-time geofence, telemetry & alert events
  static String get wsLiveUrl {
    return '$wsUrl/ws/live';
  }

  /// Location WebSocket stream for user-specific real-time telemetry
  static String wsLocationUrl(String userId) {
    return '$wsUrl/ws/location/$userId';
  }

  /// Geofence radius tolerance around registered project coordinates (meters)
  static const double maxGeofenceRadiusMeters = 100.0;

  /// Minimum required GPS accuracy before allowing check-in (meters)
  static const double minGpsAccuracyMeters = 25.0;

  static const String tamperEvidenceSalt = String.fromEnvironment(
    'TAMPER_EVIDENCE_SALT',
    defaultValue: 'mosje_sih_secure_salt_2026',
  );
}
