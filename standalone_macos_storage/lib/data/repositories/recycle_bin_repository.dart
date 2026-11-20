import '../../core/network/api_client.dart';
import 'storage_repository.dart';

/// Repository for handling Recycle Bin file restore and permanent deletion.
class RecycleBinRepository {
  /// Restores an item back to its origin application.
  /// For Bnx mail, calls POST /api/mail/restore/{id} (or fallback POST /api/mail/unarchive/{id}).
  static Future<bool> restoreItem(String id, {String app = 'Bnx mail'}) async {
    try {
      if (app == 'Bnx mail') {
        try {
          await ApiClient.post('/api/mail/restore/$id');
          return true;
        } catch (_) {
          await ApiClient.post('/api/mail/unarchive/$id');
          return true;
        }
      }
      return true;
    } catch (e) {
      StorageDebug.log('[RECYCLE BIN ERROR] Failed to restore $id: $e');
      rethrow;
    }
  }

  /// Permanently deletes an item from the system.
  /// For Bnx mail, calls DELETE /api/mail/permanent/{id}?folder=Trash.
  static Future<bool> permanentlyDeleteItem(String id, {String app = 'Bnx mail'}) async {
    try {
      if (app == 'Bnx mail') {
        await ApiClient.delete(
          '/api/mail/permanent/$id',
          queryParams: {'folder': 'Trash'},
        );
        return true;
      }
      return true;
    } catch (e) {
      StorageDebug.log('[RECYCLE BIN ERROR] Failed to delete permanently $id: $e');
      rethrow;
    }
  }
}
