import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/auth/auth_storage.dart';
import '../../../manage_account/core/network/token_service.dart' as ma;

/// Secure token & session persistence manager for the Storage suite.
/// Works out-of-the-box on macOS, Windows, Linux, Android, iOS, and Web.
class TokenService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  static const _kAccess = 'bnx_access_token';
  static const _kRefresh = 'bnx_refresh_token';
  static const _kEmail = 'bnx_user_email';
  static const _kName = 'bnx_user_name';
  static const _kAvatar = 'bnx_user_avatar';

  static bool get _useFallbackDirectly =>
      kIsWeb || (Platform.isMacOS || Platform.isLinux || Platform.isWindows);

  // ── Resilient Fallback Storage ───────────────────────────────────────────
  static final Map<String, String> _memoryFallback = {};
  static bool _fallbackLoaded = false;

  static File? _resolveFallbackFile() {
    try {
      if (kIsWeb) return null;
      Directory? baseDir;
      if (Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          baseDir = Directory('$home/Library/Application Support/com.bit-tool.com');
          if (!baseDir.existsSync()) {
            final legacy = Directory('$home/Library/Application Support/com.bnxmail.app');
            if (legacy.existsSync()) baseDir = legacy;
          }
        }
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          baseDir = Directory('$home/.config/com.bit-tool.com');
          if (!baseDir.existsSync()) {
            final legacy = Directory('$home/.config/com.bnxmail.app');
            if (legacy.existsSync()) baseDir = legacy;
          }
        }
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          baseDir = Directory('$appData/com.bit-tool.com');
          if (!baseDir.existsSync()) {
            final legacy = Directory('$appData/com.bnxmail.app');
            if (legacy.existsSync()) baseDir = legacy;
          }
        }
      }
      baseDir ??= Directory('${Directory.systemTemp.path}/com.bit-tool.com');
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
      }
      return File('${baseDir.path}/.bnx_storage_store.json');
    } catch (_) {
      return null;
    }
  }

  static void _ensureFallbackLoaded() {
    if (_fallbackLoaded) return;
    _fallbackLoaded = true;
    try {
      final file = _resolveFallbackFile();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              if (k != null && v != null) {
                _memoryFallback[k.toString()] = v.toString();
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  static void _persistFallback() {
    try {
      final file = _resolveFallbackFile();
      if (file != null) {
        file.writeAsStringSync(jsonEncode(_memoryFallback), flush: true);
      }
    } catch (_) {}
  }

  static Future<void> _writeKey(String key, String value) async {
    _ensureFallbackLoaded();
    _memoryFallback[key] = value;
    _persistFallback();
    if (!_useFallbackDirectly) {
      try {
        await _storage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  static Future<String?> _readKey(String key) async {
    _ensureFallbackLoaded();
    if (_useFallbackDirectly) {
      return _memoryFallback[key];
    }
    try {
      final val = await _storage.read(key: key);
      return val ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  static Future<void> _deleteKey(String key) async {
    _ensureFallbackLoaded();
    _memoryFallback.remove(key);
    _persistFallback();
    if (!_useFallbackDirectly) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
  }

  // ── Public Accessors ─────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _writeKey(_kAccess, accessToken);
    if (refreshToken != null) {
      await _writeKey(_kRefresh, refreshToken);
    }
  }

  static Future<String?> getAccessToken([String? forEmail]) async {
    // 1. If an explicit email is requested, lookup that account's token directly from registry
    if (forEmail != null && forEmail.trim().isNotEmpty) {
      final clean = forEmail.trim().toLowerCase();
      try {
        final accounts = await ma.TokenService.getSavedAccountsFromRegistry();
        final match = accounts.firstWhere(
          (a) => a['email']?.toString().trim().toLowerCase() == clean,
          orElse: () => {},
        );
        final token = match['accessToken']?.toString();
        if (token != null && token.trim().isNotEmpty && token.trim() != 'mock_sso_token') {
          return token.trim();
        }
      } catch (_) {}
    }

    // 2. Query current active email from manage_account TokenService
    String? activeEmail;
    try {
      activeEmail = await ma.TokenService.getUserEmail();
    } catch (_) {}

    if (activeEmail != null && activeEmail.trim().isNotEmpty) {
      final clean = activeEmail.trim().toLowerCase();
      try {
        final accounts = await ma.TokenService.getSavedAccountsFromRegistry();
        final match = accounts.firstWhere(
          (a) => a['email']?.toString().trim().toLowerCase() == clean,
          orElse: () => {},
        );
        final token = match['accessToken']?.toString();
        if (token != null && token.trim().isNotEmpty && token.trim() != 'mock_sso_token') {
          return token.trim();
        }
      } catch (_) {}
    }

    // 3. Check active token in manage_account TokenService
    try {
      final maToken = await ma.TokenService.getAccessToken();
      if (maToken != null && maToken.trim().isNotEmpty && maToken.trim() != 'mock_sso_token') {
        return maToken.trim();
      }
    } catch (_) {}

    // 4. Check Bit Tool AuthStorage
    try {
      final ssoToken = await AuthStorage().getToken();
      if (ssoToken != null && ssoToken.trim().isNotEmpty && ssoToken.trim() != 'mock_sso_token') {
        return ssoToken.trim();
      }
    } catch (_) {}

    // 5. Fallback to local storage store
    final token = await _readKey(_kAccess);
    if (token != null && token.isNotEmpty) {
      return token;
    }

    return null;
  }

  static Future<String?> getRefreshToken() async => _readKey(_kRefresh);

  static Future<void> saveUserEmail(String email) async => _writeKey(_kEmail, email);
  static Future<String?> getUserEmail() async {
    final email = await _readKey(_kEmail);
    if (email != null && email.isNotEmpty) return email;
    try {
      return await ma.TokenService.getUserEmail();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserName(String name) async => _writeKey(_kName, name);
  static Future<String?> getUserName() async {
    final name = await _readKey(_kName);
    if (name != null && name.isNotEmpty) return name;
    try {
      return await ma.TokenService.getUserName();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserAvatar(String avatarUrl) async => _writeKey(_kAvatar, avatarUrl);
  static Future<String?> getUserAvatar([String? email]) async {
    final avatar = await _readKey(_kAvatar);
    if (avatar != null && avatar.isNotEmpty) return avatar;
    try {
      if (email != null && email.isNotEmpty) {
        return await ma.TokenService.getUserAvatar(email);
      }
      final curEmail = await getUserEmail();
      if (curEmail != null && curEmail.isNotEmpty) {
        return await ma.TokenService.getUserAvatar(curEmail);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    await _deleteKey(_kAccess);
    await _deleteKey(_kRefresh);
    await _deleteKey(_kEmail);
    await _deleteKey(_kName);
    await _deleteKey(_kAvatar);
  }
}
