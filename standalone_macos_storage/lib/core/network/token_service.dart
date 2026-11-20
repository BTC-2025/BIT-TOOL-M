import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static String? cachedAccessToken;

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
          baseDir = Directory('$home/Library/Application Support/com.bnxmail.app');
        }
      } else if (Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          baseDir = Directory('$home/.config/com.bnxmail.app');
        }
      } else if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          baseDir = Directory('$appData/com.bnxmail.app');
        }
      }
      baseDir ??= Directory('${Directory.systemTemp.path}/com.bnxmail.app');
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
    cachedAccessToken = accessToken;
    await _writeKey(_kAccess, accessToken);
    if (refreshToken != null) {
      await _writeKey(_kRefresh, refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    if (cachedAccessToken != null && cachedAccessToken!.isNotEmpty) {
      return cachedAccessToken;
    }
    final token = await _readKey(_kAccess);
    cachedAccessToken = token;
    return token;
  }

  static Future<String?> getRefreshToken() async => _readKey(_kRefresh);

  static Future<void> saveUserEmail(String email) async => _writeKey(_kEmail, email);
  static Future<String?> getUserEmail() async => _readKey(_kEmail);

  static Future<void> saveUserName(String name) async => _writeKey(_kName, name);
  static Future<String?> getUserName() async => _readKey(_kName);

  static Future<void> saveUserAvatar(String avatarUrl) async => _writeKey(_kAvatar, avatarUrl);
  static Future<String?> getUserAvatar() async => _readKey(_kAvatar);

  static Future<void> clearAll() async {
    cachedAccessToken = null;
    await _deleteKey(_kAccess);
    await _deleteKey(_kRefresh);
    await _deleteKey(_kEmail);
    await _deleteKey(_kName);
    await _deleteKey(_kAvatar);
  }
}
