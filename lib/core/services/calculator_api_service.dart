import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../models/calculator_models.dart';

/// Dedicated service responsible for Calculator backend API communications.
///
/// Supports Standard Calculator History and Compare Mode History endpoints
/// with authentication, multi-envelope JSON parsing, and sanitized diagnostics.
class CalculatorApiService {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  CalculatorApiService({ApiClient? apiClient, AuthStorage? authStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _authStorage = authStorage ?? AuthStorage();

  /// Retrieves the persisted authentication token or throws [UnauthorizedException].
  Future<String> _requireToken() async {
    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[CalculatorAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }
    if (!hasToken) {
      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Aborting request: no authentication token available in storage.',
        );
      }
      throw const UnauthorizedException('No authentication token available.');
    }
    return token.trim();
  }

  // ==========================================
  // Standard Calculator History Endpoints
  // ==========================================

  /// Fetches saved calculator history sessions (GET /history).
  Future<List<CalculatorSession>> getHistory() async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorHistoryUri;

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Fetching calculator history (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final rawList = _extractList(raw);
      final sessions = <CalculatorSession>[];

      for (final item in rawList) {
        if (item is Map) {
          try {
            final map = Map<String, dynamic>.from(item);
            sessions.add(CalculatorSession.fromJson(map));
          } catch (itemError) {
            if (kDebugMode) {
              debugPrint(
                '[CalculatorAPI] Error parsing session from payload: $itemError; raw item: $item',
              );
            }
          }
        }
      }

      _logDiagnostics(
        method: 'GET',
        uri: uri,
        rawJson: raw,
        rawRecords: rawList,
        parsedCount: sessions.length,
      );

      return sessions;
    } catch (e) {
      _logError('getHistory', e);
      rethrow;
    }
  }

  /// Fetches cross-app calculator history sessions across all applications (GET /history/all).
  Future<List<CalculatorSession>> getHistoryAll() async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorHistoryAllUri;

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Fetching cross-app calculator history (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final rawList = _extractList(raw);
      final sessions = <CalculatorSession>[];

      for (final item in rawList) {
        if (item is Map) {
          try {
            final map = Map<String, dynamic>.from(item);
            sessions.add(CalculatorSession.fromJson(map));
          } catch (itemError) {
            if (kDebugMode) {
              debugPrint(
                '[CalculatorAPI] Error parsing cross-app session from payload: $itemError; raw item: $item',
              );
            }
          }
        }
      }

      _logDiagnostics(
        method: 'GET',
        uri: uri,
        rawJson: raw,
        rawRecords: rawList,
        parsedCount: sessions.length,
      );

      return sessions;
    } catch (e) {
      _logError('getHistoryAll', e);
      rethrow;
    }
  }

  /// Creates a standard calculator session (POST /sessions).
  Future<CalculatorSession> createSession({
    required String title,
    String mode = 'business',
    String currency = 'INR',
    String? applicationName,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorSessionsUri;

    final payload = <String, dynamic>{
      'title': title.trim(),
      'mode': mode.trim(),
      'currency': currency.trim(),
      if (applicationName != null && applicationName.trim().isNotEmpty)
        'applicationName': applicationName.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Creating session "$title" (POST $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final session = CalculatorSession.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Session created successfully: ${session.id}',
        );
      }
      return session;
    } catch (e) {
      _logError('createSession', e);
      rethrow;
    }
  }

  /// Adds a tape item to an existing calculator session (POST /sessions/:sessionId/items).
  Future<CalculatorTapeItem> addSessionItem({
    required String sessionId,
    required int sequence,
    required double value,
    required String operator,
    required double runningTotal,
    String label = '',
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorSessionItemsUri(sessionId);

    final payload = <String, dynamic>{
      'sequence': sequence,
      'value': value,
      'operator': operator,
      'runningTotal': runningTotal,
      'label': label.trim(),
    };

    if (kDebugMode) {
      debugPrint(
        '[CalculatorAPI] Adding item to session $sessionId (seq $sequence: $operator $value = $runningTotal) (POST $uri)',
      );
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final item = CalculatorTapeItem.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalculatorAPI] Item added successfully: ${item.id}');
      }
      return item;
    } catch (e) {
      _logError('addSessionItem($sessionId)', e);
      rethrow;
    }
  }

  /// Fetches details and items for a specific session (GET /sessions/:id).
  Future<CalculatorSession> getSessionById(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorSessionUri(id);

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Fetching session $id (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final data = _extractMap(raw);
      final session = CalculatorSession.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Session $id fetched successfully (${session.items.length} items).',
        );
      }
      return session;
    } catch (e) {
      _logError('getSessionById($id)', e);
      rethrow;
    }
  }

  /// Deletes a specific calculator session (DELETE /sessions/:id).
  Future<bool> deleteSession(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorSessionUri(id);

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Deleting session $id (DELETE $uri)');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint('[CalculatorAPI] Session $id deleted successfully.');
      }
      return true;
    } catch (e) {
      _logError('deleteSession($id)', e);
      rethrow;
    }
  }

  /// Clears all standard calculator sessions (DELETE /sessions).
  Future<bool> clearAllSessions() async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorSessionsUri;

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Clearing all sessions (DELETE $uri)');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint('[CalculatorAPI] All sessions cleared successfully.');
      }
      return true;
    } catch (e) {
      _logError('clearAllSessions', e);
      rethrow;
    }
  }

  /// Alias for getSessionById.
  Future<CalculatorSession> getSessionDetails(String id) => getSessionById(id);

  /// Alias for clearAllSessions.
  Future<bool> clearHistory() => clearAllSessions();

  // ==========================================
  // Compare Mode History Endpoints
  // ==========================================

  /// Fetches comparison history (GET /compare/history).
  Future<List<CompareSession>> getCompareHistory() async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorCompareHistoryUri;

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Fetching compare history (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final rawList = _extractList(raw);
      final sessions = <CompareSession>[];

      for (final item in rawList) {
        if (item is Map) {
          try {
            final map = Map<String, dynamic>.from(item);
            sessions.add(CompareSession.fromJson(map));
          } catch (itemError) {
            if (kDebugMode) {
              debugPrint(
                '[CalculatorAPI] Error parsing compare session: $itemError; raw: $item',
              );
            }
          }
        }
      }

      _logDiagnostics(
        method: 'GET',
        uri: uri,
        rawJson: raw,
        rawRecords: rawList,
        parsedCount: sessions.length,
      );
      return sessions;
    } catch (e) {
      _logError('getCompareHistory', e);
      rethrow;
    }
  }

  /// Creates a compare session (POST /compare/sessions).
  Future<CompareSession> createCompareSession({
    required String title,
    String mode = 'compare',
    String currency = 'INR',
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorCompareSessionsUri;

    final payload = <String, dynamic>{
      'title': title.trim(),
      'mode': mode.trim(),
      'currency': currency.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Creating compare session "$title" (POST $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final session = CompareSession.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Compare session created successfully: ${session.id}',
        );
      }
      return session;
    } catch (e) {
      _logError('createCompareSession', e);
      rethrow;
    }
  }

  /// Adds a compare item to a compare session (POST /compare/sessions/:sessionId/items).
  Future<CompareItem> addCompareItem({
    required String sessionId,
    required String description,
    double? valueA,
    double? valueB,
    double qtyA = 1.0,
    double qtyB = 1.0,
    double discountA = 0.0,
    double discountB = 0.0,
    int sequence = 1,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorCompareSessionItemsUri(sessionId);

    final payload = <String, dynamic>{
      'description': description.trim(),
      if (valueA != null) 'valueA': valueA,
      if (valueB != null) 'valueB': valueB,
      'qtyA': qtyA,
      'qtyB': qtyB,
      'discountA': discountA,
      'discountB': discountB,
      'sequence': sequence,
    };

    if (kDebugMode) {
      debugPrint(
        '[CalculatorAPI] Adding compare item to session $sessionId (POST $uri)',
      );
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final item = CompareItem.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Compare item added successfully: ${item.id}',
        );
      }
      return item;
    } catch (e) {
      _logError('addCompareItem($sessionId)', e);
      rethrow;
    }
  }

  /// Updates an existing compare item (PUT /compare/sessions/:sessionId/items/:itemId).
  Future<CompareItem> updateCompareItem({
    required String sessionId,
    required String itemId,
    String? description,
    double? valueA,
    double? valueB,
    double? qtyA,
    double? qtyB,
    double? discountA,
    double? discountB,
    int? sequence,
  }) async {
    final token = await _requireToken();
    final uri =
        ApiConfig.calculatorCompareSessionItemUri(sessionId, itemId);

    final payload = <String, dynamic>{
      if (description != null) 'description': description.trim(),
      if (valueA != null) 'valueA': valueA,
      if (valueB != null) 'valueB': valueB,
      if (qtyA != null) 'qtyA': qtyA,
      if (qtyB != null) 'qtyB': qtyB,
      if (discountA != null) 'discountA': discountA,
      if (discountB != null) 'discountB': discountB,
      if (sequence != null) 'sequence': sequence,
    };

    if (kDebugMode) {
      debugPrint(
        '[CalculatorAPI] Updating compare item $itemId in session $sessionId (PUT $uri)',
      );
    }

    try {
      final dynamic raw =
          await _apiClient.put(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final item = CompareItem.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Compare item $itemId updated successfully.',
        );
      }
      return item;
    } catch (e) {
      _logError('updateCompareItem($sessionId, $itemId)', e);
      rethrow;
    }
  }

  /// Deletes a compare item (DELETE /compare/sessions/:sessionId/items/:itemId).
  Future<bool> deleteCompareItem({
    required String sessionId,
    required String itemId,
  }) async {
    final token = await _requireToken();
    final uri =
        ApiConfig.calculatorCompareSessionItemUri(sessionId, itemId);

    if (kDebugMode) {
      debugPrint(
        '[CalculatorAPI] Deleting compare item $itemId from session $sessionId (DELETE $uri)',
      );
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Compare item $itemId deleted successfully.',
        );
      }
      return true;
    } catch (e) {
      _logError('deleteCompareItem($sessionId, $itemId)', e);
      rethrow;
    }
  }

  /// Deletes a specific compare session (DELETE /compare/sessions/:id).
  Future<bool> deleteCompareSession(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorCompareSessionUri(id);

    if (kDebugMode) {
      debugPrint('[CalculatorAPI] Deleting compare session $id (DELETE $uri)');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] Compare session $id deleted successfully.',
        );
      }
      return true;
    } catch (e) {
      _logError('deleteCompareSession($id)', e);
      rethrow;
    }
  }

  /// Clears all compare history (DELETE /compare/history).
  Future<bool> clearCompareHistory() async {
    final token = await _requireToken();
    final uri = ApiConfig.calculatorCompareHistoryUri;

    if (kDebugMode) {
      debugPrint(
        '[CalculatorAPI] Clearing all compare history (DELETE $uri)',
      );
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint(
          '[CalculatorAPI] All compare history cleared successfully.',
        );
      }
      return true;
    } catch (e) {
      _logError('clearCompareHistory', e);
      rethrow;
    }
  }

  // ==========================================
  // Helper Envelope Extractors & Error Logger
  // ==========================================

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      } else if (map['session'] is Map) {
        return Map<String, dynamic>.from(map['session'] as Map);
      } else if (map['item'] is Map) {
        return Map<String, dynamic>.from(map['item'] as Map);
      }
      return map;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['rows'] is List) return map['rows'] as List;
      if (map['data'] is List) return map['data'] as List;
      if (map['sessions'] is List) return map['sessions'] as List;
      if (map['history'] is List) return map['history'] as List;
      if (map['items'] is List) return map['items'] as List;
      if (map['data'] is Map) {
        final d = Map<String, dynamic>.from(map['data'] as Map);
        if (d['rows'] is List) return d['rows'] as List;
        if (d['data'] is List) return d['data'] as List;
        if (d['sessions'] is List) return d['sessions'] as List;
        if (d['history'] is List) return d['history'] as List;
        if (d['items'] is List) return d['items'] as List;
      }
    }
    return [];
  }

  void _logDiagnostics({
    required String method,
    required Uri uri,
    required dynamic rawJson,
    required List<dynamic> rawRecords,
    required int parsedCount,
  }) {
    if (!kDebugMode) return;
    final topLevelKeys = rawJson is Map ? rawJson.keys.toList() : '<List>';
    String nestedInfo = '';
    if (rawJson is Map && rawJson['data'] is Map) {
      final dataMap = rawJson['data'] as Map;
      nestedInfo = ', data.keys: ${dataMap.keys.toList()}';
      if (dataMap.containsKey('count')) {
        nestedInfo += ', data.count: ${dataMap['count']}';
      }
    }

    debugPrint('[CalculatorAPI Diagnostics] $method $uri');
    debugPrint('[CalculatorAPI Diagnostics] Top-level type: ${rawJson.runtimeType}, keys: $topLevelKeys$nestedInfo');
    debugPrint('[CalculatorAPI Diagnostics] Raw record count: ${rawRecords.length}');
    debugPrint('[CalculatorAPI Diagnostics] Parsed model count: $parsedCount');

    if (rawRecords.isNotEmpty) {
      final sample = rawRecords.first;
      if (sample is Map) {
        final sanitized = Map<String, dynamic>.from(sample);
        sanitized.remove('token');
        sanitized.remove('authToken');
        sanitized.remove('password');
        debugPrint('[CalculatorAPI Diagnostics] Sample record: $sanitized');
      } else {
        debugPrint('[CalculatorAPI Diagnostics] Sample record: $sample');
      }
    }

    if (rawRecords.isEmpty) {
      debugPrint('[CalculatorAPI Diagnostics] Outcome: A. Server returned empty collection (0 records).');
    } else if (parsedCount == 0) {
      debugPrint('[CalculatorAPI Diagnostics] Outcome: B. Server returned ${rawRecords.length} records, but parser produced 0 models.');
    } else {
      debugPrint('[CalculatorAPI Diagnostics] Outcome: Successfully parsed $parsedCount model(s) from ${rawRecords.length} raw record(s).');
    }
  }

  void _logError(String method, Object error) {
    if (!kDebugMode) return;
    debugPrint('[CalculatorAPI] Error in $method: $error');
    if (error is ServerException) {
      debugPrint('[CalculatorAPI] Server error status code: ${error.statusCode}');
      if (error.responseBody != null) {
        debugPrint(
          '[CalculatorAPI] Server error response body: ${error.responseBody}',
        );
      }
    }
  }
}
