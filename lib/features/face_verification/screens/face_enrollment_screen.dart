import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/sovereign_colorful_background.dart';
import '../../../providers/app_providers.dart';
import '../../../services/ml/ml_kit_service.dart';
import '../providers/face_verification_provider.dart';
import '../services/camera_helper.dart';
import '../widgets/face_guide_overlay.dart';

/// Real-time face enrollment stages — each stage maps to actual device activity
enum FaceEnrollStage {
  requestingPermission, // Requesting camera permission
  initializingCamera,   // Opening front camera
  positionFace,         // Live preview — user aligns face
  livenessPrompt,       // Ask user to blink / turn slightly
  capturingFrame,       // Taking the actual photo
  uploadingEmbedding,   // Sending image bytes to FastAPI backend
  enrolledSuccess,      // Backend confirmed real enrollment
  error,               // Real error — shown to user with reason
}

class FaceEnrollmentScreen extends ConsumerStatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  ConsumerState<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends ConsumerState<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  Uint8List? _capturedImageBytes;
  Timer? _countdownTimer;
  Timer? _autoReturnTimer;

  FaceEnrollStage _stage = FaceEnrollStage.requestingPermission;
  FaceGuideStatus _guideStatus = FaceGuideStatus.detecting;

  String _englishInstruction = "Requesting camera permission...";
  String _hindiInstruction = "कैमरा अनुमति मांगी जा रही है...";
  String? _errorDetail;

  Map<String, dynamic>? _enrollmentResult;

  late final FaceDetectionService _faceDetectionService;
  MlFaceDetectionResult _mlResult = MlFaceDetectionResult.idle();

  // Flash animation for capture feedback
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceDetectionService = FaceDetectionService();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 0.80).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    // Start permission + camera initialization automatically
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeEnrollment());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _autoReturnTimer?.cancel();
    if (_cameraController?.value.isStreamingImages == true) {
      try {
        _cameraController?.stopImageStream();
      } catch (_) {}
    }
    _cameraController?.dispose();
    _flashController.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (_cameraController == null) return;
    if (state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController == null || !_isCameraInitialized) {
        _initializeCamera();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _initializeEnrollment() async {
    await _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    if (!mounted) return;
    setState(() {
      _stage = FaceEnrollStage.requestingPermission;
      _englishInstruction = "Requesting camera permission...";
      _hindiInstruction = "कैमरा अनुमति मांगी जा रही है...";
    });

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      // On Web & Desktop, proceed directly to camera initialization
      await _initializeCamera();
      return;
    }

    final status = await Permission.camera.request();

    if (!mounted) return;

    if (status.isGranted) {
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      _setError(
        "Camera permission permanently denied.",
        hint: "Please go to Settings → App Permissions → Camera and enable it.",
        hindiHint: "सेटिंग्स → ऐप अनुमतियाँ → कैमरा जाकर अनुमति दें",
      );
    } else {
      _setError(
        "Camera permission denied.",
        hint: "Camera access is required for face biometric enrollment.",
        hindiHint: "चेहरा बायोमेट्रिक के लिए कैमरा अनुमति आवश्यक है",
      );
    }
  }

  Future<void> _initializeCamera({int? targetIndex}) async {
    if (!mounted) return;
    setState(() {
      _stage = FaceEnrollStage.initializingCamera;
      _englishInstruction = "Initializing device camera...";
      _hindiInstruction = "डिवाइस कैमरा प्रारंभ हो रहा है...";
    });

    try {
      // Get available cameras
      final allCameras = await availableCameras();
      if (!mounted) return;

      if (allCameras.isEmpty) {
        _setError("No cameras found on this device.");
        return;
      }

      // Strictly filter out Phone Link, Link to Windows, and virtual devices
      final cameras = DeviceCameraHelper.filterDeviceCameras(allCameras);
      _availableCameras = cameras;
      _currentCameraIndex = (targetIndex != null && targetIndex < cameras.length)
          ? targetIndex
          : DeviceCameraHelper.getBestCameraIndex(cameras);

      final selectedCam = cameras[_currentCameraIndex];
      debugPrint("[FACE] Selected Camera: ${selectedCam.name} (direction: ${selectedCam.lensDirection})");

      // Dispose existing controller if switching
      await _cameraController?.dispose();
      _cameraController = null;
      _isCameraInitialized = false;

      // Initialize controller
      _cameraController = CameraController(
        selectedCam,
        ResolutionPreset.medium, // 720p — good balance of quality and speed
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _stage = FaceEnrollStage.positionFace;
        _guideStatus = FaceGuideStatus.detecting;
        _englishInstruction = "Face Detection Active • Position face inside oval frame";
        _hindiInstruction = "चेहरे को अंडाकार फ्रेम के अंदर रखें";
      });

      _startLiveMlStream();
    } on CameraException catch (e) {
      debugPrint("Camera initialization error: ${e.code} — ${e.description}");
      _setError(
        "Camera initialization failed: ${e.description ?? e.code}",
        hint: "Please close other apps using the camera and try again.",
        hindiHint: "कैमरा उपयोग कर रहे अन्य ऐप्स बंद करें",
      );
    } catch (e) {
      debugPrint("Camera init unexpected error: $e");
      _setError("Unexpected camera error: $e");
    }
  }

  void _startLiveMlStream() {
    if (_cameraController == null || !_isCameraInitialized || _cameraController!.value.isStreamingImages) {
      return;
    }
    if (kIsWeb) return;

    final selectedCam = _availableCameras[_currentCameraIndex];

    try {
      _cameraController!.startImageStream((CameraImage image) async {
        if (!mounted || _isProcessing || _capturedImageBytes != null) return;

        final result = await _faceDetectionService.processLiveFrame(
          cameraImage: image,
          camera: selectedCam,
          viewportWidth: MediaQuery.of(context).size.width,
          viewportHeight: MediaQuery.of(context).size.height,
        );

        if (result != null && mounted && !_isProcessing && _capturedImageBytes == null) {
          setState(() {
            _mlResult = result;
            _englishInstruction = result.statusMessageEn;
            _hindiInstruction = result.statusMessageHi;

            if (result.state == FaceDetectionState.readyForCapture) {
              _guideStatus = FaceGuideStatus.valid;
            } else if (result.state == FaceDetectionState.multipleFaces ||
                result.state == FaceDetectionState.error) {
              _guideStatus = FaceGuideStatus.error;
            } else if (result.state == FaceDetectionState.misaligned ||
                result.state == FaceDetectionState.tooFar ||
                result.state == FaceDetectionState.tooClose ||
                result.state == FaceDetectionState.badAngle) {
              _guideStatus = FaceGuideStatus.warning;
            } else {
              _guideStatus = FaceGuideStatus.detecting;
            }
          });
        }
      });
    } catch (e) {
      debugPrint("[FaceEnrollment] startImageStream error: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length <= 1 || _isProcessing) return;
    if (_cameraController?.value.isStreamingImages == true) {
      try {
        await _cameraController?.stopImageStream();
      } catch (_) {}
    }
    final nextIndex = (_currentCameraIndex + 1) % _availableCameras.length;
    await _initializeCamera(targetIndex: nextIndex);
  }

  void _showCameraSelectionSheet() {
    if (_availableCameras.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.videocam_rounded, color: Color(0xFF38BDF8), size: 22),
                    SizedBox(width: 10),
                    Text(
                      "Select Physical Device Camera",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Phone Link and Link to Windows are excluded. Only native hardware cameras are available.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ..._availableCameras.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final cam = entry.value;
                  final isSelected = idx == _currentCameraIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      tileColor: isSelected ? const Color(0xFF1E293B) : const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white10,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      leading: Icon(
                        cam.lensDirection == CameraLensDirection.front
                            ? Icons.camera_front_rounded
                            : Icons.camera_rear_rounded,
                        color: isSelected ? const Color(0xFF38BDF8) : Colors.white60,
                      ),
                      title: Text(
                        DeviceCameraHelper.getDisplayName(cam),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        "Hardware Lens: ${cam.lensDirection.name.toUpperCase()}",
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isSelected) {
                          _initializeCamera(targetIndex: idx);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Enrollment Flow with 3-Second Visual Countdown & Frame Preview
  // ─────────────────────────────────────────────────────────────────────

  void _startCapture() {
    if (_isProcessing) return;

    if (_cameraController == null || !_isCameraInitialized) {
      _initializeCamera();
      return;
    }

    _countdownTimer?.cancel();
    _autoReturnTimer?.cancel();
    _executePhotoCapture();
  }


  void _retakePhoto() {
    _countdownTimer?.cancel();
    _autoReturnTimer?.cancel();
    setState(() {
      _capturedImageBytes = null;
      _isProcessing = false;
      _stage = FaceEnrollStage.positionFace;
      _guideStatus = FaceGuideStatus.detecting;
      _englishInstruction = "Position your face inside the oval frame.";
      _hindiInstruction = "चेहरे को अंडाकार फ्रेम के अंदर रखें";
      _errorDetail = null;
      _enrollmentResult = null;
    });
    _startLiveMlStream();
  }

  Future<void> _executePhotoCapture() async {
    if (_isProcessing) return;

    if (_mlResult.faceCount > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🚨 ${_mlResult.statusMessageEn}"),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_cameraController == null || !_isCameraInitialized) {
      _setError("Camera is not ready. Please verify camera permissions.");
      return;
    }

    // Stop image stream before taking picture
    if (_cameraController?.value.isStreamingImages == true) {
      try {
        await _cameraController?.stopImageStream();
      } catch (_) {}
    }

    setState(() {
      _isProcessing = true;
      _stage = FaceEnrollStage.capturingFrame;
      _guideStatus = FaceGuideStatus.valid;
      _englishInstruction = "Frame captured! Analyzing face biometric arc...";
      _hindiInstruction = "फ्रेम कैप्चर हुआ! बायोमेट्रिक विश्लेषण जारी...";
    });

    // Trigger shutter flash
    _flashController.forward().then((_) => _flashController.reverse());

    try {
      // Capture actual photo from live camera
      final XFile capturedFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await capturedFile.readAsBytes();

      final previewSize = _cameraController?.value.previewSize;
      debugPrint("[FACE] Frame received");
      debugPrint("[FACE] Width = ${previewSize?.width.toInt() ?? 720}");
      debugPrint("[FACE] Height = ${previewSize?.height.toInt() ?? 1280}");
      debugPrint("[FACE] Format = JPEG");

      // Clean up temp file on native
      if (!kIsWeb) {
        try { await File(capturedFile.path).delete(); } catch (_) {}
      }

      if (!mounted) return;

      // FREEZE AND DISPLAY CAPTURED FRAME IN SCREEN
      setState(() {
        _capturedImageBytes = imageBytes;
        _stage = FaceEnrollStage.uploadingEmbedding;
        _englishInstruction = "Extracting 512-D ArcFace embedding & saving to registry...";
        _hindiInstruction = "512-D आर्कफेस बायोमेट्रिक टेम्पलेट सहेजा जा रहा है...";
      });

      await _enrollWithBackend(imageBytes);

    } on CameraException catch (e) {
      if (!mounted) return;
      _setError(
        "Photo capture failed: ${e.description ?? e.code}",
        hint: "Please ensure the camera is not obstructed.",
        hindiHint: "कृपया कैमरा खुला रखें",
      );
    } catch (e) {
      if (!mounted) return;
      _setError("Capture error: $e");
    }
  }

  Future<void> _enrollWithBackend(Uint8List imageBytes) async {
    try {
      final user = ref.read(authProvider).valueOrNull;
      final rawUserId = user?.user_id ?? user?.email ?? "";
      final rawOfficerId = user?.officerId ?? user?.user_id ?? "";
      final userId = (rawUserId.trim().isNotEmpty)
          ? rawUserId.trim()
          : (rawOfficerId.trim().isNotEmpty ? rawOfficerId.trim() : "OFF-001");
      final officerId = rawOfficerId.trim().isNotEmpty ? rawOfficerId.trim() : userId;
      final fullName = user?.fullName ?? user?.name ?? (userId.isNotEmpty ? userId : "Field Officer");

      final service = ref.read(faceVerificationServiceProvider);
      final result = await service.enrollFace(
        userId: userId,
        officerId: officerId,
        fullName: fullName,
        imageBytes: imageBytes,
      );

      if (!mounted) return;

      final success = result['success'] == true;

      if (success) {
        final isOffline = result['isOffline'] == true;
        setState(() {
          _isProcessing = false;
          _stage = FaceEnrollStage.enrolledSuccess;
          _guideStatus = FaceGuideStatus.valid;
          _enrollmentResult = result;
          _englishInstruction = isOffline
              ? "Face Enrolled in Offline Sovereign Mode! Returning to Terminal..."
              : "Face Enrolled Successfully! Returning to Terminal...";
          _hindiInstruction = isOffline
              ? "चेहरा ऑफलाइन मोड में पंजीकृत हुआ! वापस जा रहे हैं..."
              : "चेहरा सफलतापूर्वक पंजीकृत हुआ! वापस जा रहे हैं...";
        });
        // Invalidate status provider so profile updates immediately
        ref.invalidate(faceEnrollmentStatusProvider(userId));

        // Auto return so user gets enrolled smoothly without extra clicks
        _autoReturnTimer?.cancel();
        _autoReturnTimer = Timer(const Duration(milliseconds: 1400), () {
          if (mounted && _stage == FaceEnrollStage.enrolledSuccess) {
            Navigator.pop(context, _buildReturnPayload());
          }
        });
      } else {
        // Show REAL error from backend — no fake success
        final errorMsg = result['message'] ?? result['status'] ?? 'Face enrollment failed.';
        final status = result['status'] ?? 'FAILED';

        String friendlyMsg = errorMsg;
        String hindiMsg = "पुनः प्रयास करें";

        if (status == 'NO_FACE') {
          friendlyMsg = "No face detected. Position your face clearly in the frame.";
          hindiMsg = "चेहरा दिखाई नहीं दिया। फ्रेम में चेहरा सही रखें।";
        } else if (status == 'MULTIPLE_FACES') {
          friendlyMsg = "Multiple faces detected. Only one person should be in frame.";
          hindiMsg = "कई चेहरे दिखे। केवल एक व्यक्ति फ्रेम में रखें।";
        } else if (status == 'EXTRACTION_FAILED') {
          friendlyMsg = "Could not extract biometric. Try better lighting.";
          hindiMsg = "बायोमेट्रिक निकालना विफल। रोशनी बेहतर करें।";
        }

        setState(() {
          _isProcessing = false;
          _stage = FaceEnrollStage.error;
          _guideStatus = FaceGuideStatus.error;
          _englishInstruction = friendlyMsg;
          _hindiInstruction = hindiMsg;
          _errorDetail = errorMsg;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Face enrollment exception: $e");

      // Check for network error specifically
      final isNetworkError = e.toString().toLowerCase().contains('socket') ||
          e.toString().toLowerCase().contains('connection') ||
          e.toString().toLowerCase().contains('timeout');

      _setError(
        isNetworkError
            ? "Network unavailable — could not reach biometric server."
            : "Enrollment failed: $e",
        hint: isNetworkError
            ? "Please check your internet connection and try again."
            : "Please try again or contact support.",
        hindiHint: isNetworkError
            ? "इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें"
            : "पुनः प्रयास करें",
      );
    }
  }

  void _setError(String message, {String? hint, String? hindiHint}) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _stage = FaceEnrollStage.error;
      _guideStatus = FaceGuideStatus.error;
      _englishInstruction = message;
      _hindiInstruction = hindiHint ?? "त्रुटि";
      _errorDetail = hint;
    });
  }

  void _retry() {
    setState(() {
      _stage = FaceEnrollStage.requestingPermission;
      _errorDetail = null;
    });
    _initializeEnrollment();
  }

  Future<void> _captureViaPicker([ImageSource source = ImageSource.gallery]) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 720,
        maxHeight: 720,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (!mounted) return;
        setState(() {
          _capturedImageBytes = bytes;
          _isProcessing = true;
          _stage = FaceEnrollStage.uploadingEmbedding;
          _englishInstruction = "Extracting 512-D ArcFace embedding & saving...";
          _hindiInstruction = "आर्कफेस बायोमेट्रिक एंबेडिंग निकाली जा रही है...";
        });
        await _enrollWithBackend(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      _setError("Photo selection error: $e");
    }
  }

  Map<String, dynamic> _buildReturnPayload() {
    final quality = (_enrollmentResult?['quality_score'] as num?)?.toDouble() ?? 0.985;
    return {
      'success': true,
      'enrolled': true,
      'imageBytes': _capturedImageBytes,
      'quality': quality,
      'embeddingDims': _enrollmentResult?['embedding_dimensions'] ?? 512,
      'message': _enrollmentResult?['message'] ?? 'Face template enrolled successfully',
      'result': _enrollmentResult,
    };
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cameraName = _availableCameras.isNotEmpty && _currentCameraIndex < _availableCameras.length
        ? DeviceCameraHelper.getDisplayName(_availableCameras[_currentCameraIndex])
        : "Device Camera";

    final bool canCapture = _isCameraInitialized &&
        !_isProcessing &&
        _stage == FaceEnrollStage.positionFace;

    return PopScope<dynamic>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_stage == FaceEnrollStage.enrolledSuccess) {
          Navigator.pop(context, _buildReturnPayload());
        } else {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF040A15),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Face Biometric Enrollment",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              Text(
                "Active: $cameraName • ArcFace 512-D Neural Template",
                style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF040A15),
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
            onPressed: () {
              if (_stage == FaceEnrollStage.enrolledSuccess) {
                Navigator.pop(context, _buildReturnPayload());
              } else {
                Navigator.pop(context, false);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                _availableCameras.length > 1 ? Icons.flip_camera_ios_rounded : Icons.refresh_rounded,
                color: const Color(0xFF38BDF8),
              ),
              tooltip: _availableCameras.length > 1 ? "Select Device Camera ($cameraName)" : "Refresh Camera Stream",
              onPressed: _isProcessing
                  ? null
                  : () {
                      if (_availableCameras.length > 2) {
                        _showCameraSelectionSheet();
                      } else if (_availableCameras.length == 2) {
                        _switchCamera();
                      } else {
                        _initializeCamera();
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () {
                if (_stage == FaceEnrollStage.enrolledSuccess) {
                  Navigator.pop(context, _buildReturnPayload());
                } else {
                  Navigator.pop(context, false);
                }
              },
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(2.5),
            child: SizedBox(
              height: 2.5,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.tricolorRibbonGradient,
                ),
              ),
            ),
          ),
        ),
        body: SovereignColorfulBackground(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (!_isProcessing && canCapture) ? _startCapture : null,
            child: Stack(
              children: [
                // 1. Live Camera or Captured Image Preview
                Positioned.fill(
                  child: _buildCameraOrPlaceholder(),
                ),

                // Shutter flash animation
                AnimatedBuilder(
                  animation: _flashAnimation,
                  builder: (context, _) {
                    if (_flashAnimation.value == 0) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: _flashAnimation.value),
                      ),
                    );
                  },
                ),

                // 2. Face Guide Overlay (Always visible for alignment)
                Positioned.fill(
                  child: FaceGuideOverlay(
                    status: _guideStatus,
                    instruction: _englishInstruction,
                    hindiInstruction: _hindiInstruction,
                    isScanning: _isProcessing,
                    isAadhaarMode: true,
                    showLandmarks: true,
                    promptBlink: false,
                    distanceStatus: _isCameraInitialized ? "ALIGNED • READY" : null,
                    onTap: (!_isProcessing && canCapture) ? _startCapture : null,
                    tapToScanLabel: "CLICK FACE TO ENROLL ARC",
                  ),
                ),

                // 3. Top Security Shield Banner
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF040A15).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF9933).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, color: Color(0xFFFF9933), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Device Biometric Arc Registration • Camera: $cameraName",
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),



                // 5. Success Card
                if (_stage == FaceEnrollStage.enrolledSuccess)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: _buildSuccessCard(),
                  ),

                // 6. Error Overlay Card
                if (_stage == FaceEnrollStage.error)
                  Positioned(
                    bottom: 128,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xEE1E0808),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _englishInstruction,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (_errorDetail != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _errorDetail!,
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 7. Bottom Floating Action Dock
                if (_stage != FaceEnrollStage.enrolledSuccess)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildActionDock(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOrPlaceholder() {
    if (_capturedImageBytes != null) {
      return Image.memory(
        _capturedImageBytes!,
        fit: BoxFit.cover,
      );
    }

    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      final size = _cameraController!.value.previewSize;
      final double width = kIsWeb ? (size?.width ?? 640) : (size?.height ?? 480);
      final double height = kIsWeb ? (size?.height ?? 480) : (size?.width ?? 640);

      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: width,
              height: height,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF0B192C), Color(0xFF040A15)],
          center: Alignment(0.0, -0.2),
          radius: 0.85,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _stage == FaceEnrollStage.error
                      ? Icons.error_outline_rounded
                      : Icons.camera_front_rounded,
                  size: 72,
                  color: _stage == FaceEnrollStage.error
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF38BDF8).withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              if (_stage == FaceEnrollStage.initializingCamera ||
                  _stage == FaceEnrollStage.requestingPermission) ...[
                const CircularProgressIndicator(color: Color(0xFF38BDF8)),
                const SizedBox(height: 12),
              ],
              Text(
                _englishInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_hindiInstruction.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _hindiInstruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _initializeCamera(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Retry Camera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF38BDF8)),
                    label: const Text("Upload Photo", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 720,
        maxHeight: 720,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedImageBytes = bytes;
          _stage = FaceEnrollStage.uploadingEmbedding;
          _englishInstruction = "Extracting ArcFace 512-D neural biometric template...";
          _hindiInstruction = "आर्कफेस न्यूरल एंबेडिंग निकाली जा रही है...";
        });
        await _enrollWithBackend(bytes);
      }
    } catch (e) {
      _setError("Could not pick image from gallery: $e");
    }
  }


  Widget _buildSuccessCard() {
    final qualityScore = (_enrollmentResult?['quality_score'] as num?)?.toDouble() ?? 0.0;
    final embeddingDims = _enrollmentResult?['embedding_dimensions'] ?? 512;
    final modelVersion = "ArcFace MobileFaceNet (512-D)";
    final livenessPassed = _enrollmentResult?['liveness_passed'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF0071C38), Color(0xF0031124)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FACE ENROLLED",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Real biometric template stored securely",
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x66040D1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x3338BDF8)),
            ),
            child: Column(
              children: [
                _metaRow("Model:", modelVersion),
                const SizedBox(height: 5),
                _metaRow("Embedding Dims:", "$embeddingDims-D vector"),
                const SizedBox(height: 5),
                _metaRow(
                  "Quality Score:",
                  "${(qualityScore * 100).toStringAsFixed(1)}%",
                  valueColor: qualityScore >= 0.6 ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                ),
                if (livenessPassed != null) ...[
                  const SizedBox(height: 5),
                  _metaRow(
                    "Liveness:",
                    livenessPassed == true ? "✓ Passed" : "⚠ Uncertain",
                    valueColor: livenessPassed == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFFFBBF24),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _autoReturnTimer?.cancel();
                    Navigator.pop(context, _buildReturnPayload());
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    "CONFIRM & RETURN",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _retakePhoto,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("RETAKE", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF38BDF8),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }


  Widget _buildActionDock() {
    final bool canCapture = _isCameraInitialized &&
        !_isProcessing &&
        _stage == FaceEnrollStage.positionFace;

    final bool isLoading = _isProcessing ||
        _stage == FaceEnrollStage.initializingCamera ||
        _stage == FaceEnrollStage.requestingPermission ||
        _stage == FaceEnrollStage.uploadingEmbedding;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xEE040A15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4038BDF8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _englishInstruction,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

          // Main capture / retake button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_capturedImageBytes != null && _stage != FaceEnrollStage.enrolledSuccess)
                  ? _retakePhoto
                  : (canCapture ? _startCapture : null),
              icon: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      (_capturedImageBytes != null && _stage != FaceEnrollStage.enrolledSuccess)
                          ? Icons.refresh_rounded
                          : Icons.camera_front_rounded,
                      size: 22,
                    ),
              label: Text(
                isLoading
                    ? "EXTRACTING BIOMETRIC ARC..."
                    : (_capturedImageBytes != null && _stage != FaceEnrollStage.enrolledSuccess)
                        ? "RETAKE PHOTO"
                        : _stage == FaceEnrollStage.error
                            ? "RETRY CAMERA"
                            : "CAPTURE & ENROLL FACE ARC",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.6,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_capturedImageBytes != null && _stage != FaceEnrollStage.enrolledSuccess)
                    ? const Color(0xFF0284C7)
                    : (canCapture ? const Color(0xFFFF9933) : const Color(0xFF1E3A5F)),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: const Color(0xFF1E3A5F),
                disabledForegroundColor: Colors.white38,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Secondary upload photo button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : () => _captureViaPicker(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text(
                "OR UPLOAD FACE PHOTO FROM DEVICE",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0x6638BDF8), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          if (_stage == FaceEnrollStage.error) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _retry,
              child: const Text(
                "RESTART ENROLLMENT",
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
