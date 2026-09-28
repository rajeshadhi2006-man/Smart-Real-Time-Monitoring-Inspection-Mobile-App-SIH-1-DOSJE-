import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';
import '../../../../providers/auth_provider.dart';

class CctvLiveScreen extends ConsumerStatefulWidget {
  final String? initialCameraId;

  const CctvLiveScreen({super.key, this.initialCameraId});

  @override
  ConsumerState<CctvLiveScreen> createState() => _CctvLiveScreenState();
}

class _CctvLiveScreenState extends ConsumerState<CctvLiveScreen> {
  WebSocketChannel? _wsChannel;
  Timer? _pollingTimer;

  String _selectedCameraId = 'CCTV-01';
  String _streamStatus = 'CONNECTING';
  double _fps = 0.0;
  double _latencyMs = 0.0;
  int _personCount = 0;
  int _vehicleCount = 0;
  List<dynamic> _detections = [];
  List<Map<String, dynamic>> _registeredCameras = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCameraId != null && widget.initialCameraId!.isNotEmpty) {
      _selectedCameraId = widget.initialCameraId!;
    }
    _loadCameras();
    _connectCctvWebSocket();
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCameras() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final list = await apiService.getCctvCameras();
      if (mounted) {
        setState(() {
          _registeredCameras = list;
        });
      }
    } catch (_) {}
  }

  void _connectCctvWebSocket() {
    try {
      final base = AppConfig.apiBaseUrl
          .replaceAll('http://', 'ws://')
          .replaceAll('https://', 'wss://')
          .replaceAll('/api', '');
      final wsUrl = '$base/ws/cctv/$_selectedCameraId';

      _wsChannel?.sink.close();
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            if (mounted) {
              setState(() {
                _streamStatus = (data['status'] ?? 'ONLINE').toString().toUpperCase();
                _fps = (data['fps'] as num?)?.toDouble() ?? 0.0;
                _latencyMs = (data['latency_ms'] as num?)?.toDouble() ?? 0.0;
                _personCount = (data['person_count'] as num?)?.toInt() ?? 0;
                _vehicleCount = (data['vehicle_count'] as num?)?.toInt() ?? 0;
                _detections = (data['detections'] as List?) ?? [];
              });
            }
          } catch (_) {}
        },
        onError: (_) {
          if (mounted) setState(() => _streamStatus = 'OFFLINE');
        },
        onDone: () {
          if (mounted) setState(() => _streamStatus = 'DISCONNECTED');
        },
      );
    } catch (e) {
      developer.log('CCTV WebSocket connection error: $e');
    }
  }

  String get _mjpegStreamUrl {
    final base = AppConfig.apiBaseUrl.replaceAll('/api', '');
    return '$base/api/cctv/$_selectedCameraId/stream';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'National CCTV & YOLO11 Hub',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'MoSJE Command Stream: $_selectedCameraId',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _streamStatus == 'ONLINE'
                  ? const Color(0x3322C55E)
                  : const Color(0x33EF4444),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _streamStatus == 'ONLINE' ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _streamStatus == 'ONLINE' ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _streamStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _streamStatus == 'ONLINE' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadCameras();
          _connectCctvWebSocket();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Video Frame Container
              Container(
                width: double.infinity,
                height: 230,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _mjpegStreamUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off, color: Colors.white38, size: 42),
                              const SizedBox(height: 8),
                              const Text(
                                'CCTV Feed Connecting / Ingest Active',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _mjpegStreamUrl,
                                style: const TextStyle(color: Colors.white30, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // OSD Overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOLO11n • ${_fps.toStringAsFixed(1)} FPS • ${_latencyMs.toStringAsFixed(0)}ms',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE FEED',
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detection Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.people,
                      title: 'Persons',
                      value: '$_personCount',
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.directions_car,
                      title: 'Vehicles',
                      value: '$_vehicleCount',
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.speed,
                      title: 'Inference',
                      value: '${_latencyMs.toStringAsFixed(0)}ms',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Camera Selector
              const Text(
                'Available Command Cameras',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (_registeredCameras.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.cyanAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Default Channel: $_selectedCameraId (Main Gateway)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _connectCctvWebSocket,
                        child: const Text('Re-link', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _registeredCameras.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cam = _registeredCameras[index];
                    final cid = cam['id'] ?? 'CAM-$index';
                    final isSelected = cid == _selectedCameraId;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCameraId = cid);
                        _connectCctvWebSocket();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF334155) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.cyanAccent : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.videocam,
                              color: isSelected ? Colors.cyanAccent : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cam['camera_name'] ?? cid,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    cam['location_description'] ?? 'Perimeter Monitor',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (cam['status'] == 'ONLINE')
                                    ? const Color(0x3322C55E)
                                    : const Color(0x33EF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cam['status'] ?? 'ONLINE',
                                style: TextStyle(
                                  color: (cam['status'] == 'ONLINE') ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // Live Detections List
              const Text(
                'Live YOLO11 Detections',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (_detections.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No bounding box anomalies in active frame',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                )
              else
                ..._detections.map((det) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              (det['class'] ?? 'Object').toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          'Confidence: ${(((det['confidence'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
