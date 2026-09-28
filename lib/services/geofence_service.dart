import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'location_service.dart';
import '../core/config/api_config.dart';
import '../models/assignment_model.dart';

enum GeofenceState { outside, entered, inside, exited }

class GeofenceStatusUpdate {
  final GeofenceState state;
  final double distanceMeters;
  final String message;

  GeofenceStatusUpdate({
    required this.state,
    required this.distanceMeters,
    required this.message,
  });
}

class GeofenceService {
  final ApiService _apiService = ApiService();
  GeofenceState _currentState = GeofenceState.outside;

  GeofenceState get currentState => _currentState;

  // Calculates status and auto-posts attendance entry/exit to backend
  Future<GeofenceStatusUpdate> processPositionUpdate({
    required Position userPosition,
    required AssignmentModel assignment,
    required String userId,
  }) async {
    final distance = LocationService.calculateDistanceMeters(
      userPosition.latitude,
      userPosition.longitude,
      assignment.latitude,
      assignment.longitude,
    );

    final bool isInsideRadius = distance <= assignment.radiusMeters;
    GeofenceState newState = _currentState;
    String message = "";

    if (isInsideRadius) {
      if (_currentState == GeofenceState.outside || _currentState == GeofenceState.exited) {
        newState = GeofenceState.entered;
        message = "You have entered the assigned working area.";
        // Trigger automated entry check-in to FastAPI
        await _recordGeofenceEntry(
          userId: userId,
          assignment: assignment,
          latitude: userPosition.latitude,
          longitude: userPosition.longitude,
          accuracy: userPosition.accuracy,
        );
        _currentState = GeofenceState.inside;
      } else {
        newState = GeofenceState.inside;
        message = "Inside assigned working area.";
      }
    } else {
      if (_currentState == GeofenceState.inside || _currentState == GeofenceState.entered) {
        newState = GeofenceState.exited;
        message = "You have exited the assigned working area.";
        // Trigger automated exit check-out to FastAPI
        await _recordGeofenceExit(
          userId: userId,
          assignment: assignment,
          latitude: userPosition.latitude,
          longitude: userPosition.longitude,
          accuracy: userPosition.accuracy,
        );
        _currentState = GeofenceState.outside;
      } else {
        newState = GeofenceState.outside;
        message = "You are outside the assigned working area.";
      }
    }

    return GeofenceStatusUpdate(
      state: newState,
      distanceMeters: distance,
      message: message,
    );
  }

  Future<void> _recordGeofenceEntry({
    required String userId,
    required AssignmentModel assignment,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      await _apiService.post(
        ApiConfig.geofenceEntryUrl,
        data: {
          'user_id': userId,
          'officer_id': userId,
          'geofence_id': assignment.geofenceId.isNotEmpty ? assignment.geofenceId : assignment.id,
          'geofence_name': assignment.geofenceName.isNotEmpty ? assignment.geofenceName : assignment.title,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'event_type': 'ENTRY',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  Future<void> _recordGeofenceExit({
    required String userId,
    required AssignmentModel assignment,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      await _apiService.post(
        ApiConfig.geofenceExitUrl,
        data: {
          'user_id': userId,
          'officer_id': userId,
          'geofence_id': assignment.geofenceId.isNotEmpty ? assignment.geofenceId : assignment.id,
          'geofence_name': assignment.geofenceName.isNotEmpty ? assignment.geofenceName : assignment.title,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'event_type': 'EXIT',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {}
  }
}
