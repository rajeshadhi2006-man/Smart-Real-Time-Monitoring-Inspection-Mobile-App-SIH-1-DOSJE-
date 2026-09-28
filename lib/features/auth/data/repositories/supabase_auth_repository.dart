import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import 'mock_auth_repository.dart';

/// Supabase Authentication Implementation with automatic mock fallback
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient? _client;
  final MockAuthRepository _mockFallback = MockAuthRepository();

  SupabaseAuthRepository([this._client]);

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (_client == null) {
      return _mockFallback.getCurrentUser();
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return _mockFallback.getCurrentUser();
    }

    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserProfile.fromJson(data);
      }

      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String? ?? 'Officer',
        officerId: user.userMetadata?['officer_id'] as String? ?? 'MOSJE-INSP',
        role: UserRole.fromString(user.userMetadata?['role'] as String?),
        department: 'Department of Social Justice and Empowerment',
        assignedDistrict: 'Coimbatore',
      );
    } catch (_) {
      return _mockFallback.getCurrentUser();
    }
  }

  @override
  Future<UserProfile> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      return _mockFallback.loginWithEmailPassword(
        email: email,
        password: password,
      );
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('User authentication failed on Supabase.');
      }

      final profile = await getCurrentUser();
      return profile ??
          UserProfile(
            id: user.id,
            email: user.email ?? email,
            fullName: 'Inspection Officer',
            officerId: 'MOSJE-2026',
            role: UserRole.inspectionOfficer,
            department: 'MoSJE',
            assignedDistrict: 'Coimbatore',
          );
    } catch (e) {
      // Fallback for demo credentials if network or invalid credentials
      return _mockFallback.loginWithEmailPassword(
        email: email,
        password: password,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (_client == null) {
      return _mockFallback.sendPasswordResetEmail(email);
    }
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> logout() async {
    if (_client != null) {
      await _client.auth.signOut();
    }
    await _mockFallback.logout();
  }

  @override
  Stream<UserProfile?> get authStateChanges => _mockFallback.authStateChanges;
}
