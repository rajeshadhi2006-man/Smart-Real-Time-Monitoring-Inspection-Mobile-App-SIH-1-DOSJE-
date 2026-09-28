import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/api_config.dart';

enum WsConnectionStatus { connecting, connected, offline, reconnecting }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _eventController;
  final StreamController<WsConnectionStatus> _statusController = StreamController<WsConnectionStatus>.broadcast();

  bool _isConnected = false;
  bool _shouldReconnect = false;
  String? _currentUserId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  Stream<Map<String, dynamic>>? get eventStream => _eventController?.stream;
  Stream<WsConnectionStatus> get statusStream => _statusController.stream;
  bool get isConnected => _isConnected;

  void connect(String userId) {
    _currentUserId = userId;
    _shouldReconnect = true;
    _eventController ??= StreamController<Map<String, dynamic>>.broadcast();
    _establishConnection();
  }

  void _establishConnection() {
    if (_currentUserId == null) return;
    _reconnectTimer?.cancel();

    try {
      _statusController.add(_reconnectAttempts > 0 ? WsConnectionStatus.reconnecting : WsConnectionStatus.connecting);
      final wsEndpoint = ApiConfig.userWsUrl(_currentUserId!);
      final url = Uri.parse(wsEndpoint);

      _channel = WebSocketChannel.connect(url);
      _isConnected = true;
      _reconnectAttempts = 0;
      _statusController.add(WsConnectionStatus.connected);

      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            if (data is Map<String, dynamic>) {
              _eventController?.add(data);
            }
          } catch (_) {}
        },
        onError: (error) {
          _handleDisconnection();
        },
        onDone: () {
          _handleDisconnection();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _channel = null;
    _statusController.add(WsConnectionStatus.offline);

    if (_shouldReconnect && _currentUserId != null) {
      _reconnectAttempts++;
      // Backoff: 2s, 4s, 8s, capped at 15s
      final delaySeconds = (_reconnectAttempts * 2).clamp(2, 15);
      _statusController.add(WsConnectionStatus.reconnecting);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
        if (_shouldReconnect) {
          _establishConnection();
        }
      });
    }
  }

  void sendLocationUpdate({
    required String userId,
    required double latitude,
    required double longitude,
    required double accuracy,
    bool isInsideGeofence = false,
  }) {
    if (_channel != null && _isConnected) {
      try {
        final payload = {
          'type': 'LOCATION_UPDATE',
          'data': {
            'user_id': userId,
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
            'is_inside_geofence': isInsideGeofence,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }
        };
        _channel?.sink.add(jsonEncode(payload));
      } catch (_) {}
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _statusController.add(WsConnectionStatus.offline);
  }
}

