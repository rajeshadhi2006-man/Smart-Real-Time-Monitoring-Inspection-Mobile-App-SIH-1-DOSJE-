import 'package:camera/camera.dart';

/// Helper utility for robust device camera discovery, strictly filtering out
/// Phone Link, Link to Windows, OBS, and all virtual/emulated cameras,
/// and prioritizing genuine physical device cameras (integrated laptop webcam, device front camera).
class DeviceCameraHelper {
  /// Check if a camera description corresponds to Phone Link, Link to Windows, or virtual cameras
  static bool isVirtualOrPhoneLink(CameraDescription cam) {
    final name = cam.name.toLowerCase();
    return name.contains('phone link') ||
        name.contains('phonelink') ||
        name.contains('phone-link') ||
        name.contains('link to windows') ||
        name.contains('link windows') ||
        name.contains('link_to_windows') ||
        name.contains('link to phone') ||
        name.contains('your phone') ||
        name.contains('yourphone') ||
        name.contains('mobile link') ||
        name.contains('obs virtual') ||
        name.contains('obs-camera') ||
        name.contains('obs') ||
        name.contains('droidcam') ||
        name.contains('iriun') ||
        name.contains('epoccam') ||
        name.contains('camo') ||
        name.contains('manycam') ||
        name.contains('splitcam') ||
        name.contains('synthetic') ||
        name.contains('screen-capture') ||
        (name.contains('virtual') && !name.contains('android'));
  }

  /// Strictly filters out Phone Link, Link to Windows, and any virtual cameras.
  /// Guarantees that only genuine physical device cameras are used in the options.
  static List<CameraDescription> filterDeviceCameras(List<CameraDescription> cameras) {
    if (cameras.isEmpty) return cameras;

    // Keep only physical device cameras
    final physical = cameras.where((cam) => !isVirtualOrPhoneLink(cam)).toList();
    if (physical.isNotEmpty) {
      return physical;
    }

    // Fallback only if no other cameras exist
    return cameras;
  }

  /// Select the optimal physical laptop / device camera from available cameras
  static int getBestCameraIndex(List<CameraDescription> cameras) {
    if (cameras.isEmpty) return 0;

    // 1. First priority: Physical front-facing camera that is NOT Phone Link / Virtual
    for (int i = 0; i < cameras.length; i++) {
      final cam = cameras[i];
      if (!isVirtualOrPhoneLink(cam) && cam.lensDirection == CameraLensDirection.front) {
        return i;
      }
    }

    // 2. Second priority: Integrated laptop webcam or internal camera with keywords
    for (int i = 0; i < cameras.length; i++) {
      final cam = cameras[i];
      if (!isVirtualOrPhoneLink(cam)) {
        final name = cam.name.toLowerCase();
        if (name.contains('integrated') ||
            name.contains('internal') ||
            name.contains('webcam') ||
            name.contains('front') ||
            name.contains('hd') ||
            name.contains('user') ||
            name.contains('camera 0')) {
          return i;
        }
      }
    }

    // 3. Third priority: Any non-virtual, non-Phone Link physical camera
    for (int i = 0; i < cameras.length; i++) {
      if (!isVirtualOrPhoneLink(cameras[i])) {
        return i;
      }
    }

    // 4. Fallback: First camera in list
    return 0;
  }

  /// User-friendly label for camera display (only physical device camera labels)
  static String getDisplayName(CameraDescription cam) {
    final name = cam.name;
    final lower = name.toLowerCase();
    if (lower.contains('asus') ||
        lower.contains('integrated') ||
        lower.contains('webcam') ||
        lower.contains('internal') ||
        lower.contains('laptop') ||
        lower.contains('wide vision') ||
        lower.contains('facetime')) {
      return "Integrated Laptop Webcam";
    }
    if (cam.lensDirection == CameraLensDirection.front) {
      return "Device Front Camera";
    }
    if (cam.lensDirection == CameraLensDirection.back) {
      return "Device Rear Camera";
    }
    if (cam.lensDirection == CameraLensDirection.external) {
      return "External USB Camera";
    }
    return name.isNotEmpty ? name : "Physical Device Camera";
  }
}

