import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/app_config.dart';

enum RealtimeConnectionStatus {
  connected,
  reconnecting,
  offline,
}

/// Real-time WebSocket Service for bidirectional communication with the FastAPI Backend.
/// Synchronizes live status across Government Mobile App and Government Web Dashboard.
class RealtimeService {
  WebSocketChannel? _channel;
  RealtimeConnectionStatus _status = RealtimeConnectionStatus.offline;
  final _statusController = StreamController<RealtimeConnectionStatus>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Timer? _reconnectTimer;
  bool _isDisposed = false;
  String? _authToken;
  int _reconnectAttempts = 0;

  RealtimeConnectionStatus get status => _status;
  Stream<RealtimeConnectionStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  WebSocketChannel? _locationChannel;

  void initialize({String? token}) {
    _authToken = token;
    _connect();
  }

  /// Connect to user-specific location stream /ws/location/{user_id}
  void connectUserLocationStream(String userId) {
    if (_isDisposed) return;
    try {
      _locationChannel?.sink.close();
      final wsUrl = AppConfig.wsLocationUrl(userId);
      final uri = Uri.parse(wsUrl);
      _locationChannel = WebSocketChannel.connect(uri);
      developer.log('[WS] Connected to user location stream: $wsUrl');

      _locationChannel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (e) {
          developer.log('[WS] User location stream error: $e');
        },
        onDone: () {
          developer.log('[WS] User location stream closed');
        },
      );
    } catch (e) {
      developer.log('[WS] Failed to connect user location stream: $e');
    }
  }

  int _candidateIndex = 0;

  List<String> get _candidateWsUrls {
    final urls = <String>[];
    urls.add(AppConfig.wsLiveUrl);
    final fallbackCandidates = [
      'ws://127.0.0.1:8000/ws/live',
      'ws://10.77.108.231:8000/ws/live',
      'ws://10.162.172.231:8000/ws/live',
      'ws://10.0.2.2:8000/ws/live',
      'ws://localhost:8000/ws/live',
    ];
    for (final c in fallbackCandidates) {
      if (!urls.contains(c)) {
        urls.add(c);
      }
    }
    return urls;
  }

  void _connect() {
    if (_isDisposed) return;
    _updateStatus(RealtimeConnectionStatus.reconnecting);

    final candidateList = _candidateWsUrls;
    final currentTarget = candidateList[_candidateIndex % candidateList.length];
    final wsUrl = '$currentTarget?token=${_authToken ?? ''}';

    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      // Handle connection handshake safely to avoid unhandled zone exceptions
      _channel!.ready.then((_) {
        _reconnectAttempts = 0;
        _updateStatus(RealtimeConnectionStatus.connected);

        // Synchronize resolved base URL so REST API matches the connected backend host
        final httpBase = currentTarget
            .replaceFirst('ws://', 'http://')
            .replaceFirst('wss://', 'https://')
            .replaceFirst('/ws/live', '');
        AppConfig.setResolvedBaseUrl('$httpBase/api');
        developer.log('WebSocket successfully connected to $currentTarget (Synced API: $httpBase/api)');
      }).catchError((error) {
        developer.log('WebSocket handshake error for $currentTarget: $error');
        _handleDisconnect();
      });

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          developer.log('WebSocket stream error: $error');
          _handleDisconnect();
        },
        onDone: () {
          developer.log('WebSocket stream closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      developer.log('Failed to initiate WebSocket connection: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message.toString());
      final String event = data['event'] ?? data['type'] ?? '';
      developer.log('Realtime Event Received: $event -> $data');
      _eventController.add(data);
    } catch (e) {
      developer.log('Failed to parse WebSocket frame: $e');
    }
  }

  void _handleDisconnect() {
    _updateStatus(RealtimeConnectionStatus.offline);
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    if (!_isDisposed) {
      _reconnectTimer?.cancel();
      _reconnectAttempts++;
      // Rotate to next candidate host on failure
      _candidateIndex++;
      final backoffSeconds = min(15, max(2, pow(2, min(_reconnectAttempts, 4)).toInt()));
      developer.log('Scheduling WebSocket reconnection to next candidate in ${backoffSeconds}s (Attempt #$_reconnectAttempts)...');

      _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
        _connect();
      });
    }
  }

  void sendEvent(String event, Map<String, dynamic> payload) {
    if (_status == RealtimeConnectionStatus.connected && _channel != null) {
      final Map<String, dynamic> frame = {
        'event': event,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _channel!.sink.add(jsonEncode(frame));
      developer.log('Realtime Event Sent: $event');
    } else {
      developer.log('Cannot send realtime event $event: WebSocket offline');
    }
  }

  void _updateStatus(RealtimeConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _statusController.close();
    _eventController.close();
  }
}
