import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../models/storage_quota.dart';

class StorageDebug {
  static final List<String> logs = [];
  static void log(String s) {
    logs.add(s);
    print(s);
  }
}

/// Repository for handling real-time storage quota APIs.
class StorageRepository {
  static Future<StorageQuota>? _inFlightRequest;

  /// Resets in-flight request guard (used on account switch).
  static void resetInFlight() {
    _inFlightRequest = null;
  }

  /// Fetches real-time mailbox quota from GET /api/mail/storage-quota
  /// Deduplicates concurrent requests so only one HTTP request is active at a time.
  static Future<StorageQuota> fetchStorageQuota([String? email]) async {
    if (_inFlightRequest != null) {
      StorageDebug.log('[STORAGE] Duplicate request prevented');
      return _inFlightRequest!;
    }
    _inFlightRequest = _performFetch(email);
    try {
      return await _inFlightRequest!;
    } finally {
      _inFlightRequest = null;
    }
  }

  static Future<StorageQuota> _performFetch([String? email]) async {
    StorageDebug.log('[STORAGE] Fetching storage quota for ${email ?? 'active user'}...');
    try {
      final res = await ApiClient.get('/api/mail/storage-quota', email: email);
      final bool success = res['success'] == true;
      final dynamic data = res['data'];

      if (!success || data is! Map<String, dynamic>) {
        // Some backends return the data directly at top level
        if (res.containsKey('storageLimit') || res.containsKey('storageUsed')) {
          final quota = StorageQuota.fromJson(res);
          StorageDebug.log('[STORAGE] Quota loaded directly: ${quota.storageUsed}/${quota.storageLimit}');
          return quota;
        }
        throw ApiException(
          statusCode: 200,
          message: res['message']?.toString() ?? 'Invalid storage quota response',
        );
      }

      final quota = StorageQuota.fromJson(data);
      StorageDebug.log('[STORAGE] Quota loaded');
      StorageDebug.log('[STORAGE] Email: ${quota.email}');
      StorageDebug.log('[STORAGE] Used: ${quota.storageUsed} bytes');
      StorageDebug.log('[STORAGE] Limit: ${quota.storageLimit} bytes');
      StorageDebug.log('[STORAGE] Percentage: ${quota.storagePercentage}%');
      return quota;
    } catch (e) {
      StorageDebug.log('[STORAGE ERROR] Failed to fetch storage quota: $e');
      rethrow;
    }
  }

  /// Backward compatibility alias
  static Future<StorageQuota> getStorageQuota([String? email]) => fetchStorageQuota(email);
}
