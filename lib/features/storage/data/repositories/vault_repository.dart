import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/token_service.dart';
import '../../models/vault_file.dart';
import 'storage_repository.dart';

/// Repository for handling Mail Backup & Data Vault APIs
class VaultRepository {
  /// GET /api/vault
  /// Fetches list of all backed-up files in user's vault
  static Future<List<VaultFile>> listVaultFiles() async {
    try {
      final res = await ApiClient.get('/api/vault');
      final dynamic rawList = res['data'] ?? res;
      if (rawList is List) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => VaultFile.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      StorageDebug.log('[VAULT ERROR] Failed to list vault files: $e');
      rethrow;
    }
  }

  /// POST /api/vault/upload
  /// Uploads and stores a backup archive or file in the Vault (multipart/form-data)
  static Future<VaultFile> uploadVaultFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const ApiException(statusCode: 400, message: 'Selected file does not exist.');
      }

      final uri = Uri.parse('${ApiClient.baseUrl}/api/vault/upload');
      final token = await TokenService.getAccessToken();

      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Upload failed: ${response.body}',
        );
      }

      return VaultFile(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        filename: file.uri.pathSegments.last,
        contentType: 'application/octet-stream',
        size: await file.length(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      StorageDebug.log('[VAULT ERROR] Failed to upload vault file: $e');
      rethrow;
    }
  }

  /// DELETE /api/vault/{id}
  /// Deletes a backup from the Vault
  static Future<bool> deleteVaultFile(int id) async {
    try {
      final res = await ApiClient.delete('/api/vault/$id');
      return res['message'] != null || res['success'] == true;
    } catch (e) {
      StorageDebug.log('[VAULT ERROR] Failed to delete vault file $id: $e');
      rethrow;
    }
  }

  /// GET /api/vault/{id}/download
  /// Downloads raw backup file binary stream
  static Future<List<int>> downloadVaultFile(int id) async {
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}/api/vault/$id/download');
      final token = await TokenService.getAccessToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to download backup file ($id)',
        );
      }
      return response.bodyBytes;
    } catch (e) {
      StorageDebug.log('[VAULT ERROR] Failed to download vault file $id: $e');
      rethrow;
    }
  }
}
