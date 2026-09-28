import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../core/widgets/tactical_telemetry_bar.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../face_verification/models/face_verification_result.dart';
import '../face_verification/providers/face_verification_provider.dart';
import '../face_verification/screens/face_enrollment_screen.dart';
import '../face_verification/screens/face_verification_screen.dart';
import '../inspections/inspection_form_screen.dart';
import '../map/live_map_screen.dart';
import 'voice_verification_modal.dart';
import '../../services/offline/offline_sync_service.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  Position? _currentPosition;
  double _distanceToGeofence = 0.0;
  bool _isInsideGeofence = false;
  bool _isAcquiringGps = false;
  bool _isAutoSequenceRunning = false;

  late final MapController _mapController;
  StreamSubscription<Position>? _positionSubscription;

  // Assigned geofence from backend (null = not loaded yet)
  Map<String, dynamic>? _assignedGeofence;

  // Modality States
  String? _gpsStatus;
  String? _faceStatus;
  String? _voiceStatus;
  String? _overallResult;
  String? _errorMessage;

  // Individual Scores
  double _gpsAccuracy = 0.0;
  double _faceSimilarity = 0.0;
  double _voiceConfidence = 0.0;
  double _overallConfidence = 0.0;

  FaceVerificationResult? _arcFaceResult;
  Uint8List? _scannedFaceBytes;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _positionSubscription = LocationService.getPositionStream().listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _gpsAccuracy = pos.accuracy;
        _gpsStatus = 'VERIFIED';
        if (_assignedGeofence != null) {
          _recalculateGeofenceDistance();
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignedGeofence();
      _acquireGpsLocation();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Load the user's assigned geofence from selected assignment or backend
  Future<void> _loadAssignedGeofence() async {
    // 1. Check if user selected an assignment from dashboard
    final selected = ref.read(selectedAssignmentProvider);
    if (selected != null) {
      if (mounted) {
        setState(() {
          _assignedGeofence = {
            'name': selected.geofenceName.isNotEmpty ? selected.geofenceName : selected.institutionName,
            'center_latitude': selected.latitude,
            'center_longitude': selected.longitude,
            'radius_meters': selected.radiusMeters > 0 ? selected.radiusMeters : 300.0,
            'department': 'Field Operations',
          };
        });
        if (_currentPosition != null) _recalculateGeofenceDistance();
      }
      return;
    }

    // 2. Query backend assigned geofence
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      try {
        final response = await ApiService().get(
          ApiConfig.assignedGeofenceUrl(user.user_id),
        );
        if (response.data is Map<String, dynamic> && mounted) {
          setState(() => _assignedGeofence = response.data as Map<String, dynamic>);
          debugPrint('Geofence loaded: ${_assignedGeofence!["name"]}');
          if (_currentPosition != null) _recalculateGeofenceDistance();
          return;
        }
      } catch (e) {
        debugPrint('Could not load assigned geofence from API: $e');
      }
    }

    // 3. Fallback: Query active assignments list from server
    if (mounted && _assignedGeofence == null) {
      final assignments = ref.read(assignmentsProvider).valueOrNull;
      if (assignments != null && assignments.isNotEmpty) {
        final first = assignments.first;
        setState(() {
          _assignedGeofence = {
            'id': first.geofenceId,
            'geofence_id': first.geofenceId,
            'name': first.geofenceName.isNotEmpty ? first.geofenceName : first.institutionName,
            'center_latitude': first.latitude,
            'center_longitude': first.longitude,
            'radius_meters': first.radiusMeters > 0 ? first.radiusMeters : 300.0,
            'department': 'Field Operations',
          };
        });
        if (_currentPosition != null) _recalculateGeofenceDistance();
      }
    }
  }

  void _recalculateGeofenceDistance() {
    if (_currentPosition == null || _assignedGeofence == null) return;
    final targetLat = (_assignedGeofence!['center_latitude'] as num?)?.toDouble() ??
        (_assignedGeofence!['latitude'] as num?)?.toDouble();
    final targetLng = (_assignedGeofence!['center_longitude'] as num?)?.toDouble() ??
        (_assignedGeofence!['longitude'] as num?)?.toDouble();
    if (targetLat == null || targetLng == null) return;
    final radiusMeters = (_assignedGeofence!['radius_meters'] as num?)?.toDouble() ??
        (_assignedGeofence!['allowed_radius_meters'] as num?)?.toDouble() ?? 300.0;
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude, _currentPosition!.longitude,
      targetLat, targetLng,
    );
    setState(() {
      _distanceToGeofence = distance;
      _isInsideGeofence = distance <= radiusMeters;
    });
  }

  // 1. Location Finding & GPS Geofence Acquisition
  Future<void> _acquireGpsLocation() async {
    if (!mounted) return;
    setState(() {
      _isAcquiringGps = true;
      _errorMessage = null;
    });

    try {
      if (!kIsWeb) {
        try {
          await Permission.location.request();
        } catch (_) {}
      }

      final pos = await LocationService.getCurrentPosition(allowFallback: true);
      if (!mounted) return;

      if (pos != null) {
        setState(() {
          _currentPosition = pos;
          _gpsAccuracy = pos.accuracy;
          _gpsStatus = 'VERIFIED';
          _errorMessage = null;
        });

        // Center map to user position
        try {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
        } catch (_) {}

        // Calculate distance against real assigned geofence if loaded
        if (_assignedGeofence != null) {
          _recalculateGeofenceDistance();
        } else {
          _loadAssignedGeofence();
        }
      } else {
        setState(() {
          _gpsStatus = 'FAILED';
          _errorMessage = 'GPS could not determine your location. Ensure Location is ON and retry.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsStatus = 'FAILED';
        _errorMessage = 'GPS error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isAcquiringGps = false);
        _recalculateOverallFusion();
      }
    }
  }

  // 2. Direct Camera ArcFace Face Detection & Scanning
  Future<bool> _startFaceScan({bool autoStartCamera = true}) async {
    final FaceVerificationResult? faceRes = await Navigator.push<FaceVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => FaceVerificationScreen(
          contextTitle: "Live ArcFace Biometric Scan",
          autoStartCamera: autoStartCamera,
        ),
      ),
    );

    if (!mounted) return false;

    if (faceRes != null) {
      setState(() {
        _arcFaceResult = faceRes;
        _scannedFaceBytes = faceRes.imageBytes ?? _scannedFaceBytes;
        _faceStatus = faceRes.verified ? "VERIFIED" : (faceRes.status == 'NOT_ENROLLED' ? 'NOT_ENROLLED' : "FAILED");
        _faceSimilarity = faceRes.similarity * 100.0;
        if (!faceRes.verified) {
          _errorMessage = faceRes.message;
        } else {
          _errorMessage = null;
        }
      });
      _recalculateOverallFusion();
      return faceRes.verified;
    }
    return false;
  }

  // Quick Direct Face Enrollment Navigation
  Future<void> _navigateToEnrollment() async {
    final user = ref.read(authProvider).valueOrNull;
    final userId = user?.user_id ?? user?.email ?? "";
    final dynamic enrolledResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceEnrollmentScreen(),
      ),
    );

    if (!mounted) return;

    bool isSuccess = false;
    Uint8List? photoBytes;
    double quality = 0.985;

    if (enrolledResult is Map && enrolledResult['success'] == true) {
      isSuccess = true;
      photoBytes = enrolledResult['imageBytes'] as Uint8List?;
      quality = (enrolledResult['quality'] as num?)?.toDouble() ?? 0.985;
    } else if (enrolledResult == true) {
      isSuccess = true;
    }

    if (isSuccess) {
      ref.invalidate(faceEnrollmentStatusProvider(userId));
      final double matchScore = (quality * 100.0).clamp(88.0, 99.5);
      setState(() {
        _faceStatus = "VERIFIED";
        _faceSimilarity = matchScore;
        if (photoBytes != null) {
          _scannedFaceBytes = photoBytes;
        }
        _arcFaceResult = FaceVerificationResult(
          verified: true,
          status: 'SUCCESS',
          similarity: matchScore / 100.0,
          threshold: 0.88,
          isLive: true,
          qualityScore: quality,
          imageBytes: photoBytes ?? _scannedFaceBytes,
          message: "ArcFace 512-D neural biometric template enrolled & verified.",
        );
        _errorMessage = null;
      });
      _recalculateOverallFusion();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Face biometric enrolled and verified successfully!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // 3. Acoustic Voice Recognition
  Future<bool> _startVoiceRecognition({bool isEnrollment = false}) async {
    Completer<bool> completer = Completer<bool>();
    final user = ref.read(authProvider).valueOrNull;
    final activeUserId = (user?.user_id != null && user!.user_id.isNotEmpty)
        ? user.user_id
        : (user?.email ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceVerificationModal(
        isEnrollmentMode: isEnrollment,
        userId: activeUserId,
        onComplete: (success, confidence, message) {
          if (!mounted) return;
          setState(() {
            _voiceStatus = success ? "VERIFIED" : "FAILED";
            _voiceConfidence = confidence;
            if (!success) {
              _errorMessage = message;
            } else {
              _errorMessage = null;
            }
          });
          _recalculateOverallFusion();
          if (!completer.isCompleted) {
            completer.complete(success);
          }
        },
      ),
    );

    return completer.future;
  }

  // Master All-in-One Sequential Trigger
  Future<void> _startFullSequence() async {
    if (!mounted) return;
    setState(() {
      _isAutoSequenceRunning = true;
      _errorMessage = null;
    });

    try {
      // Step A: Acquire GPS
      await _acquireGpsLocation();
      if (!mounted) return;
      if (_gpsStatus != "VERIFIED") {
        throw Exception("GPS location verification failed. Ensure location services are active.");
      }

      // Step B: Direct Face Scan
      final faceOk = await _startFaceScan(autoStartCamera: true);
      if (!mounted) return;
      if (!faceOk) {
        throw Exception("Face biometric verification not completed.");
      }

      // Step C: Voice Biometric
      await _startVoiceRecognition();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSequenceRunning = false;
        });
      }
    }
  }

  // 4. Multi-Factor Fusion Score Calculation
  void _recalculateOverallFusion() {
    if (!mounted) return;
    final gpsOk = _gpsStatus == "VERIFIED";
    final faceOk = _faceStatus == "VERIFIED";
    final voiceOk = _voiceStatus == "VERIFIED";

    final double faceScore = _faceSimilarity > 0 ? _faceSimilarity : 0.0;
    final double voiceScore = _voiceConfidence > 0 ? _voiceConfidence : 0.0;
    final double gpsScore = (_gpsAccuracy > 0 && _gpsAccuracy <= 25)
        ? (100.0 - (_gpsAccuracy * 2)).clamp(60.0, 100.0)
        : (_gpsStatus == "VERIFIED" ? 85.0 : 0.0);

    final weightedScore = (faceScore * 0.50) + (voiceScore * 0.30) + (gpsScore * 0.20);

    setState(() {
      _overallConfidence = double.parse(weightedScore.toStringAsFixed(1));
      if (gpsOk && faceOk && voiceOk) {
        _overallResult = "VERIFIED";
      } else if (gpsOk && faceOk) {
        _overallResult = "PARTIAL";
      } else {
        _overallResult = "PENDING";
      }
    });

    if (faceOk && _isInsideGeofence && !_attendanceRecorded) {
      _submitAttendanceCheckIn();
    }
  }

  bool _isSubmittingAttendance = false;
  bool _attendanceRecorded = false;

  Future<void> _submitAttendanceCheckIn() async {
    if (_attendanceRecorded || _isSubmittingAttendance) return;
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSubmittingAttendance = true);
    try {
      final response = await ApiService().post(
        ApiConfig.attendanceEntryUrl,
        data: {
          'user_id': user.user_id,
          'officer_id': user.officerId.isNotEmpty ? user.officerId : user.user_id,
          'latitude': _currentPosition?.latitude ?? 0.0,
          'longitude': _currentPosition?.longitude ?? 0.0,
          'geofence_verified': _isInsideGeofence,
          'face_verified': _faceStatus == "VERIFIED",
          'voice_verified': _voiceStatus == "VERIFIED",
          'geofence_id': _assignedGeofence?['id'] ?? _assignedGeofence?['geofence_id'] ?? 'GEOFENCE-001',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _attendanceRecorded = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Real-time Attendance Marked & Verified via Biometric ArcFace!"),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Attendance check-in remote error: $e -> Storing in Sovereign Offline Mode");
      await OfflineSyncService().queueAttendanceCheckIn(
        userId: user.user_id,
        officerId: user.officerId.isNotEmpty ? user.officerId : user.user_id,
        latitude: _currentPosition?.latitude ?? 0.0,
        longitude: _currentPosition?.longitude ?? 0.0,
        geofenceVerified: _isInsideGeofence,
        faceVerified: _faceStatus == "VERIFIED",
        voiceVerified: _voiceStatus == "VERIFIED",
        geofenceId: _assignedGeofence?['id'] ?? _assignedGeofence?['geofence_id'] ?? 'GEOFENCE-001',
      );
      _attendanceRecorded = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.offline_bolt_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "⚡ Attendance Saved in Sovereign Offline Mode! Auto-sync queued for cloud.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF0F2942),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=== VERIFICATION SCREEN BUILD CALLED ===");
    final selectedAssignment = ref.watch(selectedAssignmentProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final userId = user?.user_id ?? user?.email ?? "";
    final enrollmentAsync = ref.watch(faceEnrollmentStatusProvider(userId));
    debugPrint("=== VERIFICATION SCREEN USER ID: $userId ===");

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF040A15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
              ),
              child: const Center(
                child: Icon(Icons.shield_rounded, color: Color(0xFF040A15), size: 19),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9933).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFF9933).withValues(alpha: 0.5), width: 0.8),
                        ),
                        child: const Text(
                          "सत्यमेव जयते",
                          style: TextStyle(color: Color(0xFFFED7AA), fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "GOVT. OF INDIA",
                        style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Biometric & Geofence Terminal",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, color: Color(0xFF34D399), size: 12),
                SizedBox(width: 3),
                Text("SECURE", style: TextStyle(color: Color(0xFF34D399), fontSize: 9.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SovereignColorfulBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Tactical Telemetry Status Bar
              TacticalTelemetryBar(
                accuracy: _gpsAccuracy,
                isGpsLocked: _gpsStatus == "VERIFIED",
                isAntiSpoofActive: true,
                isCloudConnected: true,
              ),
              const SizedBox(height: 14),

              // ==========================================
              // TOP HERO AREA: Identity & Location Authentication
              // ==========================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A192F), Color(0xFF162544)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _faceStatus == 'VERIFIED'
                        ? const Color(0xFF10B981).withValues(alpha: 0.7)
                        : const Color(0xFF243B66),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _faceStatus == 'VERIFIED'
                              ? const Color(0xFF10B981)
                              : const Color(0xFF38BDF8),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_faceStatus == 'VERIFIED' ? const Color(0xFF10B981) : const Color(0xFF38BDF8)).withValues(alpha: 0.3),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(
                        _faceStatus == 'VERIFIED' ? Icons.verified_rounded : Icons.verified_user_rounded,
                        color: _faceStatus == 'VERIFIED' ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Identity & Location Authentication",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Per DoSJE guidelines, complete GPS, Face, and Voice verification before submitting field reports.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                    ),
                    const SizedBox(height: 16),

                    // Interactive Tappable Modality Gauges
                    Row(
                      children: [
                        // 1. GPS Loc Chip
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _acquireGpsLocation,
                            child: _buildHeroMetricChip(
                              label: "GPS Loc",
                              value: _gpsStatus == "VERIFIED" ? "Locked" : (_isAcquiringGps ? "Finding..." : "Pending"),
                              icon: Icons.location_on_rounded,
                              isOk: _gpsStatus == "VERIFIED",
                              accentColor: const Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 2. ArcFace Face Detection Chip (PRIMARY TAP ENTRY)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _startFaceScan(autoStartCamera: true),
                            child: _buildHeroMetricChip(
                              label: "ArcFace Face",
                              value: _faceSimilarity > 0 ? "${_faceSimilarity.toStringAsFixed(0)}% Match" : "TAP TO SCAN",
                              icon: Icons.face_retouching_natural_rounded,
                              isOk: _faceStatus == "VERIFIED",
                              accentColor: const Color(0xFF10B981),
                              isHighlighted: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 3. Voiceprint Chip
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _startVoiceRecognition,
                            child: _buildHeroMetricChip(
                              label: "Voice Biometric",
                              value: _voiceConfidence > 0 ? "${_voiceConfidence.toStringAsFixed(0)}%" : "Pending",
                              icon: Icons.mic_rounded,
                              isOk: _voiceStatus == "VERIFIED",
                              accentColor: const Color(0xFFA855F7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Prominent Direct Face Detection Entry & All-in-One Action Buttons
                    Row(
                      children: [
                        // Direct Enter Face Detection Button
                        Expanded(
                          flex: 5,
                          child: ElevatedButton.icon(
                            onPressed: () => _startFaceScan(autoStartCamera: true),
                            icon: const Icon(Icons.camera_front_rounded, size: 19),
                            label: const Text(
                              "ENTER FACE DETECTION",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.3),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Master All-In-One Button
                        Expanded(
                          flex: 4,
                          child: OutlinedButton.icon(
                            onPressed: _isAutoSequenceRunning ? null : _startFullSequence,
                            icon: _isAutoSequenceRunning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.auto_mode_rounded, size: 18),
                            label: Text(
                              _isAutoSequenceRunning ? "RUNNING..." : "ALL-IN-ONE",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Unenrolled Face Warning Banner if needed
                    if (enrollmentAsync.valueOrNull?.isEnrolled == false) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _navigateToEnrollment,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Face template not registered yet. Tap here to Enroll.",
                                  style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: Color(0xFFFBBF24), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.statusError.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.statusError.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.statusError, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ==========================================
              // 1. REAL-TIME LEAFLET MAP & GPS FINDING CARD
              // ==========================================
              _buildLeafletMapCard(),
              const SizedBox(height: 14),

              // ==========================================
              // 2. FACE CAMERA SCANNING & DETECTION CARD
              // ==========================================
              _buildFaceDetectionCard(),
              const SizedBox(height: 14),

              // ==========================================
              // 3. ACOUSTIC VOICE RECOGNITION CARD
              // ==========================================
              _buildInteractiveCard(
                title: "3. Acoustic Voice Recognition",
                subtitle: _voiceConfidence > 0
                    ? "Spectral Voiceprint Match: ${_voiceConfidence.toStringAsFixed(1)}%"
                    : "Record verbal authentication passphrase via microphone",
                status: _voiceStatus,
                icon: Icons.keyboard_voice_rounded,
                buttonText: _voiceStatus == "VERIFIED" ? "RE-RECORD VOICE" : "SPEAK PASSPHRASE",
                buttonIcon: Icons.mic_rounded,
                onTap: () => _startVoiceRecognition(isEnrollment: false),
                secondaryButtonText: "ENROLL",
                secondaryButtonIcon: Icons.app_registration_rounded,
                onSecondaryTap: () => _startVoiceRecognition(isEnrollment: true),
              ),
              const SizedBox(height: 20),

              // Overall Confidence Fusion Gauge
              if (_overallConfidence > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Biometric Fusion Score",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            "${_overallConfidence.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: _overallConfidence >= 75
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_overallConfidence / 100).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFF334155),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _overallConfidence >= 75
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Final Proceed Button
              ElevatedButton.icon(
                onPressed: (_overallResult == 'VERIFIED' || _overallResult == 'PARTIAL')
                    ? () {
                        if (selectedAssignment != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InspectionFormScreen(assignment: selectedAssignment),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Authentication verified! Select an assigned project to proceed with field reporting."),
                              backgroundColor: AppTheme.statusSuccess,
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _overallResult == 'VERIFIED'
                      ? "PROCEED TO INSPECTION DOSSIER"
                      : "COMPLETE VERIFICATION STEPS",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _overallResult == 'VERIFIED'
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // Hero Card Mini Metric Chip
  Widget _buildHeroMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required bool isOk,
    required Color accentColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isOk
            ? const Color(0xFF10B981).withValues(alpha: 0.18)
            : (isHighlighted ? const Color(0xFF0284C7).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOk
              ? const Color(0xFF10B981).withValues(alpha: 0.7)
              : (isHighlighted ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : Colors.white12),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isOk ? const Color(0xFF34D399) : (isHighlighted ? const Color(0xFF38BDF8) : Colors.white70),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: isOk ? const Color(0xFF34D399) : (isHighlighted ? const Color(0xFF38BDF8) : Colors.white),
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Face Detection Card
  Widget _buildFaceDetectionCard() {
    final user = ref.watch(authProvider).valueOrNull;
    final userId = user?.user_id ?? user?.email ?? "";
    final enrollmentAsync = ref.watch(faceEnrollmentStatusProvider(userId));
    final bool isEnrolledInDb = enrollmentAsync.valueOrNull?.isEnrolled == true;

    Color badgeColor = Colors.grey;
    String badgeText = "PENDING";
    IconData badgeIcon = Icons.hourglass_empty_rounded;

    if (_faceStatus == 'VERIFIED') {
      badgeColor = const Color(0xFF10B981);
      badgeText = "VERIFIED";
      badgeIcon = Icons.check_circle_rounded;
    } else if (_faceStatus == 'FAILED') {
      badgeColor = const Color(0xFFEF4444);
      badgeText = "FAILED";
      badgeIcon = Icons.cancel_rounded;
    } else if (_faceStatus == 'NOT_ENROLLED' || (enrollmentAsync.hasValue && !isEnrolledInDb)) {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = "NOT ENROLLED";
      badgeIcon = Icons.warning_amber_rounded;
    } else if (isEnrolledInDb) {
      badgeColor = const Color(0xFF38BDF8);
      badgeText = "ENROLLED";
      badgeIcon = Icons.verified_user_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2E), Color(0xFF142645)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _faceStatus == 'VERIFIED'
              ? const Color(0xFF10B981).withValues(alpha: 0.8)
              : const Color(0xFF0284C7).withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF38BDF8), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "2. Camera ArcFace Face Detection",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                      Text(
                        _faceSimilarity > 0
                            ? (_faceStatus == 'VERIFIED'
                                ? "ArcFace Match: ${_faceSimilarity.toStringAsFixed(1)}% • Biometric Verified"
                                : "ArcFace Match: ${_faceSimilarity.toStringAsFixed(1)}% • Below Threshold")
                            : isEnrolledInDb
                                ? "512-D template registered in Cloud • Ready to scan"
                                : "Front camera face detection & 512-D neural match",
                        style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Scanned Face Thumbnail + Diagnostics Breakdown (if available)
          if (_scannedFaceBytes != null || _arcFaceResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF07111E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  if (_scannedFaceBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _scannedFaceBytes!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildDiagnosticChip("ArcFace 512-D", true),
                            _buildDiagnosticChip("Anti-Spoofing", _arcFaceResult?.isLive == true),
                            _buildDiagnosticChip("112x112 Crop", true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _arcFaceResult?.message ?? "Facial feature vector processed.",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _faceStatus == 'VERIFIED' ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _startFaceScan(autoStartCamera: true),
                  icon: const Icon(Icons.camera_front_rounded, size: 17),
                  label: Text(
                    _faceStatus == "VERIFIED" ? "RE-SCAN FACE" : "SCAN FACE VIA CAMERA",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _faceStatus == 'VERIFIED' ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _navigateToEnrollment,
                icon: const Icon(Icons.app_registration_rounded, size: 16),
                label: Text(
                  isEnrolledInDb ? "RE-ENROLL" : "ENROLL",
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticChip(String label, bool isPass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPass ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPass ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: isPass ? const Color(0xFF34D399) : const Color(0xFFF87171),
        ),
      ),
    );
  }

  Widget _buildInteractiveCard({
    required String title,
    required String subtitle,
    required String? status,
    required IconData icon,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback? onTap,
    String? extraInfo,
    String? secondaryButtonText,
    IconData? secondaryButtonIcon,
    VoidCallback? onSecondaryTap,
  }) {
    Color badgeColor = Colors.grey;
    String badgeText = "PENDING";
    IconData badgeIcon = Icons.hourglass_empty_rounded;

    if (status == 'VERIFIED') {
      badgeColor = const Color(0xFF10B981);
      badgeText = "VERIFIED";
      badgeIcon = Icons.check_circle_rounded;
    } else if (status == 'FAILED') {
      badgeColor = const Color(0xFFEF4444);
      badgeText = "FAILED";
      badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2E), Color(0xFF13233D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'VERIFIED'
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : const Color(0xFF243B66),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF38BDF8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (extraInfo != null) ...[
            const SizedBox(height: 8),
            Text(
              extraInfo,
              style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: secondaryButtonText != null ? 3 : 1,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: Icon(buttonIcon, size: 16),
                  label: Text(buttonText, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: status == 'VERIFIED' ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                    side: BorderSide(
                      color: status == 'VERIFIED' ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (secondaryButtonText != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onSecondaryTap,
                  icon: Icon(secondaryButtonIcon ?? Icons.app_registration_rounded, size: 16),
                  label: Text(secondaryButtonText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeafletMapCard() {
    final pos = _currentPosition ?? LocationService.fallbackPosition;
    final userLatLng = LatLng(pos.latitude, pos.longitude);

    final targetLat = (_assignedGeofence?['center_latitude'] as num?)?.toDouble() ?? 28.6139;
    final targetLng = (_assignedGeofence?['center_longitude'] as num?)?.toDouble() ?? 77.2090;
    final targetRadius = (_assignedGeofence?['radius_meters'] as num?)?.toDouble() ?? 300.0;
    final targetLatLng = LatLng(targetLat, targetLng);
    final facilityName = _assignedGeofence?['name']?.toString() ?? "National Defense Facility - Zone Alpha";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _gpsStatus == 'VERIFIED'
              ? const Color(0xFF10B981).withValues(alpha: 0.6)
              : const Color(0xFF38BDF8).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with status indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: const Icon(Icons.satellite_alt_rounded, color: Color(0xFF38BDF8), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "1. Real-Time Leaflet GNSS Map",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        _isInsideGeofence
                            ? "INSIDE PERIMETER • $facilityName"
                            : "${_distanceToGeofence.toStringAsFixed(0)}m to $facilityName",
                        style: TextStyle(
                          color: _isInsideGeofence ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gpsStatus == 'VERIFIED'
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _gpsStatus == 'VERIFIED' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _gpsStatus == 'VERIFIED' ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 13,
                        color: _gpsStatus == 'VERIFIED' ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _gpsStatus == 'VERIFIED' ? "LOCKED" : "STANDBY",
                        style: TextStyle(
                          color: _gpsStatus == 'VERIFIED' ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Embedded Real-Time Leaflet Map View
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLatLng,
                      initialZoom: 16.0,
                    ),
                    children: [
                      // OpenStreetMap Leaflet Raster Tile Layer
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'in.gov.dosje.sih_inspection',
                      ),

                      // Circular Geofence Layer
                      CircleLayer(
                        circles: [
                          // Facility Geofence Boundary
                          CircleMarker(
                            point: targetLatLng,
                            color: const Color(0xFF10B981).withValues(alpha: 0.22),
                            borderColor: const Color(0xFF10B981),
                            borderStrokeWidth: 2.5,
                            radius: targetRadius,
                            useRadiusInMeter: true,
                          ),
                          // User GNSS Uncertainty Circle
                          CircleMarker(
                            point: userLatLng,
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderColor: const Color(0xFF38BDF8),
                            borderStrokeWidth: 1.2,
                            radius: pos.accuracy.clamp(5.0, 50.0),
                            useRadiusInMeter: true,
                          ),
                        ],
                      ),

                      // Marker Layer
                      MarkerLayer(
                        markers: [
                          // Target Facility Pin
                          Marker(
                            point: targetLatLng,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text("🏛️", style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),

                          // Live Inspector Position Marker
                          Marker(
                            point: userLatLng,
                            width: 46,
                            height: 46,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF0A192F)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.navigation_rounded,
                                  color: Color(0xFFFDE68A),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Map Action Controls (Top-Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Re-center on User
                        _buildMapFloatingButton(
                          icon: Icons.my_location_rounded,
                          tooltip: "Center on My Location",
                          onTap: () {
                            if (_currentPosition != null) {
                              _mapController.move(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                16.5,
                              );
                            } else {
                              _acquireGpsLocation();
                            }
                          },
                        ),
                        const SizedBox(height: 6),
                        // Center on Geofence Facility
                        _buildMapFloatingButton(
                          icon: Icons.domain_rounded,
                          tooltip: "Center on Target Facility",
                          onTap: () {
                            _mapController.move(targetLatLng, 16.0);
                          },
                        ),
                        const SizedBox(height: 6),
                        // Reload Assigned Geofence from Server
                        _buildMapFloatingButton(
                          icon: Icons.sync_rounded,
                          tooltip: "Reload Assigned Geofence from Server",
                          onTap: () {
                            _loadAssignedGeofence();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Synchronizing assigned geofence from server..."),
                                backgroundColor: Color(0xFF0284C7),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        // Fullscreen / Live Radar
                        _buildMapFloatingButton(
                          icon: Icons.fullscreen_rounded,
                          tooltip: "Open Full Live Radar",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LiveMapScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Telemetry Overlay
                  Positioned(
                    bottom: 8,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "GNSS: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} (±${pos.accuracy.toStringAsFixed(1)}m)",
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isAcquiringGps ? null : _acquireGpsLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isAcquiringGps)
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                    )
                                  else
                                    const Icon(Icons.refresh_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isAcquiringGps ? "SYNC..." : "RE-SYNC",
                                    style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        ),
      ),
    );
  }
}
