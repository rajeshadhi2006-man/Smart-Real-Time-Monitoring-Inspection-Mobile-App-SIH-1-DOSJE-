import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../home/home_dashboard_screen.dart';
import '../assignments/assignments_screen.dart';
import '../map/live_map_screen.dart';
import '../inspections/inspections_screen.dart';
import '../profile/profile_screen.dart';
import '../alerts/random_verification_dialog.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0}; // Only load index 0 on startup!
  final WebSocketService _wsService = WebSocketService();

  // Continuous Live GPS Sharing
  StreamSubscription<Position>? _positionSubscription;
  Timer? _telemetryHeartbeatTimer;
  Position? _latestPosition;
  bool _isGpsTransmitting = false;

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return const HomeDashboardScreen();
      case 1:
        return const AssignmentsScreen();
      case 2:
        return const LiveMapScreen();
      case 3:
        return const InspectionsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeDashboardScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWebSocket();
      _startLiveGpsTransmission();
    });
  }

  void _initWebSocket() {
    final authState = ref.read(authProvider);
    final user = authState.valueOrNull;
    if (user != null) {
      final uId = user.user_id.isNotEmpty ? user.user_id : user.officerId;
      _wsService.connect(uId);
      _wsService.eventStream?.listen((event) {
        final type = event['type'] ?? event['event'];
        if (type == 'RANDOM_VERIFICATION_REQUEST' || type == 'VC_SESSION_REQUESTED') {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RandomVerificationDialog(
                sessionData: event['data'] ?? event,
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _startLiveGpsTransmission() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.valueOrNull;
      if (user == null) return;
      final userId = user.user_id.isNotEmpty ? user.user_id : user.officerId;

      // 1. Acquire initial location and transmit
      final initialPos = await LocationService.getCurrentPosition(allowFallback: true);
      if (initialPos != null && mounted) {
        setState(() {
          _latestPosition = initialPos;
          _isGpsTransmitting = true;
        });
        _transmitLocation(initialPos, userId);
      }

      // 2. Continuous real-time GNSS stream (every 2 meters movement)
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        (Position pos) {
          if (mounted) {
            setState(() {
              _latestPosition = pos;
              _isGpsTransmitting = true;
            });
            _transmitLocation(pos, userId);
          }
        },
        onError: (_) {},
      );

      // 3. Periodic heartbeat telemetry (every 5 seconds) to ensure Web Dashboard remains live even when stationary
      _telemetryHeartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final pos = await LocationService.getCurrentPosition(allowFallback: false);
        if (pos != null && mounted) {
          setState(() {
            _latestPosition = pos;
            _isGpsTransmitting = true;
          });
          _transmitLocation(pos, userId);
        }
      });
    } catch (_) {}
  }

  Future<void> _transmitLocation(Position pos, String userId) async {
    try {
      // Broadcast via WebSocket
      _wsService.sendLocationUpdate(
        userId: userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
      );

      // Broadcast via REST Endpoint
      final api = ApiService();
      await api.post('/api/location/update', data: {
        'user_id': userId,
        'officer_id': userId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'speed': pos.speed,
        'heading': pos.heading,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _telemetryHeartbeatTimer?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Live GPS Transmitter Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isGpsTransmitting
                    ? [const Color(0xCC064E3B), const Color(0xCC042F2E)]
                    : [const Color(0xCC78350F), const Color(0xCC451A03)],
              ),
              border: Border(
                bottom: BorderSide(
                  color: _isGpsTransmitting ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isGpsTransmitting ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isGpsTransmitting ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _latestPosition != null
                        ? "LIVE GPS STREAMING TO WEB COMMAND • ${_latestPosition!.latitude.toStringAsFixed(4)}, ${_latestPosition!.longitude.toStringAsFixed(4)} (±${_latestPosition!.accuracy.toStringAsFixed(0)}m)"
                        : "ACQUIRING REAL GNSS FIX FOR COMMAND DASHBOARD...",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: _isGpsTransmitting ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isGpsTransmitting ? "SHARING • LIVE" : "SYNCING",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: _isGpsTransmitting ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Tab View
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildTab(0),
                _buildTab(1),
                _buildTab(2),
                _buildTab(3),
                _buildTab(4),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF061325),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0x3338BDF8), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 2.5,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.tricolorRibbonGradient,
              ),
            ),

            NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorColor: const Color(0xFF1E3A5F),
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    );
                  }
                  return const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                    _loadedTabs.add(index);
                  });
                },
                backgroundColor: const Color(0xFF061325),
                elevation: 0,
                height: 64,
                indicatorColor: const Color(0xFF132F54),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined, color: Color(0xFF94A3B8), size: 22),
                    selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFFFDE68A), size: 22),
                    label: 'Command',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_outlined, color: Color(0xFF94A3B8), size: 22),
                    selectedIcon: Icon(Icons.assignment_rounded, color: Color(0xFFFDE68A), size: 22),
                    label: 'Assignments',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.radar_rounded, color: Color(0xFF94A3B8), size: 22),
                    selectedIcon: Icon(Icons.radar_rounded, color: Color(0xFFFDE68A), size: 22),
                    label: 'Live Radar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.verified_outlined, color: Color(0xFF94A3B8), size: 22),
                    selectedIcon: Icon(Icons.verified_rounded, color: Color(0xFFFDE68A), size: 22),
                    label: 'Audits',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.badge_outlined, color: Color(0xFF94A3B8), size: 22),
                    selectedIcon: Icon(Icons.badge_rounded, color: Color(0xFFFDE68A), size: 22),
                    label: 'Smart ID',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
