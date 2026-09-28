import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) await openAppSettings();
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) await openAppSettings();
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) await openAppSettings();
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, bool>> checkAllPermissionsStatus() async {
    if (kIsWeb) {
      return {
        'location': true,
        'camera': true,
        'microphone': true,
        'notification': true,
      };
    }
    try {
      final location = await Permission.locationWhenInUse.status;
      final camera = await Permission.camera.status;
      final mic = await Permission.microphone.status;
      final notification = await Permission.notification.status;

      return {
        'location': location.isGranted,
        'camera': camera.isGranted,
        'microphone': mic.isGranted,
        'notification': notification.isGranted,
      };
    } catch (_) {
      return {
        'location': true,
        'camera': true,
        'microphone': true,
        'notification': true,
      };
    }
  }
}
