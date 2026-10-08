// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'auth_storage.dart';

/// Web implementation of [AuthStorage] storing directly in [html.window.localStorage]
/// with exact key `bnx_auth_token`.
class AuthStorageWeb implements AuthStorage {
  @override
  Future<void> saveToken(String token) async {
    html.window.localStorage[AuthStorage.tokenKey] = token;
  }

  @override
  Future<String?> getToken() async {
    return html.window.localStorage[AuthStorage.tokenKey];
  }

  @override
  Future<void> removeToken() async {
    html.window.localStorage.remove(AuthStorage.tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = html.window.localStorage[AuthStorage.tokenKey];
    return token != null && token.trim().isNotEmpty;
  }
}

AuthStorage createAuthStorage() => AuthStorageWeb();
