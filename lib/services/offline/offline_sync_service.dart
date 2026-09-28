import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../api_service.dart';

enum OfflineActionType {
  faceEnrollment,
  attendanceCheckIn,
  verificationLog,
}

class OfflineSyncItem {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  OfflineSyncItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OfflineSyncItem.fromJson(Map<String, dynamic> json) => OfflineSyncItem(
    id: json['id'] as String,
    type: OfflineActionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => OfflineActionType.attendanceCheckIn,
    ),
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: (json['retryCount'] as int?) ?? 0,
  );
}

/// Sovereign Autonomous Offline Synchronization Engine
/// Enables 100% independent functionality when disconnected from server/cellular.
/// Store-and-forward queue automatically syncs when connection returns.
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  static const String _queueKey = 'offline_sync_queue_v1';

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicSyncTimer;
  bool _isInitialized = false;

  OfflineSyncService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load initial queue count
    await _updatePendingCount();

    // Listen to device network state
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        // Double check with actual server reachability
        _verifyOnlineAndSync();
      } else {
        isOnlineNotifier.value = false;
      }
    });

    // Periodic heartbeat to auto-discover connection & drain queue
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _verifyOnlineAndSync();
    });

    // Immediate initial sync check
    _verifyOnlineAndSync();
  }

  Future<void> _verifyOnlineAndSync() async {
    try {
      final workingUrl = await AppConfig.autoDiscoverWorkingEndpoint();
      final online = workingUrl != null;
      isOnlineNotifier.value = online;

      if (online && pendingCountNotifier.value > 0 && !isSyncingNotifier.value) {
        await syncPendingQueue();
      }
    } catch (_) {
      isOnlineNotifier.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Enqueue Operations (Instant Local Commit)
  // ─────────────────────────────────────────────────────────────────────

  /// Enqueue an offline face enrollment for background server synchronization
  Future<void> queueFaceEnrollment({
    required String userId,
    required String officerId,
    required String fullName,
    required String imageBase64,
  }) async {
    final item = OfflineSyncItem(
      id: 'enroll_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      type: OfflineActionType.faceEnrollment,
      payload: {
        'user_id': userId,
        'officer_id': officerId,
        'full_name': fullName,
        'image_base64': imageBase64,
        'enrolled_offline_at': DateTime.now().toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
    await _addItem(item);
    debugPrint("[OfflineSync] Face enrollment queued for background sync: user=$userId");
  }

  /// Enqueue an offline attendance check-in
  Future<void> queueAttendanceCheckIn({
    required String userId,
    required String officerId,
    required double latitude,
    required double longitude,
    required bool geofenceVerified,
    required bool faceVerified,
    required bool voiceVerified,
    required String geofenceId,
  }) async {
    final item = OfflineSyncItem(
      id: 'att_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      type: OfflineActionType.attendanceCheckIn,
      payload: {
        'user_id': userId,
        'officer_id': officerId,
        'latitude': latitude,
        'longitude': longitude,
        'geofence_verified': geofenceVerified,
        'face_verified': faceVerified,
        'voice_verified': voiceVerified,
        'geofence_id': geofenceId,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'OFFLINE_SOVEREIGN_MODE',
      },
      createdAt: DateTime.now(),
    );
    await _addItem(item);
    debugPrint("[OfflineSync] Attendance check-in queued for user=$userId");
  }

  /// Enqueue a biometric verification log
  Future<void> queueVerificationLog({
    required String userId,
    required String officerId,
    required String method,
    required String status,
    required double confidence,
  }) async {
    final item = OfflineSyncItem(
      id: 'verif_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      type: OfflineActionType.verificationLog,
      payload: {
        'user_id': userId,
        'officer_id': officerId,
        'method': method,
        'status': status,
        'confidence': confidence,
        'timestamp': DateTime.now().toIso8601String(),
        'mode': 'OFFLINE_STANDALONE',
      },
      createdAt: DateTime.now(),
    );
    await _addItem(item);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Sync Engine (Drain Queue)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> syncPendingQueue() async {
    if (isSyncingNotifier.value) return;
    isSyncingNotifier.value = true;

    try {
      final queue = await _loadQueue();
      if (queue.isEmpty) {
        pendingCountNotifier.value = 0;
        return;
      }

      debugPrint("[OfflineSync] Starting sync of ${queue.length} pending offline actions...");
      final remaining = <OfflineSyncItem>[];

      for (final item in queue) {
        bool success = false;
        try {
          switch (item.type) {
            case OfflineActionType.faceEnrollment:
              success = await _syncFaceEnrollment(item.payload);
              break;
            case OfflineActionType.attendanceCheckIn:
              success = await _syncAttendanceCheckIn(item.payload);
              break;
            case OfflineActionType.verificationLog:
              success = await _syncVerificationLog(item.payload);
              break;
          }
        } catch (e) {
          debugPrint("[OfflineSync] Error syncing item ${item.id}: $e");
          success = false;
        }

        if (!success) {
          item.retryCount++;
          if (item.retryCount < 10) {
            remaining.add(item);
          } else {
            debugPrint("[OfflineSync] Dropping item ${item.id} after 10 failed retries.");
          }
        } else {
          debugPrint("[OfflineSync] Successfully synced ${item.id}");
        }
      }

      await _saveQueue(remaining);
      pendingCountNotifier.value = remaining.length;
      isOnlineNotifier.value = true;
    } catch (e) {
      debugPrint("[OfflineSync] Critical sync error: $e");
    } finally {
      isSyncingNotifier.value = false;
    }
  }

  Future<bool> _syncFaceEnrollment(Map<String, dynamic> payload) async {
    try {
      final resp = await _apiService.post(
        ApiConfig.faceEnrollUrl,
        data: {
          'user_id': payload['user_id'],
          'officer_id': payload['officer_id'],
          'full_name': payload['full_name'],
          'image_base64': payload['image_base64'],
        },
      );
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      // If already enrolled or status returned, treat as success
      if (e.toString().contains('already') || e.toString().contains('400')) {
        return true;
      }
      return false;
    }
  }

  Future<bool> _syncAttendanceCheckIn(Map<String, dynamic> payload) async {
    try {
      final resp = await _apiService.post(
        ApiConfig.attendanceEntryUrl,
        data: payload,
      );
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      if (e.toString().contains('already checked in')) return true;
      return false;
    }
  }

  Future<bool> _syncVerificationLog(Map<String, dynamic> payload) async {
    try {
      final resp = await _apiService.post(
        '${ApiConfig.baseUrl}/api/verification/log',
        data: payload,
      );
      return resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 404;
    } catch (_) {
      return true; // Non-critical log, don't hold queue
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Internal Queue Persistence
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _addItem(OfflineSyncItem item) async {
    final queue = await _loadQueue();
    // Avoid duplicate queue items for same user and type
    queue.removeWhere((i) => i.type == item.type && i.payload['user_id'] == item.payload['user_id']);
    queue.add(item);
    await _saveQueue(queue);
    pendingCountNotifier.value = queue.length;

    // Trigger immediate background sync attempt if connection is already healthy
    if (isOnlineNotifier.value) {
      syncPendingQueue().catchError((_) => null);
    }
  }

  Future<List<OfflineSyncItem>> _loadQueue() async {
    try {
      final raw = await _storage.read(key: _queueKey);
      if (raw == null || raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => OfflineSyncItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      debugPrint("[OfflineSync] Error loading queue: $e");
      return [];
    }
  }

  Future<void> _saveQueue(List<OfflineSyncItem> queue) async {
    try {
      if (queue.isEmpty) {
        await _storage.delete(key: _queueKey);
      } else {
        final raw = jsonEncode(queue.map((e) => e.toJson()).toList());
        await _storage.write(key: _queueKey, value: raw);
      }
    } catch (e) {
      debugPrint("[OfflineSync] Error saving queue: $e");
    }
  }

  Future<void> _updatePendingCount() async {
    final queue = await _loadQueue();
    pendingCountNotifier.value = queue.length;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicSyncTimer?.cancel();
  }
}
