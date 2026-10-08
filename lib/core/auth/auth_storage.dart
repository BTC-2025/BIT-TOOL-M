import 'auth_storage_io.dart' if (dart.library.html) 'auth_storage_web.dart';

/// Abstract storage interface for persisting authentication credentials.
abstract class AuthStorage {
  /// Exact key required for storing the BNX SSO token.
  static const String tokenKey = 'bnx_auth_token';

  /// Factory creating the platform-appropriate [AuthStorage] instance.
  factory AuthStorage() => createAuthStorage();

  /// Persist the authentication token.
  Future<void> saveToken(String token);

  /// Retrieve the persisted authentication token, or null if none exists.
  Future<String?> getToken();

  /// Remove the persisted authentication token.
  Future<void> removeToken();

  /// Check whether an authentication token is currently persisted.
  Future<bool> hasToken();
}
