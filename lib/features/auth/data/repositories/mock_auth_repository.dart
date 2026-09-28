import 'dart:async';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// Isolated Enterprise Mock Auth Repository for resilient offline testing & field demonstration
class MockAuthRepository implements AuthRepository {
  final StreamController<UserProfile?> _authStateController =
      StreamController<UserProfile?>.broadcast();

  UserProfile? _currentUser;

  MockAuthRepository() {
    // Default demo session for immediate verification
    _currentUser = const UserProfile(
      id: 'USR-MOSJE-001',
      email: 'rajesh.pmu@mosje.gov.in',
      fullName: 'Rajesh Sharma',
      officerId: 'PMU-TN-2026-08',
      role: UserRole.pmuOfficer,
      department: 'Department of Social Justice and Empowerment',
      assignedDistrict: 'Coimbatore',
      phone: '+91 98401 23456',
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserProfile> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    final isDepartment = email.contains('dept') || email.contains('director');
    final isStaff = email.contains('staff') || email.contains('project');

    _currentUser = UserProfile(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
      officerId: 'MOSJE-INSP-${email.hashCode.abs().toString().substring(0, 4)}',
      role: isDepartment
          ? UserRole.departmentOfficial
          : isStaff
              ? UserRole.projectStaff
              : UserRole.inspectionOfficer,
      department: 'Ministry of Social Justice and Empowerment',
      assignedDistrict: 'Coimbatore',
      phone: '+91 98765 43210',
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Simulation succeeded
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;
}
