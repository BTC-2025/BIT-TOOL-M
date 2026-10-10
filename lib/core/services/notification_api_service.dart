import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../models/notification_model.dart';

/// Dedicated service responsible for notification API interactions.
class NotificationApiService {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  NotificationApiService({ApiClient? apiClient, AuthStorage? authStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _authStorage = authStorage ?? AuthStorage();

  /// Retrieves notifications for the currently authenticated user from GET /notifications.
  ///
  /// Throws [UnauthorizedException] if no token is saved or if token is rejected.
  /// Throws [InvalidResponseException] if the response structure is malformed.
  Future<List<NotificationModel>> getNotifications() async {
    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[NotificationAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }

    if (!hasToken) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationAPI] Aborting GET: no authentication token available in storage.',
        );
      }
      throw const UnauthorizedException('No authentication token available.');
    }

    final endpointUri = ApiConfig.notificationsUri;
    if (kDebugMode) {
      debugPrint('[NotificationAPI] Final request: GET $endpointUri');
    }

    try {
      final dynamic rawResponse = await _apiClient.get(
        endpointUri,
        token: token,
      );

      if (kDebugMode) {
        debugPrint(
          '[NotificationAPI] Response received: payload type is ${rawResponse.runtimeType}',
        );
      }

      List<NotificationModel> notifications = [];

      if (rawResponse is List) {
        notifications = rawResponse
            .whereType<Map>()
            .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else if (rawResponse is Map) {
        final map = Map<String, dynamic>.from(rawResponse);
        final success = map['success'];
        final status = map['status']?.toString().toLowerCase();
        if (success == false || status == 'error') {
          final message =
              map['message']?.toString() ??
              'Failed to retrieve notifications.';
          throw ApiException(message);
        }

        var listData =
            map['data'] ??
            map['notifications'] ??
            map['results'] ??
            map['items'];

        if (listData is Map) {
          final nestedMap = Map<String, dynamic>.from(listData);
          listData =
              nestedMap['notifications'] ??
              nestedMap['items'] ??
              nestedMap['results'] ??
              nestedMap['data'];
        }

        if (listData is List) {
          notifications = listData
              .whereType<Map>()
              .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } else if (map.containsKey('data') && map['data'] == null) {
          notifications = [];
        } else {
          throw const InvalidResponseException(
            'Server returned an unexpected notifications response format.',
          );
        }
      } else if (rawResponse == null) {
        notifications = [];
      } else {
        throw const InvalidResponseException(
          'Server returned an unexpected notifications response format.',
        );
      }

      if (kDebugMode) {
        final unread = notifications.where((n) => !n.isRead).length;
        debugPrint(
          '[NotificationAPI] Successfully parsed ${notifications.length} notification(s) ($unread unread).',
        );
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAPI] Error in getNotifications: $e');
        if (e is ServerException) {
          debugPrint(
            '[NotificationAPI] Server error status code: ${e.statusCode}',
          );
          if (e.correlationId != null) {
            debugPrint(
              '[NotificationAPI] Server request/correlation ID: ${e.correlationId}',
            );
          }
          if (e.responseBody != null && e.responseBody!.isNotEmpty) {
            debugPrint(
              '[NotificationAPI] Server error response body: ${e.responseBody}',
            );
          }
        }
      }
      rethrow;
    }
  }

  /// Marks a single notification as read via PUT /notifications/:id/read.
  ///
  /// Throws [UnauthorizedException] if unauthenticated.
  /// Throws [ApiException] on backend rejection.
  Future<bool> markOneAsRead(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const ApiException('Notification ID cannot be empty.');
    }

    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[NotificationAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }

    if (!hasToken) {
      throw const UnauthorizedException('No authentication token available.');
    }

    final endpointUri = ApiConfig.notificationReadUri(cleanId);
    if (kDebugMode) {
      debugPrint(
        '[NotificationAPI] Single-read request: PUT $endpointUri for ID: $cleanId',
      );
    }

    try {
      final dynamic rawResponse = await _apiClient.put(
        endpointUri,
        token: token,
      );

      if (rawResponse is Map) {
        final map = Map<String, dynamic>.from(rawResponse);
        final status = map['status']?.toString().toLowerCase();
        final success = map['success'];
        if (status == 'success' || success == true) {
          if (kDebugMode) {
            debugPrint(
              '[NotificationAPI] Single-read successful for notification ID: $cleanId',
            );
          }
          return true;
        }
        if (status == 'error' || success == false) {
          final message =
              map['message']?.toString() ??
              'Failed to mark notification as read.';
          throw ApiException(message);
        }
        return true;
      }

      if (kDebugMode) {
        debugPrint(
          '[NotificationAPI] Single-read successful for notification ID: $cleanId',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAPI] Error in markOneAsRead: $e');
        if (e is ServerException) {
          debugPrint(
            '[NotificationAPI] Server error status code: ${e.statusCode}',
          );
          if (e.correlationId != null) {
            debugPrint(
              '[NotificationAPI] Server request/correlation ID: ${e.correlationId}',
            );
          }
          if (e.responseBody != null && e.responseBody!.isNotEmpty) {
            debugPrint(
              '[NotificationAPI] Server error response body: ${e.responseBody}',
            );
          }
        }
      }
      rethrow;
    }
  }

  /// Marks all notifications as read via PUT /notifications/read-all.
  ///
  /// Throws [UnauthorizedException] if unauthenticated.
  /// Throws [ApiException] on backend rejection.
  Future<bool> markAllAsRead() async {
    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[NotificationAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }

    if (!hasToken) {
      throw const UnauthorizedException('No authentication token available.');
    }

    final endpointUri = ApiConfig.notificationsReadAllUri;
    if (kDebugMode) {
      debugPrint('[NotificationAPI] Read-all request: PUT $endpointUri');
    }

    try {
      final dynamic rawResponse = await _apiClient.put(
        endpointUri,
        token: token,
      );

      if (rawResponse is Map) {
        final map = Map<String, dynamic>.from(rawResponse);
        final status = map['status']?.toString().toLowerCase();
        final success = map['success'];
        if (status == 'success' || success == true) {
          if (kDebugMode) {
            debugPrint('[NotificationAPI] Read-all request succeeded.');
          }
          return true;
        }
        if (status == 'error' || success == false) {
          final message =
              map['message']?.toString() ??
              'Failed to mark all notifications as read.';
          throw ApiException(message);
        }
        return true;
      }

      if (kDebugMode) {
        debugPrint('[NotificationAPI] Read-all request succeeded.');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationAPI] Error in markAllAsRead: $e');
        if (e is ServerException) {
          debugPrint(
            '[NotificationAPI] Server error status code: ${e.statusCode}',
          );
          if (e.correlationId != null) {
            debugPrint(
              '[NotificationAPI] Server request/correlation ID: ${e.correlationId}',
            );
          }
          if (e.responseBody != null && e.responseBody!.isNotEmpty) {
            debugPrint(
              '[NotificationAPI] Server error response body: ${e.responseBody}',
            );
          }
        }
      }
      rethrow;
    }
  }
}
