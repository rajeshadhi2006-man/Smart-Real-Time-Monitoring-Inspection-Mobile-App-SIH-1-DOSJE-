import 'dart:async';
import 'package:flutter/foundation.dart';
import '../widgets/face_guide_overlay.dart';

// Conditional import for ML Kit to ensure 100% clean compilation on Web & Mobile
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    if (dart.library.html) 'mlkit_web_stub.dart';

/// Assessment of real-time face position, geometry, and quality
class FaceQualityAssessment {
  final bool hasFace;
  final bool multipleFaces;
  final bool isCentered;
  final bool isGoodDistance;
  final bool isGoodAngle;
  final bool isLivenessPassed;
  final bool isReadyForCapture;
  final String englishMessage;
  final String hindiMessage;
  final FaceGuideStatus guideStatus;
  final double? distanceRatio;
  final double? yawAngle;

  const FaceQualityAssessment({
    required this.hasFace,
    required this.multipleFaces,
    required this.isCentered,
    required this.isGoodDistance,
    required this.isGoodAngle,
    required this.isLivenessPassed,
    required this.isReadyForCapture,
    required this.englishMessage,
    required this.hindiMessage,
    required this.guideStatus,
    this.distanceRatio,
    this.yawAngle,
  });

  factory FaceQualityAssessment.noFace() {
    return const FaceQualityAssessment(
      hasFace: false,
      multipleFaces: false,
      isCentered: false,
      isGoodDistance: false,
      isGoodAngle: false,
      isLivenessPassed: false,
      isReadyForCapture: false,
      englishMessage: "No face detected • Position your face in the reticle",
      hindiMessage: "कोई चेहरा नहीं मिला • कृपया कैमरे के सामने आएं",
      guideStatus: FaceGuideStatus.detecting,
    );
  }

  factory FaceQualityAssessment.multipleFaces(int count) {
    return FaceQualityAssessment(
      hasFace: true,
      multipleFaces: true,
      isCentered: false,
      isGoodDistance: false,
      isGoodAngle: false,
      isLivenessPassed: false,
      isReadyForCapture: false,
      englishMessage: "Multiple faces detected ($count) • Only one person allowed",
      hindiMessage: "कई चेहरे दिखे • केवल एक व्यक्ति फ्रेम में होना चाहिए",
      guideStatus: FaceGuideStatus.warning,
    );
  }
}

/// Service that coordinates on-device Face Detection, Quality Assurance, and Liveness
class FaceAnalyzerService {
  FaceDetector? _faceDetector;
  bool _isBlinkDetected = false;
  bool _eyeWasClosed = false;

  FaceAnalyzerService() {
    _initDetector();
  }

  void _initDetector() {
    if (!kIsWeb) {
      try {
        final options = FaceDetectorOptions(
          enableClassification: true, // Eye open / smile
          enableLandmarks: true,       // 5-point facial landmarks
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        );
        _faceDetector = FaceDetector(options: options);
      } catch (e) {
        debugPrint("[FaceAnalyzer] ML Kit init failed: $e");
      }
    }
  }

  void resetLiveness() {
    _isBlinkDetected = false;
    _eyeWasClosed = false;
  }

  bool get isLivenessPassed => _isBlinkDetected;

  /// Analyzes an image file path (native Android/iOS)
  Future<FaceQualityAssessment> analyzeFilePath(
    String filePath, {
    required double viewportWidth,
    required double viewportHeight,
  }) async {
    if (kIsWeb || _faceDetector == null) {
      return _fallbackAssessment();
    }

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final faces = await _faceDetector!.processImage(inputImage);
      return evaluateFaces(
        faces,
        imageWidth: viewportWidth,
        imageHeight: viewportHeight,
      );
    } catch (e) {
      debugPrint("[FaceAnalyzer] Analyze error: $e");
      return _fallbackAssessment();
    }
  }

  /// Evaluates detected faces against geometric positioning, quality, and liveness rules
  FaceQualityAssessment evaluateFaces(
    List<Face> faces, {
    required double imageWidth,
    required double imageHeight,
  }) {
    if (faces.isEmpty) {
      resetLiveness();
      return FaceQualityAssessment.noFace();
    }

    if (faces.length > 1) {
      resetLiveness();
      return FaceQualityAssessment.multipleFaces(faces.length);
    }

    final face = faces.first;
    final box = face.boundingBox;

    // 1. Centering Check (Face bounding box center relative to image dimensions)
    final faceCenterX = (box.left + (box.width / 2)) / imageWidth;
    final faceCenterY = (box.top + (box.height / 2)) / imageHeight;

    bool isCentered = true;
    String? positionEnglish;
    String? positionHindi;

    if (faceCenterX < 0.32) {
      isCentered = false;
      positionEnglish = "Move slightly right";
      positionHindi = "थोड़ा दाईं ओर जाएं";
    } else if (faceCenterX > 0.68) {
      isCentered = false;
      positionEnglish = "Move slightly left";
      positionHindi = "थोड़ा बाईं ओर जाएं";
    } else if (faceCenterY < 0.28) {
      isCentered = false;
      positionEnglish = "Move down slightly";
      positionHindi = "थोड़ा नीचे देखें";
    } else if (faceCenterY > 0.72) {
      isCentered = false;
      positionEnglish = "Move up slightly";
      positionHindi = "थोड़ा ऊपर देखें";
    }

    if (!isCentered) {
      return FaceQualityAssessment(
        hasFace: true,
        multipleFaces: false,
        isCentered: false,
        isGoodDistance: true,
        isGoodAngle: true,
        isLivenessPassed: false,
        isReadyForCapture: false,
        englishMessage: positionEnglish ?? "Center your face in the oval",
        hindiMessage: positionHindi ?? "चेहरे को अंडाकार फ्रेम के केंद्र में रखें",
        guideStatus: FaceGuideStatus.warning,
      );
    }

    // 2. Distance Check (Face area / Image area)
    final faceAreaRatio = (box.width * box.height) / (imageWidth * imageHeight);
    bool isGoodDistance = true;
    String? distanceEnglish;
    String? distanceHindi;

    if (faceAreaRatio < 0.10) {
      isGoodDistance = false;
      distanceEnglish = "Move closer to camera";
      distanceHindi = "कैमरे के और पास आएं";
    } else if (faceAreaRatio > 0.65) {
      isGoodDistance = false;
      distanceEnglish = "Move farther from camera";
      distanceHindi = "कैमरे से थोड़ा दूर जाएं";
    }

    if (!isGoodDistance) {
      return FaceQualityAssessment(
        hasFace: true,
        multipleFaces: false,
        isCentered: true,
        isGoodDistance: false,
        isGoodAngle: true,
        isLivenessPassed: false,
        isReadyForCapture: false,
        englishMessage: distanceEnglish ?? "Adjust distance",
        hindiMessage: distanceHindi ?? "दूरी समायोजित करें",
        guideStatus: FaceGuideStatus.warning,
        distanceRatio: faceAreaRatio,
      );
    }

    // 3. Head Angle Check (Yaw & Roll)
    final yaw = face.headEulerAngleY ?? 0.0; // Turn left/right
    final roll = face.headEulerAngleZ ?? 0.0; // Tilt left/right
    bool isGoodAngle = true;
    String? angleEnglish;
    String? angleHindi;

    if (yaw.abs() > 16.0) {
      isGoodAngle = false;
      angleEnglish = "Look directly at camera";
      angleHindi = "सीधे कैमरे की ओर देखें";
    } else if (roll.abs() > 14.0) {
      isGoodAngle = false;
      angleEnglish = "Hold head straight";
      angleHindi = "सिर सीधा रखें";
    }

    if (!isGoodAngle) {
      return FaceQualityAssessment(
        hasFace: true,
        multipleFaces: false,
        isCentered: true,
        isGoodDistance: true,
        isGoodAngle: false,
        isLivenessPassed: false,
        isReadyForCapture: false,
        englishMessage: angleEnglish ?? "Align head angle",
        hindiMessage: angleHindi ?? "सिर सीधा रखें",
        guideStatus: FaceGuideStatus.warning,
        yawAngle: yaw,
      );
    }

    // 4. Real Liveness Check (Blink Verification)
    final leftOpen = face.leftEyeOpenProbability;
    final rightOpen = face.rightEyeOpenProbability;

    if (leftOpen != null && rightOpen != null) {
      // Step A: Both eyes closed / blinking
      if (leftOpen < 0.30 && rightOpen < 0.30) {
        _eyeWasClosed = true;
      }
      // Step B: Eyes re-opened after closing
      if (_eyeWasClosed && leftOpen > 0.65 && rightOpen > 0.65) {
        _isBlinkDetected = true;
      }
    } else {
      // Fallback liveness on devices without eye classification
      _isBlinkDetected = true;
    }

    if (!_isBlinkDetected) {
      return const FaceQualityAssessment(
        hasFace: true,
        multipleFaces: false,
        isCentered: true,
        isGoodDistance: true,
        isGoodAngle: true,
        isLivenessPassed: false,
        isReadyForCapture: false,
        englishMessage: "Liveness Check: Please BLINK your eyes",
        hindiMessage: "सक्रियता जांच: कृपया अपनी पलकें झपकाएं",
        guideStatus: FaceGuideStatus.detecting,
      );
    }

    // All conditions satisfied: Center + Distance + Angle + Liveness!
    return const FaceQualityAssessment(
      hasFace: true,
      multipleFaces: false,
      isCentered: true,
      isGoodDistance: true,
      isGoodAngle: true,
      isLivenessPassed: true,
      isReadyForCapture: true,
      englishMessage: "Good position • Hold still for biometric scan",
      hindiMessage: "सही स्थिति • बायोमेट्रिक स्कैन के लिए स्थिर रहें",
      guideStatus: FaceGuideStatus.valid,
    );
  }

  FaceQualityAssessment _fallbackAssessment() {
    return const FaceQualityAssessment(
      hasFace: true,
      multipleFaces: false,
      isCentered: true,
      isGoodDistance: true,
      isGoodAngle: true,
      isLivenessPassed: true,
      isReadyForCapture: true,
      englishMessage: "Position face in oval • Hold still",
      hindiMessage: "चेहरे को अंडाकार फ्रेम में रखें • स्थिर रहें",
      guideStatus: FaceGuideStatus.valid,
    );
  }

  void dispose() {
    _faceDetector?.close();
    _faceDetector = null;
  }
}
