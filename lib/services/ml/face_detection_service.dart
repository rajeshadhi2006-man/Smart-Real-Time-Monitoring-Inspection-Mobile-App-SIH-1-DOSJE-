import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    if (dart.library.html) '../../features/face_verification/services/mlkit_web_stub.dart';
import 'camera_image_converter.dart';
import 'ml_detection_result.dart';

/// Modular, production-ready on-device Google ML Kit Face Detection Service
class FaceDetectionService {
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  DateTime _lastFrameTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Target inference throttle: ~150ms between frames (~6.6 FPS)
  static const Duration _throttleInterval = Duration(milliseconds: 150);

  // Liveness tracking (eye blink state machine)
  bool _eyeWasClosed = false;
  bool _isBlinkDetected = false;

  FaceDetectionService() {
    _initDetector();
  }

  void _initDetector() {
    if (!kIsWeb) {
      try {
        final options = FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        );
        _faceDetector = FaceDetector(options: options);
      } catch (e) {
        debugPrint("[FaceDetectionService] ML Kit init failed: $e");
      }
    }
  }

  void resetLiveness() {
    _eyeWasClosed = false;
    _isBlinkDetected = false;
  }

  bool get isBlinkDetected => _isBlinkDetected;

  /// Processes a live camera frame with async concurrency protection and throttling
  Future<MlFaceDetectionResult?> processLiveFrame({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required double viewportWidth,
    required double viewportHeight,
  }) async {
    if (kIsWeb || _faceDetector == null) return null;

    final now = DateTime.now();
    if (now.difference(_lastFrameTime) < _throttleInterval) {
      return null; // Skip frame to throttle inference
    }

    if (_isDetecting) {
      return null; // Skip if previous frame is still processing
    }

    _isDetecting = true;
    _lastFrameTime = now;

    try {
      final inputImage = CameraImageConverter.convert(
        image: cameraImage,
        camera: camera,
      );

      if (inputImage == null) {
        return null;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      final bool isRotated = camera.sensorOrientation == 90 || camera.sensorOrientation == 270;
      final double effectiveWidth = isRotated ? cameraImage.height.toDouble() : cameraImage.width.toDouble();
      final double effectiveHeight = isRotated ? cameraImage.width.toDouble() : cameraImage.height.toDouble();

      return evaluateFaces(
        faces: faces,
        imageWidth: effectiveWidth,
        imageHeight: effectiveHeight,
      );
    } catch (e) {
      debugPrint("[FaceDetectionService] Live frame detection error: $e");
      return MlFaceDetectionResult.error(e.toString());
    } finally {
      _isDetecting = false;
    }
  }

  /// Evaluates an image file by path
  Future<MlFaceDetectionResult> processImageFile(
    String filePath, {
    required double viewportWidth,
    required double viewportHeight,
  }) async {
    if (kIsWeb || _faceDetector == null) {
      return MlFaceDetectionResult.idle();
    }

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final faces = await _faceDetector!.processImage(inputImage);
      return evaluateFaces(
        faces: faces,
        imageWidth: viewportWidth,
        imageHeight: viewportHeight,
      );
    } catch (e) {
      debugPrint("[FaceDetectionService] File detection error: $e");
      return MlFaceDetectionResult.error(e.toString());
    }
  }

  /// Evaluates detected ML Kit faces against geometric & one-person rules
  MlFaceDetectionResult evaluateFaces({
    required List<Face> faces,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (faces.isEmpty) {
      resetLiveness();
      return MlFaceDetectionResult.noFace();
    }

    final detectedFaces = faces.map((f) {
      return DetectedFaceData(
        boundingBox: f.boundingBox,
        headEulerAngleX: f.headEulerAngleX,
        headEulerAngleY: f.headEulerAngleY,
        headEulerAngleZ: f.headEulerAngleZ,
        leftEyeOpenProbability: f.leftEyeOpenProbability,
        rightEyeOpenProbability: f.rightEyeOpenProbability,
        smilingProbability: f.smilingProbability,
        trackingId: f.trackingId,
      );
    }).toList();

    // RULE: Exactly ONE person allowed
    if (faces.length > 1) {
      resetLiveness();
      return MlFaceDetectionResult.multipleFaces(faces.length, detectedFaces);
    }

    final face = faces.first;
    final box = face.boundingBox;

    // 1. Centering Check (normalized relative to preview bounds)
    final faceCenterX = (box.left + (box.width / 2)) / imageWidth;
    final faceCenterY = (box.top + (box.height / 2)) / imageHeight;

    bool isCentered = true;
    String? misalignedEn;
    String? misalignedHi;

    if (faceCenterX < 0.28) {
      isCentered = false;
      misalignedEn = "Move slightly right";
      misalignedHi = "थोड़ा दाईं ओर जाएं";
    } else if (faceCenterX > 0.72) {
      isCentered = false;
      misalignedEn = "Move slightly left";
      misalignedHi = "थोड़ा बाईं ओर जाएं";
    } else if (faceCenterY < 0.22) {
      isCentered = false;
      misalignedEn = "Move slightly down";
      misalignedHi = "थोड़ा नीचे आएं";
    } else if (faceCenterY > 0.78) {
      isCentered = false;
      misalignedEn = "Move slightly up";
      misalignedHi = "थोड़ा ऊपर आएं";
    }

    if (!isCentered) {
      return MlFaceDetectionResult(
        faceCount: 1,
        faces: detectedFaces,
        state: FaceDetectionState.misaligned,
        isEligibleForVerification: false,
        statusMessageEn: misalignedEn ?? "Center face in the oval guide",
        statusMessageHi: misalignedHi ?? "चेहरे को गाइड के केंद्र में रखें",
        isCentered: false,
      );
    }

    // 2. Distance Check (Face area / Image area)
    final faceAreaRatio = (box.width * box.height) / (imageWidth * imageHeight);
    bool isGoodDistance = true;
    String? distanceEn;
    String? distanceHi;

    if (faceAreaRatio < 0.08) {
      isGoodDistance = false;
      distanceEn = "Move closer to camera";
      distanceHi = "कैमरे के और पास आएं";
    } else if (faceAreaRatio > 0.70) {
      isGoodDistance = false;
      distanceEn = "Move farther from camera";
      distanceHi = "कैमरे से थोड़ा दूर जाएं";
    }

    if (!isGoodDistance) {
      return MlFaceDetectionResult(
        faceCount: 1,
        faces: detectedFaces,
        state: faceAreaRatio < 0.08 ? FaceDetectionState.tooFar : FaceDetectionState.tooClose,
        isEligibleForVerification: false,
        statusMessageEn: distanceEn ?? "Adjust camera distance",
        statusMessageHi: distanceHi ?? "दूरी सही करें",
        distanceRatio: faceAreaRatio,
        isCentered: true,
        isGoodDistance: false,
      );
    }

    // 3. Head Angle Check (Yaw & Roll)
    final yaw = face.headEulerAngleY ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;
    bool isGoodAngle = true;
    String? angleEn;
    String? angleHi;

    if (yaw.abs() > 18.0) {
      isGoodAngle = false;
      angleEn = "Look directly at the camera";
      angleHi = "सीधे कैमरे की ओर देखें";
    } else if (roll.abs() > 16.0) {
      isGoodAngle = false;
      angleEn = "Hold your head upright";
      angleHi = "सिर सीधा रखें";
    }

    if (!isGoodAngle) {
      return MlFaceDetectionResult(
        faceCount: 1,
        faces: detectedFaces,
        state: FaceDetectionState.badAngle,
        isEligibleForVerification: false,
        statusMessageEn: angleEn ?? "Straighten head position",
        statusMessageHi: angleHi ?? "सिर की स्थिति सीधी रखें",
        yawAngle: yaw,
        isCentered: true,
        isGoodDistance: true,
        isGoodAngle: false,
      );
    }

    // 4. Liveness / Blink Verification
    final leftOpen = face.leftEyeOpenProbability;
    final rightOpen = face.rightEyeOpenProbability;

    if (leftOpen != null && rightOpen != null) {
      if (leftOpen < 0.30 && rightOpen < 0.30) {
        _eyeWasClosed = true;
      }
      if (_eyeWasClosed && leftOpen > 0.65 && rightOpen > 0.65) {
        _isBlinkDetected = true;
      }
    } else {
      // Fallback if sensor does not output eye classification
      _isBlinkDetected = true;
    }

    if (!_isBlinkDetected) {
      return MlFaceDetectionResult(
        faceCount: 1,
        faces: detectedFaces,
        state: FaceDetectionState.blinkingRequired,
        isEligibleForVerification: false,
        statusMessageEn: "Liveness Check: Please BLINK your eyes",
        statusMessageHi: "सक्रियता जांच: कृपया अपनी पलकें झपकाएं",
        isCentered: true,
        isGoodDistance: true,
        isGoodAngle: true,
        isBlinkDetected: false,
      );
    }

    // All conditions verified: Exactly 1 face, centered, proper distance, straight angle, and blink verified!
    return MlFaceDetectionResult(
      faceCount: 1,
      faces: detectedFaces,
      state: FaceDetectionState.readyForCapture,
      isEligibleForVerification: true,
      statusMessageEn: "Face Detected ✓ (1 Person) • Ready for ArcFace Verification",
      statusMessageHi: "चेहरा सत्यापित ✓ (1 व्यक्ति) • बायोमेट्रिक मिलान के लिए तैयार",
      isCentered: true,
      isGoodDistance: true,
      isGoodAngle: true,
      isBlinkDetected: true,
      distanceRatio: faceAreaRatio,
      yawAngle: yaw,
    );
  }

  Future<void> dispose() async {
    try {
      await _faceDetector?.close();
    } catch (_) {}
    _faceDetector = null;
  }
}
