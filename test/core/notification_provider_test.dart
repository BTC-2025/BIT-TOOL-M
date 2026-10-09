import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/notification_provider.dart';
import 'package:bit_tools_backend/core/services/notification_api_service.dart';
import 'package:bit_tools_backend/core/services/user_api_service.dart';

void main() {
  group('NotificationProvider State & Lifecycle Tests', () {
    late AuthStorage storage;

    const dummyUserJson = '''
    {
      "success": true,
      "data": {
        "id": 10,
        "email": "user1@example.com",
        "firstName": "User",
        "lastName": "One",
        "fullName": "User One",
        "role": "MEMBER",
        "accountType": "BUSINESS",
        "isPrimary": true
      }
    }
    ''';

    const dummyUser2Json = '''
    {
      "success": true,
      "data": {
        "id": 20,
        "email": "user2@example.com",
        "firstName": "User",
        "lastName": "Two",
        "fullName": "User Two",
        "role": "MEMBER",
        "accountType": "BUSINESS",
        "isPrimary": true
      }
    }
    ''';

    const sampleNotificationsJson = '''
    [
      {
        "id": "notif-1",
        "title": "Welcome to Bit Tool",
        "message": "Your workspace is ready.",
        "isRead": false,
        "type": "system"
      },
      {
        "id": "notif-2",
        "title": "Weather Alert",
        "message": "Forecast updated.",
        "isRead": true,
        "type": "weather"
      },
      {
        "id": "notif-3",
        "title": "Calendar Sync",
        "message": "Events synced.",
        "isRead": false,
        "type": "calendar"
      }
    ]
    ''';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test(
      'TEST A & C: fetchNotifications loads items and calculates unread count accurately',
      () async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/notifications')) {
            return http.Response(sampleNotificationsJson, 200);
          }
          return http.Response('Not Found', 404);
        });

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(apiService: apiService);

        expect(provider.status, NotificationStatus.initial);
        expect(provider.unreadCount, 0);

        await provider.fetchNotifications();

        expect(provider.status, NotificationStatus.loaded);
        expect(provider.notifications.length, 3);
        // notif-1 and notif-3 are unread -> unreadCount should be 2
        expect(provider.unreadCount, 2);
        expect(provider.hasUnread, isTrue);
        expect(provider.isEmpty, isFalse);
      },
    );

    test('TEST B: empty response sets loaded and isEmpty = true', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final apiService = NotificationApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final provider = NotificationProvider(apiService: apiService);

      await provider.fetchNotifications();

      expect(provider.status, NotificationStatus.loaded);
      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, isFalse);
      expect(provider.isEmpty, isTrue);
    });

    test(
      'TEST D: markAsRead marks item as read and decrements unreadCount',
      () async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/notifications')) {
            return http.Response(sampleNotificationsJson, 200);
          }
          if (request.method == 'PUT' &&
              request.url.path.endsWith('/notifications/notif-1/read')) {
            return http.Response(
              '{"status": "success", "message": "Read"}',
              200,
            );
          }
          return http.Response('Error', 400);
        });

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(apiService: apiService);
        await provider.fetchNotifications();

        expect(provider.unreadCount, 2);
        expect(
          provider.notifications.firstWhere((n) => n.id == 'notif-1').isRead,
          isFalse,
        );

        final result = await provider.markAsRead('notif-1');
        expect(result, isTrue);
        expect(
          provider.notifications.firstWhere((n) => n.id == 'notif-1').isRead,
          isTrue,
        );
        expect(provider.unreadCount, 1);
      },
    );

    test(
      'TEST E: markAllAsRead marks all notifications as read and sets unreadCount to 0',
      () async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/notifications')) {
            return http.Response(sampleNotificationsJson, 200);
          }
          if (request.method == 'PUT' &&
              request.url.path.endsWith('/notifications/read-all')) {
            return http.Response(
              '{"status": "success", "message": "All read"}',
              200,
            );
          }
          return http.Response('Error', 400);
        });

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(apiService: apiService);
        await provider.fetchNotifications();

        expect(provider.unreadCount, 2);

        final result = await provider.markAllAsRead();
        expect(result, isTrue);
        expect(provider.unreadCount, 0);
        expect(provider.hasUnread, isFalse);
        expect(provider.notifications.every((n) => n.isRead), isTrue);
      },
    );

    test(
      'TEST G: HTTP 401 sets error state and calls authProvider.signOut()',
      () async {
        await storage.saveToken('EXPIRED_TOKEN');

        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/users/me') {
            return http.Response(dummyUserJson, 200);
          }
          if (request.url.path.endsWith('/notifications')) {
            return http.Response('{"message": "Token expired"}', 401);
          }
          return http.Response('Not Found', 404);
        });

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: UserApiService(
            apiClient: ApiClient(client: mockClient),
            authStorage: storage,
          ),
        );
        await authProvider.initializeAuth();

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(
          apiService: apiService,
          authProvider: authProvider,
        );

        await provider.fetchNotifications();

        expect(provider.status, NotificationStatus.error);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Token expired'));
        // AuthProvider was notified of expiration
        expect(authProvider.isAuthenticated, isFalse);
      },
    );

    test(
      'TEST H: HTTP 403 sets error state without signing out authProvider',
      () async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/users/me') {
            return http.Response(dummyUserJson, 200);
          }
          if (request.url.path.endsWith('/notifications')) {
            return http.Response('{"message": "Forbidden access"}', 403);
          }
          return http.Response('Not Found', 404);
        });

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: UserApiService(
            apiClient: ApiClient(client: mockClient),
            authStorage: storage,
          ),
        );
        await authProvider.initializeAuth();

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(
          apiService: apiService,
          authProvider: authProvider,
        );

        await provider.fetchNotifications();

        expect(provider.status, NotificationStatus.error);
        expect(provider.errorMessage?.toLowerCase(), contains('permission'));
        // AuthProvider remains authenticated on 403 permission error
        expect(authProvider.isAuthenticated, isTrue);
      },
    );

    test(
      'TEST I: Network error sets friendly error state and retry fetches successfully',
      () async {
        await storage.saveToken('VALID_TOKEN');

        var failOnce = true;
        final mockClient = MockClient((request) async {
          if (failOnce) {
            failOnce = false;
            throw http.ClientException('Failed host lookup');
          }
          return http.Response(sampleNotificationsJson, 200);
        });

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(apiService: apiService);

        await provider.fetchNotifications();
        expect(provider.status, NotificationStatus.error);
        expect(provider.hasError, isTrue);

        // Retry
        await provider.fetchNotifications(forceRefresh: true);
        expect(provider.status, NotificationStatus.loaded);
        expect(provider.notifications.length, 3);
      },
    );

    test(
      'TEST K: Multi-account correctness: switching accounts clears old data and loads new account data',
      () async {
        await storage.saveToken('TOKEN_1');

        var activeUserId = 10;
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/notifications')) {
            if (activeUserId == 10) {
              return http.Response(
                '[{"id": "user1-notif", "title": "For User 1", "message": "msg", "isRead": false}]',
                200,
              );
            } else {
              return http.Response(
                '[{"id": "user2-notif", "title": "For User 2", "message": "msg", "isRead": true}]',
                200,
              );
            }
          }
          if (request.url.path == '/api/users/me') {
            return http.Response(
              activeUserId == 10 ? dummyUserJson : dummyUser2Json,
              200,
            );
          }
          return http.Response('Error', 400);
        });

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: UserApiService(
            apiClient: ApiClient(client: mockClient),
            authStorage: storage,
          ),
        );
        await authProvider.initializeAuth();

        final apiService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final provider = NotificationProvider(
          apiService: apiService,
          authProvider: authProvider,
        );

        provider.updateAuth(authProvider);
        // Wait for fetch
        await pumpEventQueue();

        expect(provider.notifications.length, 1);
        expect(provider.notifications.first.id, 'user1-notif');
        expect(provider.unreadCount, 1);

        // Now switch account to user 2
        activeUserId = 20;
        await authProvider.fetchCurrentUser();

        provider.updateAuth(authProvider);
        await pumpEventQueue();

        // State is updated to User 2's notifications only!
        expect(provider.notifications.length, 1);
        expect(provider.notifications.first.id, 'user2-notif');
        expect(provider.unreadCount, 0);

        // User signs out
        await authProvider.signOut();
        provider.updateAuth(authProvider);

        expect(provider.notifications, isEmpty);
        expect(provider.unreadCount, 0);
      },
    );
  });
}
