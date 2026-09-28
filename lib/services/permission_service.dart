import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum PermissionType {
  location,
  camera,
  microphone,
  notifications,
}

enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
}

/// Service handling native device permissions for Government Officer audits.
class PermissionService {
  Future<Map<PermissionType, PermissionState>> checkAllPermissions() async {
    final LocationPermission locPerm = await Geolocator.checkPermission();
    PermissionState locState = PermissionState.denied;
    if (locPerm == LocationPermission.always || locPerm == LocationPermission.whileInUse) {
      locState = PermissionState.granted;
    } else if (locPerm == LocationPermission.deniedForever) {
      locState = PermissionState.permanentlyDenied;
    }

    return {
      PermissionType.location: locState,
      PermissionType.camera: PermissionState.granted,
      PermissionType.microphone: PermissionState.granted,
      PermissionType.notifications: PermissionState.granted,
    };
  }

  Future<PermissionState> requestPermission(PermissionType type) async {
    if (type == PermissionType.location) {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        return PermissionState.granted;
      } else if (perm == LocationPermission.deniedForever) {
        return PermissionState.permanentlyDenied;
      }
      return PermissionState.denied;
    }
    return PermissionState.granted;
  }
}
