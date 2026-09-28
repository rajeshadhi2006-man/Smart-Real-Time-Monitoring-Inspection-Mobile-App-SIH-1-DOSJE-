import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/assignment_model.dart';
import '../models/inspection_model.dart';
import '../models/alert_model.dart';
import '../services/auth_service.dart';
import '../services/inspection_service.dart';
import '../services/geofence_service.dart';
import '../services/verification_service.dart';
import '../services/location_service.dart';

// Services Providers
final authServiceProvider = Provider((ref) => AuthService());
final inspectionServiceProvider = Provider((ref) => InspectionService());
final geofenceServiceProvider = Provider((ref) => GeofenceService());
final verificationServiceProvider = Provider((ref) => VerificationService());

// User & Auth Provider
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    checkSavedUser();
  }

  Future<void> checkSavedUser() async {
    try {
      final user = await _authService.getSavedUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(username, password);
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Assignments Provider
final assignmentsProvider = FutureProvider<List<AssignmentModel>>((ref) async {
  final service = ref.watch(inspectionServiceProvider);
  final user = ref.watch(authProvider).valueOrNull;
  return await service.getMyAssignments(userId: user?.user_id);
});

// Selected Assignment Provider
final selectedAssignmentProvider = StateProvider<AssignmentModel?>((ref) => null);

// Live Position Stream Provider
final positionStreamProvider = StreamProvider<Position>((ref) {
  return LocationService.getPositionStream();
});

// Geofence State & Distance Provider
class GeofenceStateNotifier extends StateNotifier<GeofenceStatusUpdate?> {
  final GeofenceService _geofenceService;
  Position? _lastPos;
  String? _lastAssignmentId;

  GeofenceStateNotifier(this._geofenceService) : super(null);

  Future<void> updatePosition(Position position, AssignmentModel assignment, String userId) async {
    // Avoid redundant calculation if movement is under 10 meters for the same assignment
    if (_lastPos != null && _lastAssignmentId == assignment.id) {
      final delta = LocationService.calculateDistanceMeters(
        _lastPos!.latitude,
        _lastPos!.longitude,
        position.latitude,
        position.longitude,
      );
      if (delta < 10.0) return;
    }
    _lastPos = position;
    _lastAssignmentId = assignment.id;

    final status = await _geofenceService.processPositionUpdate(
      userPosition: position,
      assignment: assignment,
      userId: userId,
    );
    state = status;
  }
}

final geofenceStateProvider = StateNotifierProvider<GeofenceStateNotifier, GeofenceStatusUpdate?>((ref) {
  return GeofenceStateNotifier(ref.watch(geofenceServiceProvider));
});

// Inspections List Provider
final inspectionsProvider = FutureProvider<List<InspectionModel>>((ref) async {
  final service = ref.watch(inspectionServiceProvider);
  return await service.getMyInspections();
});

// Verification State Provider
final verificationResultProvider = StateProvider<VerificationResult?>((ref) => null);

// Alerts List Provider
final alertsProvider = StateProvider<List<AlertModel>>((ref) => []);
