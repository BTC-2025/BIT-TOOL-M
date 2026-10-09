import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exceptions.dart';

/// Centralized HTTP client for making API requests with sanitized logging,
/// authorization injection, timeouts, and typed exception mapping.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Executes an authenticated or unauthenticated GET request.
  Future<dynamic> get(
    Uri uri, {
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    _logRequest('GET', uri, headers);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.requestTimeout);
      stopwatch.stop();

      _logResponse('GET', uri, response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    } on FormatException catch (e) {
      throw InvalidResponseException('Malformed JSON response: ${e.message}');
    } catch (e) {
      // Check for OS-level socket/network exception on non-web
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw const NetworkException();
      }
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Executes an authenticated or unauthenticated POST request.
  Future<dynamic> post(
    Uri uri, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    _logRequest('POST', uri, headers);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);
      stopwatch.stop();

      _logResponse('POST', uri, response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    } on FormatException catch (e) {
      throw InvalidResponseException('Malformed JSON response: ${e.message}');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw const NetworkException();
      }
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Executes an authenticated or unauthenticated PUT request.
  Future<dynamic> put(
    Uri uri, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    _logRequest('PUT', uri, headers);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);
      stopwatch.stop();

      _logResponse('PUT', uri, response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    } on FormatException catch (e) {
      throw InvalidResponseException('Malformed JSON response: ${e.message}');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw const NetworkException();
      }
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Executes an authenticated or unauthenticated DELETE request.
  Future<dynamic> delete(
    Uri uri, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    _logRequest('DELETE', uri, headers);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);
      stopwatch.stop();

      _logResponse('DELETE', uri, response, stopwatch.elapsedMilliseconds);
      return _handleResponse(response);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on http.ClientException {
      throw const NetworkException();
    } on FormatException catch (e) {
      throw InvalidResponseException('Malformed JSON response: ${e.message}');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw const NetworkException();
      }
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  /// Processes the [http.Response] and throws appropriate typed exceptions.
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    final bodyString = utf8.decode(response.bodyBytes);
    dynamic decoded;
    if (bodyString.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(bodyString);
      } on FormatException {
        // Handled below if status is successful
      }
    }

    if (statusCode == 401) {
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message']?.toString() ?? '';
        if (msg.toLowerCase().contains('invalid credential')) {
          throw const InvalidCredentialsException('Invalid Credentials');
        }
        throw UnauthorizedException(
          msg.isNotEmpty ? msg : 'Authentication token expired or invalid.',
        );
      }
      throw const UnauthorizedException();
    }

    if (statusCode == 400) {
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message']?.toString() ?? '';
        if (msg.toLowerCase().contains('invalid credential')) {
          throw const InvalidCredentialsException('Invalid Credentials');
        }
        if (msg.isNotEmpty) {
          throw ApiException(msg, statusCode: statusCode);
        }
      }
      throw const ApiException('Bad Request.', statusCode: 400);
    }

    if (statusCode == 403) {
      throw const ForbiddenException();
    }

    if (statusCode == 404) {
      throw const NotFoundException();
    }

    if (statusCode == 409) {
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message']?.toString() ?? '';
        if (msg.isNotEmpty) {
          throw ConflictException(msg);
        }
      }
      throw const ConflictException();
    }

    if (statusCode >= 500 && statusCode <= 599) {
      String? backendMsg;
      if (decoded is Map<String, dynamic>) {
        backendMsg =
            decoded['message']?.toString() ?? decoded['error']?.toString();
      }
      final correlationId =
          response.headers['x-request-id'] ??
          response.headers['x-correlation-id'] ??
          response.headers['traceparent'] ??
          response.headers['x-trace-id'];
      throw ServerException(
        backendMsg != null && backendMsg.isNotEmpty
            ? backendMsg
            : 'Unable to connect to Bit Tool services right now.',
        statusCode,
        bodyString,
        correlationId,
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        'Server returned error status $statusCode.',
        statusCode: statusCode,
      );
    }

    if (bodyString.trim().isEmpty) {
      return null;
    }

    if (decoded != null) {
      return decoded;
    }

    try {
      return jsonDecode(bodyString);
    } on FormatException {
      throw const InvalidResponseException(
        'Failed to decode server response as valid JSON.',
      );
    }
  }

  /// Logs outgoing request details while strictly sanitizing sensitive headers.
  void _logRequest(String method, Uri uri, Map<String, String> headers) {
    if (kDebugMode) {
      final sanitizedHeaders = Map<String, String>.from(headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = '[REDACTED]';
      }
      debugPrint('[API] $method $uri | Headers: $sanitizedHeaders');
    }
  }

  /// Logs response status, duration, content-type, correlation ID, and sanitized error body.
  void _logResponse(
    String method,
    Uri uri,
    http.Response response,
    int durationMs,
  ) {
    if (kDebugMode) {
      final statusCode = response.statusCode;
      final contentType = response.headers['content-type'] ?? 'unknown';
      final correlationId =
          response.headers['x-request-id'] ??
          response.headers['x-correlation-id'] ??
          response.headers['traceparent'] ??
          response.headers['x-trace-id'];

      final buffer = StringBuffer(
        '[API] $method $uri -> Status: $statusCode (${durationMs}ms) | Content-Type: $contentType',
      );
      if (correlationId != null) {
        buffer.write(' | RequestId: $correlationId');
      }
      debugPrint(buffer.toString());

      if (statusCode >= 400 && response.body.trim().isNotEmpty) {
        final body = response.body.trim();
        final sanitizedBody = body.length > 500
            ? '${body.substring(0, 500)}... (truncated)'
            : body;
        debugPrint('[API] Response Body: $sanitizedBody');
      }
    }
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}
