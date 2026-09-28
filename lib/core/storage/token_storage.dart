import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage service utilizing Android KeyStore & iOS Keychain
class TokenStorage {
  final _storage = const FlutterSecureStorage();

  static const String _keyJwtToken = 'gov_officer_jwt_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _keyJwtToken);
  }
}
