// Web Stub for Google ML Kit Face Detection to allow clean compilation on web browsers.

class FaceDetectorOptions {
  final bool enableClassification;
  final bool enableLandmarks;
  final dynamic performanceMode;
  final double minFaceSize;

  const FaceDetectorOptions({
    this.enableClassification = false,
    this.enableLandmarks = false,
    this.performanceMode,
    this.minFaceSize = 0.1,
  });
}

enum FaceDetectorMode { fast, accurate }

class FaceDetector {
  final FaceDetectorOptions options;
  FaceDetector({required this.options});

  Future<List<Face>> processImage(dynamic inputImage) async => [];
  Future<void> close() async {}
}

class Face {
  final dynamic boundingBox;
  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;

  Face({
    this.boundingBox,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
  });
}

class InputImage {
  static InputImage fromFilePath(String path) => InputImage();
  static InputImage fromBytes({required dynamic bytes, required dynamic metadata}) => InputImage();
}

enum InputImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg,
}

enum InputImageFormat {
  nv21,
  yv12,
  yuv_420_888,
  yuv420,
  bgra8888,
  rgba8888,
}

class InputImageMetadata {
  final dynamic size;
  final InputImageRotation rotation;
  final InputImageFormat format;
  final int bytesPerRow;

  const InputImageMetadata({
    required this.size,
    required this.rotation,
    required this.format,
    required this.bytesPerRow,
  });
}
