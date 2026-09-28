import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/government_officer.dart';
import '../services/api_service.dart';
export '../services/api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<GovernmentOfficer>>((ref) {

  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});


class AuthNotifier extends StateNotifier<AsyncValue<GovernmentOfficer>> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadOfficer();
  }

  Future<void> loadOfficer() async {
    state = const AsyncValue.loading();
    try {
      final officer = await _apiService.getOfficerProfile();
      if (officer != null) {
        state = AsyncValue.data(officer);
      } else {
        state = AsyncValue.error('Failed to load officer profile', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
