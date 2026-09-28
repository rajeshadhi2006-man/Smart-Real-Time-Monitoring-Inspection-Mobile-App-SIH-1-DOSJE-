import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../core/config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel?> login(String username, String password) async {
    final response = await _apiService.post(
      ApiConfig.loginUrl,
      data: {'username': username.trim(), 'password': password},
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      final token = data['access_token'];
      final userData = data['user'];

      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
      }
      if (userData != null) {
        await _storage.write(key: 'user_profile', value: jsonEncode(userData));
        return UserModel.fromJson(userData);
      }
    }
    return null;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) return null;

      final response = await _apiService.get(ApiConfig.meUrl);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data;
        await _storage.write(key: 'user_profile', value: jsonEncode(userData));
        return UserModel.fromJson(userData);
      }
    } catch (_) {
      // Return cached user if network temporarily unavailable
      return await _getCachedUser();
    }
    return null;
  }

  Future<UserModel?> _getCachedUser() async {
    try {
      final userJson = await _storage.read(key: 'user_profile');
      if (userJson != null) {
        return UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel?> getSavedUser() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) return null;
    return await getCurrentUser();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.logoutUrl);
    } catch (_) {}
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_profile');
  }
}

