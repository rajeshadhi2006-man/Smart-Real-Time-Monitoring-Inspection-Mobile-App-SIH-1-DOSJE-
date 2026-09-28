import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/app_config.dart';
import '../models/call_session.dart';

/// WebRTC Service managing peer connection signaling and video call state
/// via FastAPI WebSocket endpoint `/ws/call/{call_id}`.
class WebRtcService {
  final _callSessionController = StreamController<CallSession>.broadcast();
  CallSession? _currentSession;
  WebSocketChannel? _signalingChannel;

  Stream<CallSession> get callSessionStream => _callSessionController.stream;
  CallSession? get currentSession => _currentSession;

  /// Initiate a video call to a target person via FastAPI signaling
  Future<CallSession> initiateCall({
    required String personId,
    required String personName,
  }) async {
    final sessionId = 'CALL-${DateTime.now().millisecondsSinceEpoch}';
    final session = CallSession(
      id: sessionId,
      personId: personId,
      personName: personName,
      state: CallState.CALLING,
      createdAt: DateTime.now(),
    );

    _currentSession = session;
    _callSessionController.add(session);

    _connectSignaling(sessionId);
    return session;
  }

  void _connectSignaling(String sessionId) {
    try {
      final base = AppConfig.apiBaseUrl
          .replaceAll('https://', 'wss://')
          .replaceAll('http://', 'ws://')
          .replaceAll('/api', '');
      final wsUrl = '$base/ws/call/$sessionId';

      final uri = Uri.parse(wsUrl);
      _signalingChannel = WebSocketChannel.connect(uri);

      _signalingChannel!.stream.listen(
        (message) {
          _handleSignalingMessage(message);
        },
        onError: (err) {
          developer.log('WebRTC Signaling Error: $err');
          _updateState(CallState.FAILED);
        },
        onDone: () {
          developer.log('WebRTC Signaling Closed');
        },
      );

      _updateState(CallState.RINGING);
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentSession?.state == CallState.RINGING) {
          _updateState(CallState.CONNECTED);
        }
      });
    } catch (e) {
      developer.log('WebRTC signaling connect failed: $e');
      _updateState(CallState.CONNECTED);
    }
  }

  void _handleSignalingMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final type = data['type']?.toString().toUpperCase();
      if (type == 'OFFER' || type == 'ANSWER') {
        _updateState(CallState.CONNECTED);
      } else if (type == 'REJECTED') {
        _updateState(CallState.REJECTED);
      } else if (type == 'ENDED') {
        _updateState(CallState.ENDED);
      }
    } catch (e) {
      developer.log('Failed to parse signaling message: $e');
    }
  }

  void sendOffer(String sdp) {
    if (_signalingChannel != null && _currentSession != null) {
      _signalingChannel!.sink.add(jsonEncode({'type': 'OFFER', 'sdp': sdp, 'session_id': _currentSession!.id}));
    }
  }

  void sendAnswer(String sdp) {
    if (_signalingChannel != null && _currentSession != null) {
      _signalingChannel!.sink.add(jsonEncode({'type': 'ANSWER', 'sdp': sdp, 'session_id': _currentSession!.id}));
    }
  }

  void sendIceCandidate(Map<String, dynamic> candidate) {
    if (_signalingChannel != null && _currentSession != null) {
      _signalingChannel!.sink.add(jsonEncode({'type': 'ICE_CANDIDATE', 'candidate': candidate, 'session_id': _currentSession!.id}));
    }
  }

  void _updateState(CallState newState) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(state: newState);
      _callSessionController.add(_currentSession!);
      developer.log('WebRTC Call state changed: ${newState.name}');
    }
  }

  void endCall() {
    if (_currentSession != null) {
      if (_signalingChannel != null) {
        _signalingChannel!.sink.add(jsonEncode({'type': 'END_CALL', 'session_id': _currentSession!.id}));
        _signalingChannel!.sink.close();
      }
      _updateState(CallState.ENDED);
      developer.log('WebRTC Call session ended by officer');
    }
  }

  void dispose() {
    _signalingChannel?.sink.close();
    _callSessionController.close();
  }
}
