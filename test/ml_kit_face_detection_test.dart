import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sih_inspection/services/ml/ml_kit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google ML Kit Face Detection Service Tests', () {
    late FaceDetectionService service;

    setUp(() {
      service = FaceDetectionService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('Zero faces produces noFace state and blocks verification', () {
      final result = service.evaluateFaces(
        faces: [],
        imageWidth: 720,
        imageHeight: 1280,
      );

      expect(result.faceCount, 0);
      expect(result.state, FaceDetectionState.noFace);
      expect(result.isEligibleForVerification, false);
      expect(result.statusMessageEn, contains("No Face Detected"));
    });

    test('Multiple faces strictly violates 1-person policy', () {
      final face1 = Face(
        boundingBox: const Rect.fromLTWH(100, 200, 200, 200),
        landmarks: const {},
        contours: const {},
      );
      final face2 = Face(
        boundingBox: const Rect.fromLTWH(400, 200, 200, 200),
        landmarks: const {},
        contours: const {},
      );

      final result = service.evaluateFaces(
        faces: [face1, face2],
        imageWidth: 720,
        imageHeight: 1280,
      );

      expect(result.faceCount, 2);
      expect(result.state, FaceDetectionState.multipleFaces);
      expect(result.isEligibleForVerification, false);
      expect(result.statusMessageEn, contains("Multiple Faces Detected (2)"));
    });

    test('Single centered face with blink verified allows verification capture', () {
      // Step 1: Simulate eyes closing (face area ~ 350x400 on 720x1280 = 15.2% ratio)
      final blinkClosedFace = Face(
        boundingBox: const Rect.fromLTWH(185, 440, 350, 400),
        landmarks: const {},
        contours: const {},
        headEulerAngleX: 0.0,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
        leftEyeOpenProbability: 0.15,
        rightEyeOpenProbability: 0.15,
      );
      service.evaluateFaces(
        faces: [blinkClosedFace],
        imageWidth: 720,
        imageHeight: 1280,
      );

      // Step 2: Simulate eyes re-opening
      final blinkOpenedFace = Face(
        boundingBox: const Rect.fromLTWH(185, 440, 350, 400),
        landmarks: const {},
        contours: const {},
        headEulerAngleX: 0.0,
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
        leftEyeOpenProbability: 0.90,
        rightEyeOpenProbability: 0.90,
      );
      final result = service.evaluateFaces(
        faces: [blinkOpenedFace],
        imageWidth: 720,
        imageHeight: 1280,
      );

      expect(result.faceCount, 1);
      expect(result.isCentered, true);
      expect(result.isGoodDistance, true);
      expect(result.isGoodAngle, true);
      expect(result.isBlinkDetected, true);
      expect(result.isEligibleForVerification, true);
      expect(result.state, FaceDetectionState.readyForCapture);
      expect(result.statusMessageEn, contains("Face Detected ✓ (1 Person)"));
    });

    test('Head angle exceeding threshold is flagged as badAngle', () {
      final turnedFace = Face(
        boundingBox: const Rect.fromLTWH(185, 440, 350, 400),
        landmarks: const {},
        contours: const {},
        headEulerAngleY: 28.0, // Turned head too much to the right
      );

      final result = service.evaluateFaces(
        faces: [turnedFace],
        imageWidth: 720,
        imageHeight: 1280,
      );

      expect(result.faceCount, 1);
      expect(result.state, FaceDetectionState.badAngle);
      expect(result.isEligibleForVerification, false);
      expect(result.statusMessageEn, contains("Look directly at the camera"));
    });
  });
}
