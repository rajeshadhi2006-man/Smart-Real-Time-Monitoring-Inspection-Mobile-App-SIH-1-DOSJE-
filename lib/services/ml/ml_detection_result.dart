import 'dart:ui';

/// Enum representing the real-time evaluation state of face detection
enum FaceDetectionState {
  idle,
  detecting,
  noFace,
  singleFaceValid,
  multipleFaces,
  misaligned,
  tooFar,
  tooClose,
  badAngle,
  blinkingRequired,
  readyForCapture,
  error,
}

/// Data class representing individual detected face details
class DetectedFaceData {
  final Rect boundingBox;
  final double? headEulerAngleX; // Pitch (nodding up/down)
  final double? headEulerAngleY; // Yaw (turning left/right)
  final double? headEulerAngleZ; // Roll (tilting left/right)
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;
  final int? trackingId;

  const DetectedFaceData({
    required this.boundingBox,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
    this.trackingId,
  });
}

/// Strongly typed result produced by Google ML Kit Face Detection pipeline
class MlFaceDetectionResult {
  final int faceCount;
  final List<DetectedFaceData> faces;
  final FaceDetectionState state;
  final bool isEligibleForVerification;
  final String statusMessageEn;
  final String statusMessageHi;
  final double? distanceRatio;
  final double? yawAngle;
  final bool isBlinkDetected;
  final bool isCentered;
  final bool isGoodDistance;
  final bool isGoodAngle;

  const MlFaceDetectionResult({
    required this.faceCount,
    required this.faces,
    required this.state,
    required this.isEligibleForVerification,
    required this.statusMessageEn,
    required this.statusMessageHi,
    this.distanceRatio,
    this.yawAngle,
    this.isBlinkDetected = false,
    this.isCentered = false,
    this.isGoodDistance = false,
    this.isGoodAngle = false,
  });

  /// Primary face if available
  DetectedFaceData? get primaryFace => faces.isNotEmpty ? faces.first : null;

  factory MlFaceDetectionResult.idle() {
    return const MlFaceDetectionResult(
      faceCount: 0,
      faces: [],
      state: FaceDetectionState.idle,
      isEligibleForVerification: false,
      statusMessageEn: "Initializing AI Face Detector...",
      statusMessageHi: "एआई फेस डिटेक्टर प्रारंभ हो रहा है...",
    );
  }

  factory MlFaceDetectionResult.noFace() {
    return const MlFaceDetectionResult(
      faceCount: 0,
      faces: [],
      state: FaceDetectionState.noFace,
      isEligibleForVerification: false,
      statusMessageEn: "No Face Detected • Position your face inside the oval",
      statusMessageHi: "कोई चेहरा नहीं दिखा • अंडाकार फ्रेम के अंदर आएं",
    );
  }

  factory MlFaceDetectionResult.multipleFaces(int count, List<DetectedFaceData> faces) {
    return MlFaceDetectionResult(
      faceCount: count,
      faces: faces,
      state: FaceDetectionState.multipleFaces,
      isEligibleForVerification: false,
      statusMessageEn: "Multiple Faces Detected ($count) • Only 1 person allowed!",
      statusMessageHi: "कई चेहरे दिखे ($count) • केवल एक व्यक्ति की अनुमति है!",
    );
  }

  factory MlFaceDetectionResult.error(String message) {
    return MlFaceDetectionResult(
      faceCount: 0,
      faces: const [],
      state: FaceDetectionState.error,
      isEligibleForVerification: false,
      statusMessageEn: message.contains("Exception") ? "Face Detection Active • Align face in guide" : "ML Kit: $message",
      statusMessageHi: "चेहरा पहचान सक्रिय • चेहरे को अंडाकार में रखें",
    );
  }
}
