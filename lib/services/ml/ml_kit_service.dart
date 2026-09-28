import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'face_detection_service.dart';
export 'ml_detection_result.dart';
export 'face_detection_service.dart';
export 'camera_image_converter.dart';

/// Central On-Device Machine Learning Service for MoSJE Nirikshan App
class MlKitService {
  final FaceDetectionService _faceDetectionService;

  MlKitService() : _faceDetectionService = FaceDetectionService();

  /// Access face detection engine
  FaceDetectionService get faceDetector => _faceDetectionService;

  /// Dispose all active ML models and release GPU/NPU memory
  void dispose() {
    _faceDetectionService.dispose();
  }
}

/// Global Riverpod provider for ML Kit Service
final mlKitServiceProvider = Provider<MlKitService>((ref) {
  final service = MlKitService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Riverpod provider for real-time face detector
final faceDetectionServiceProvider = Provider<FaceDetectionService>((ref) {
  final mlService = ref.watch(mlKitServiceProvider);
  return mlService.faceDetector;
});
