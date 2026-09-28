import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../models/face_enrollment_model.dart';

import '../models/face_verification_result.dart';
import '../services/face_verification_service.dart';

final faceVerificationServiceProvider = Provider((ref) => FaceVerificationService());

// User Enrollment Status Provider
final faceEnrollmentStatusProvider = FutureProvider.autoDispose.family<FaceEnrollmentStatus, String>((ref, userId) async {
  final service = ref.watch(faceVerificationServiceProvider);
  final user = ref.watch(authProvider).valueOrNull;
  final officerId = user?.officerId;
  return await service.checkEnrollmentStatus(userId, officerId);
});

// Face Verification Active Result State
final activeFaceVerificationResultProvider = StateProvider<FaceVerificationResult?>((ref) => null);

