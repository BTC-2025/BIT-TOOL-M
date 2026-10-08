import 'package:shared_preferences/shared_preferences.dart';
import 'auth_storage.dart';

/// Non-web (mobile/desktop) implementation of [AuthStorage] using [SharedPreferences].
class AuthStorageIo implements AuthStorage {
  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthStorage.tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AuthStorage.tokenKey);
  }

  @override
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthStorage.tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }
}

AuthStorage createAuthStorage() => AuthStorageIo();
