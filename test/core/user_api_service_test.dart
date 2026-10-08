import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/services/user_api_service.dart';

void main() {
  group('UserApiService Tests', () {
    late AuthStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test('throws UnauthorizedException when no token is in storage', () async {
      final service = UserApiService(
        apiClient: ApiClient(),
        authStorage: storage,
      );

      expect(
        () => service.getCurrentUser(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test(
      'TEST 1: retrieves and parses current user on successful 200 response',
      () async {
        await storage.saveToken('VALID_BNX_TOKEN');

        const responseBody = '''
      {
        "success": true,
        "message": "User profile retrieved successfully",
        "data": {
          "id": 28,
          "email": "user@example.com",
          "firstName": "First",
          "lastName": "Last",
          "fullName": "First Last",
          "profilePictureUrl": null,
          "role": "ORG_ADMIN",
          "accountType": "BUSINESS",
          "storageUsed": 0,
          "storageLimit": 16106127360,
          "isPrimary": true,
          "phoneNumber": null,
          "recoveryEmail": null,
          "dob": null,
          "organization": {
            "id": 6,
            "name": "Organization Name"
          }
        }
      }
      ''';

        final mockClient = MockClient((request) async {
          expect(request.url.path, '/api/users/me');
          expect(request.headers['Authorization'], 'Bearer VALID_BNX_TOKEN');
          return http.Response(responseBody, 200);
        });

        final service = UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final user = await service.getCurrentUser();

        expect(user.id, 28);
        expect(user.email, 'user@example.com');
        expect(user.fullName, 'First Last');
        expect(user.role, 'ORG_ADMIN');
        expect(user.organization?.name, 'Organization Name');
      },
    );

    test('throws ApiException when success flag is false', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": false, "message": "Account suspended"}',
          200,
        );
      });

      final service = UserApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getCurrentUser(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Account suspended',
          ),
        ),
      );
    });

    test(
      'throws InvalidResponseException when data payload is missing',
      () async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          return http.Response('{"success": true, "data": null}', 200);
        });

        final service = UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        expect(
          () => service.getCurrentUser(),
          throwsA(isA<InvalidResponseException>()),
        );
      },
    );
  });
}
