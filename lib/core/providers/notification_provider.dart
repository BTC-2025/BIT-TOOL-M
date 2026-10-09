import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import 'auth_provider.dart';

/// Represents the high-level state of notifications.
enum NotificationStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Centralized state management for user notifications.
class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _apiService;

  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationModel> _notifications = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isMarkingAllAsRead = false;

  /// IDs of notifications currently in-flight for mark-one-as-read.
  final Set<String> _pendingMarkAsReadIds = {};

  /// Tracks active user ID to prevent cross-account data leakage.
  String? _currentUserId;

  /// Tracks the monotonic request ID to prevent out-of-order in-flight responses.
  int _activeRequestId = 0;

  /// Reference to AuthProvider for token-expiration coordination.
  AuthProvider? _authProvider;

  NotificationProvider({
    NotificationApiService? apiService,
    AuthProvider? authProvider,
  }) : _apiService = apiService ?? NotificationApiService() {
    if (authProvider != null) {
      updateAuth(authProvider);
    }
  }

  // --- Getters ---

  NotificationStatus get status => _status;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  bool get isMarkingAllAsRead => _isMarkingAllAsRead;

  bool get isLoading => _status == NotificationStatus.loading;
  bool get hasError => _status == NotificationStatus.error;
  bool get isLoaded => _status == NotificationStatus.loaded;
  bool get isEmpty => isLoaded && _notifications.isEmpty;

  /// The count of unread notifications, strictly calculated from real items.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Whether there are any unread notifications.
  bool get hasUnread => unreadCount > 0;

  /// Checks if a specific notification item is currently being marked as read.
  bool isItemMarkingRead(String id) => _pendingMarkAsReadIds.contains(id);

  // --- Multi-Account & Auth Synchronization ---

  /// Synchronizes notifications state with the active [AuthProvider].
  ///
  /// When account switches or user signs out, in-memory state is cleared immediately.
  /// If a new account is signed in, notifications are fetched for that account.
  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    final newUserId = auth.user?.id.toString();

    if (!auth.isAuthenticated || newUserId == null) {
      if (_currentUserId != null || _notifications.isNotEmpty) {
        clear();
      }
      _currentUserId = null;
      return;
    }

    // Account changed or initial sign-in
    if (newUserId != _currentUserId) {
      clear();
      _currentUserId = newUserId;
      fetchNotifications();
    }
  }

  // --- API Actions ---

  Future<void>? _pendingFetch;

  /// Fetches all notifications from GET /notifications.
  ///
  /// If [forceRefresh] is true, preserves existing items while fetching in the background.
  Future<void> fetchNotifications({bool forceRefresh = false}) {
    if (_pendingFetch != null && !forceRefresh) {
      return _pendingFetch!;
    }

    _pendingFetch = _executeFetchNotifications(forceRefresh: forceRefresh);
    return _pendingFetch!;
  }

  Future<void> _executeFetchNotifications({bool forceRefresh = false}) async {
    final auth = _authProvider;
    if (auth != null && !auth.isAuthenticated) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationProvider] AuthProvider is unauthenticated. Notifications cannot be retrieved without an active session.',
        );
      }
      _status = NotificationStatus.error;
      _errorMessage = 'Please sign in to view notifications.';
      _notifications = [];
      notifyListeners();
      return;
    }

    final int requestId = ++_activeRequestId;
    final String? expectedUserId = _currentUserId;

    if (kDebugMode) {
      debugPrint(
        '[NotificationProvider] Notification fetch initiated (requestId: $requestId, forceRefresh: $forceRefresh, activeUserId: $_currentUserId).',
      );
    }

    if (forceRefresh && _notifications.isNotEmpty) {
      _isRefreshing = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _status = NotificationStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final items = await _apiService.getNotifications();

      // Guard: Ignore response if another request was launched or account changed
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationProvider] Stale response discarded (active: $_activeRequestId vs request: $requestId).',
          );
        }
        return;
      }

      _notifications = items;
      _status = NotificationStatus.loaded;
      _errorMessage = null;
      if (kDebugMode) {
        debugPrint(
          '[NotificationProvider] State updated to loaded with ${items.length} notifications ($unreadCount unread).',
        );
      }
    } on UnauthorizedException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage = e.message;
      _notifications = [];
      // Trigger token expiration handling in auth provider if available
      await _authProvider?.signOut();
    } on ForbiddenException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage = e.message;
    } on NetworkException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage = e.message;
    } on RequestTimeoutException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage = e.message;
    } on ServerException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage = e.message;
    } on ApiException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }
      _status = NotificationStatus.error;
      _errorMessage =
          'Failed to load notifications. Please check your connection and retry.';
    } finally {
      _pendingFetch = null;
      if (requestId == _activeRequestId && _currentUserId == expectedUserId) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Marks a single notification as read via PUT /notifications/:id/read.
  Future<bool> markAsRead(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty || _pendingMarkAsReadIds.contains(cleanId)) {
      return false;
    }

    final int index = _notifications.indexWhere((n) => n.id == cleanId);
    if (index == -1) return false;

    // If already read, nothing to do
    if (_notifications[index].isRead) return true;

    _pendingMarkAsReadIds.add(cleanId);
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '[NotificationProvider] Single-read request initiated for notification ID: $cleanId',
      );
    }

    try {
      final success = await _apiService.markOneAsRead(cleanId);
      if (success) {
        // Update local item on confirmed success
        final updatedIndex = _notifications.indexWhere((n) => n.id == cleanId);
        if (updatedIndex != -1) {
          _notifications[updatedIndex] = _notifications[updatedIndex].copyWith(
            isRead: true,
          );
        }
        if (kDebugMode) {
          debugPrint(
            '[NotificationProvider] Single-read request confirmed for ID: $cleanId (remaining unread: $unreadCount)',
          );
        }
        return true;
      }
      return false;
    } on UnauthorizedException catch (e) {
      _errorMessage = e.message;
      await _authProvider?.signOut();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationProvider] Failed to mark notification as read: $e',
        );
      }
      return false;
    } finally {
      _pendingMarkAsReadIds.remove(cleanId);
      notifyListeners();
    }
  }

  /// Marks all notifications as read via PUT /notifications/read-all.
  Future<bool> markAllAsRead() async {
    if (_isMarkingAllAsRead || unreadCount == 0) {
      return true;
    }

    _isMarkingAllAsRead = true;
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '[NotificationProvider] Read-all request initiated ($unreadCount unread).',
      );
    }

    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        // Update all notifications to read
        _notifications =
            _notifications
                .map((item) => item.isRead ? item : item.copyWith(isRead: true))
                .toList();
        if (kDebugMode) {
          debugPrint(
            '[NotificationProvider] Read-all request confirmed. All notifications marked as read (unread: 0).',
          );
        }
        return true;
      }
      return false;
    } on UnauthorizedException catch (e) {
      _errorMessage = e.message;
      await _authProvider?.signOut();
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationProvider] Failed to mark all notifications as read: $e',
        );
      }
      return false;
    } finally {
      _isMarkingAllAsRead = false;
      notifyListeners();
    }
  }

  /// Resets in-memory notifications state.
  void clear() {
    _status = NotificationStatus.initial;
    _notifications = [];
    _errorMessage = null;
    _isRefreshing = false;
    _isMarkingAllAsRead = false;
    _pendingMarkAsReadIds.clear();
    if (kDebugMode) {
      debugPrint('[NotificationProvider] In-memory notifications state cleared.');
    }
    notifyListeners();
  }
}
