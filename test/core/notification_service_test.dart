import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/services/notification_api_service.dart';

void main() {
  group('NotificationApiService Tests', () {
    late AuthStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test(
      'throws UnauthorizedException when no token exists and never sends request',
      () async {
        var requestMade = false;
        final mockClient = MockClient((request) async {
          requestMade = true;
          return http.Response('[]', 200);
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        expect(
          () => service.getNotifications(),
          throwsA(isA<UnauthorizedException>()),
        );
        expect(requestMade, isFalse);
      },
    );

    test(
      'TEST A: GET /notifications returns list of NotificationModel on raw array response',
      () async {
        await storage.saveToken('TEST_TOKEN_123');

        const responseJson = '''
      [
        {
          "id": "1",
          "title": "Alert 1",
          "message": "Message 1",
          "isRead": false
        },
        {
          "id": "2",
          "title": "Alert 2",
          "message": "Message 2",
          "isRead": true
        }
      ]
      ''';

        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/notifications');
          expect(request.headers['Authorization'], 'Bearer TEST_TOKEN_123');
          return http.Response(responseJson, 200);
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final result = await service.getNotifications();
        expect(result.length, 2);
        expect(result[0].id, '1');
        expect(result[0].isRead, isFalse);
        expect(result[1].id, '2');
        expect(result[1].isRead, isTrue);
      },
    );

    test(
      'TEST A (envelope): GET /notifications returns list on {success: true, data: [...]} envelope',
      () async {
        await storage.saveToken('TEST_TOKEN_123');

        const responseJson = '''
      {
        "success": true,
        "data": [
          {
            "id": "100",
            "title": "Envelope Alert",
            "message": "Data inside envelope",
            "isRead": false
          }
        ]
      }
      ''';

        final mockClient = MockClient((request) async {
          return http.Response(responseJson, 200);
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final result = await service.getNotifications();
        expect(result.length, 1);
        expect(result[0].id, '100');
        expect(result[0].title, 'Envelope Alert');
      },
    );

    test(
      'TEST B: GET /notifications returns empty list on empty array',
      () async {
        await storage.saveToken('TEST_TOKEN_123');

        final mockClient = MockClient((request) async {
          return http.Response('[]', 200);
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final result = await service.getNotifications();
        expect(result, isEmpty);
      },
    );

    test('TEST G: throws UnauthorizedException on HTTP 401', () async {
      await storage.saveToken('EXPIRED_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401);
      });

      final service = NotificationApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getNotifications(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('TEST H: throws ForbiddenException on HTTP 403', () async {
      await storage.saveToken('TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Forbidden"}', 403);
      });

      final service = NotificationApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getNotifications(),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('TEST I: throws ServerException on HTTP 500', () async {
      await storage.saveToken('TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = NotificationApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(() => service.getNotifications(), throwsA(isA<ServerException>()));
    });

    test(
      'TEST J: throws InvalidResponseException on malformed response structure',
      () async {
        await storage.saveToken('TOKEN');

        final mockClient = MockClient((request) async {
          return http.Response('{"unexpected": "format"}', 200);
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        expect(
          () => service.getNotifications(),
          throwsA(isA<InvalidResponseException>()),
        );
      },
    );

    test(
      'TEST D: PUT /notifications/:id/read calls correct URL and header',
      () async {
        await storage.saveToken('TOKEN_ABC');

        final mockClient = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/notifications/42/read');
          expect(request.headers['Authorization'], 'Bearer TOKEN_ABC');
          return http.Response(
            '{"status": "success", "message": "Marked as read"}',
            200,
          );
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final success = await service.markOneAsRead('42');
        expect(success, isTrue);
      },
    );

    test(
      'TEST E: PUT /notifications/read-all calls correct URL and header',
      () async {
        await storage.saveToken('TOKEN_ABC');

        final mockClient = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/notifications/read-all');
          expect(request.headers['Authorization'], 'Bearer TOKEN_ABC');
          return http.Response(
            '{"status": "success", "message": "All marked as read"}',
            200,
          );
        });

        final service = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final success = await service.markAllAsRead();
        expect(success, isTrue);
      },
    );
  });
}
