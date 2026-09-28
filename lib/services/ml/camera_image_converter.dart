import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    if (dart.library.html) '../../features/face_verification/services/mlkit_web_stub.dart';

/// High-performance utility to convert CameraImage into Google ML Kit InputImage
class CameraImageConverter {
  const CameraImageConverter._();

  /// Converts a live [CameraImage] into Google ML Kit [InputImage]
  static InputImage? convert({
    required CameraImage image,
    required CameraDescription camera,
  }) {
    if (kIsWeb) return null;

    try {
      final rotation = getImageRotation(camera);

      Uint8List bytes;
      InputImageFormat format;

      if (Platform.isAndroid) {
        format = InputImageFormat.nv21;
        if (image.planes.length == 1) {
          bytes = image.planes.first.bytes;
        } else {
          // If 3 planes (Y, U, V from YUV_420_888), convert to clean NV21 (Y followed by VU)
          final int width = image.width;
          final int height = image.height;
          final int ySize = width * height;
          final int uvSize = width * height ~/ 2;
          final nv21 = Uint8List(ySize + uvSize);

          final yPlane = image.planes[0];
          final uPlane = image.planes[1];
          final vPlane = image.planes[2];

          // Copy Y
          int yIndex = 0;
          for (int row = 0; row < height; row++) {
            final rowStart = row * yPlane.bytesPerRow;
            nv21.setRange(yIndex, yIndex + width, yPlane.bytes, rowStart);
            yIndex += width;
          }

          // Interleave VU
          int uvIndex = ySize;
          final int uvRowStride = uPlane.bytesPerRow;
          final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

          for (int row = 0; row < height ~/ 2; row++) {
            for (int col = 0; col < width ~/ 2; col++) {
              final int vOffset = row * vPlane.bytesPerRow + col * (vPlane.bytesPerPixel ?? 1);
              final int uOffset = row * uvRowStride + col * uvPixelStride;

              if (vOffset < vPlane.bytes.length && uvIndex < nv21.length) {
                nv21[uvIndex++] = vPlane.bytes[vOffset];
              }
              if (uOffset < uPlane.bytes.length && uvIndex < nv21.length) {
                nv21[uvIndex++] = uPlane.bytes[uOffset];
              }
            }
          }
          bytes = nv21;
        }
      } else if (Platform.isIOS) {
        format = InputImageFormat.bgra8888;
        bytes = image.planes.first.bytes;
      } else {
        return null;
      }

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final plane = image.planes.first;

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint("[CameraImageConverter] Conversion error: $e");
      return null;
    }
  }

  /// Calculates sensor rotation
  static InputImageRotation getImageRotation(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}
