import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../auth/url_token_helper.dart';
import '../models/user_model.dart';
import '../services/user_api_service.dart';

/// All possible states of authentication.
enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  tokenExpired,
  authenticationError,
}

/// Centralized state management for authentication and the current user profile.
class AuthProvider extends ChangeNotifier {
  final AuthStorage _authStorage;
  final UserApiService _userApiService;

  AuthStatus _status = AuthStatus.unauthenticated;
  UserModel? _user;
  String? _errorMessage;
  bool _isInitializing = false;
  Future<void>? _pendingFetch;

  AuthProvider({AuthStorage? authStorage, UserApiService? userApiService})
    : _authStorage = authStorage ?? AuthStorage(),
      _userApiService =
          userApiService ??
          UserApiService(authStorage: authStorage ?? AuthStorage());

  AuthStorage get authStorage => _authStorage;
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get hasError =>
      _status == AuthStatus.authenticationError ||
      _status == AuthStatus.tokenExpired;

  /// Main initialization flow executed when Bit Tool starts:
  /// 1. Inspect URL for ?token=...
  /// 2. If found, save to AuthStorage and remove from visible URL.
  /// 3. If token exists in storage, call GET /api/users/me.
  /// 4. If no token, set unauthenticated state.
  Future<void> initializeAuth() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // 1. Check for SSO token in URL redirect
      final urlToken = UrlTokenHelper.extractAndClearToken();
      if (urlToken != null && urlToken.trim().isNotEmpty) {
        await _authStorage.saveToken(urlToken.trim());
      }

      // 2. Check for persisted token
      final storedToken = await _authStorage.getToken();
      if (storedToken == null || storedToken.trim().isEmpty) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _errorMessage = null;
        notifyListeners();
        return;
      }

      // 3. Fetch authenticated user profile
      await fetchCurrentUser();
    } finally {
      _isInitializing = false;
    }
  }

  /// Fetches the authenticated user profile from GET /api/users/me.
  /// Deduplicates concurrent calls.
  Future<void> fetchCurrentUser({bool isRetry = false}) {
    if (_pendingFetch != null) {
      return _pendingFetch!;
    }

    _pendingFetch = _executeFetchCurrentUser();
    return _pendingFetch!;
  }

  Future<void> _executeFetchCurrentUser() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedUser = await _userApiService.getCurrentUser();
      _user = fetchedUser;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } on UnauthorizedException catch (e) {
      // 401: Token invalid or expired. Clear token and user state without infinite retries.
      await _authStorage.removeToken();
      _user = null;
      _status = AuthStatus.tokenExpired;
      _errorMessage = e.message;
    } on ForbiddenException catch (e) {
      // 403: Preserve token, display permission error
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
    } on ServerException catch (e) {
      // 500-504: Friendly server error with retry
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
    } on NetworkException catch (e) {
      // Connection failure with retry
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
    } on RequestTimeoutException catch (e) {
      // Timeout with retry
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
    } on ApiException catch (e) {
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
    } catch (_) {
      _status = AuthStatus.authenticationError;
      _errorMessage = 'Unable to connect to Bit Tool services right now.';
    } finally {
      _pendingFetch = null;
      notifyListeners();
    }
  }

  /// Retries fetching the current user profile.
  Future<void> retry() async {
    await fetchCurrentUser(isRetry: true);
  }

  /// Authenticates using email and password.
  /// Sets error message to 'Invalid Credentials' on credential failure.
  Future<bool> signIn({required String email, required String password}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _userApiService.login(
        email: email,
        password: password,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on InvalidCredentialsException catch (e) {
      _user = null;
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } on UnauthorizedException {
      _user = null;
      _status = AuthStatus.authenticationError;
      _errorMessage = 'Invalid Credentials';
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } on RequestTimeoutException catch (e) {
      _status = AuthStatus.authenticationError;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _status = AuthStatus.authenticationError;
      _errorMessage =
          e.message.toLowerCase().contains('credential') ||
              e.message.toLowerCase().contains('invalid')
          ? 'Invalid Credentials'
          : e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.authenticationError;
      _errorMessage = 'Invalid Credentials';
      notifyListeners();
      return false;
    }
  }

  /// Clears any transient error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clears local session and resets auth state.
  Future<void> signOut() async {
    await _authStorage.removeToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
