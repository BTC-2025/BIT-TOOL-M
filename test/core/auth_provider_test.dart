import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/services/user_api_service.dart';

void main() {
  group('AuthProvider Lifecycle & State Tests', () {
    late AuthStorage storage;

    const validUserJson = '''
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
        "organization": {
          "id": 6,
          "name": "Organization Name"
        }
      }
    }
    ''';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test(
      'TEST 1: Valid token -> fetches profile and sets Authenticated state',
      () async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          return http.Response(validUserJson, 200);
        });

        final userApiService = UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: userApiService,
        );

        expect(authProvider.status, AuthStatus.unauthenticated);

        await authProvider.initializeAuth();

        expect(authProvider.status, AuthStatus.authenticated);
        expect(authProvider.isAuthenticated, true);
        expect(authProvider.user, isNotNull);
        expect(authProvider.user!.id, 28);
        expect(authProvider.user!.displayName, 'First Last');
      },
    );

    test(
      'TEST 2: No token -> remains Unauthenticated without calling API',
      () async {
        var apiCalled = false;
        final mockClient = MockClient((request) async {
          apiCalled = true;
          return http.Response(validUserJson, 200);
        });

        final userApiService = UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: userApiService,
        );

        await authProvider.initializeAuth();

        expect(authProvider.status, AuthStatus.unauthenticated);
        expect(authProvider.isAuthenticated, false);
        expect(authProvider.user, isNull);
        expect(apiCalled, false);
      },
    );

    test(
      'TEST 3: Invalid token (401) -> clears token, resets user state, sets TokenExpired',
      () async {
        await storage.saveToken('INVALID_EXPIRED_TOKEN');

        var callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('{"message": "Unauthorized"}', 401);
        });

        final userApiService = UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: userApiService,
        );

        await authProvider.initializeAuth();

        expect(authProvider.status, AuthStatus.tokenExpired);
        expect(authProvider.isAuthenticated, false);
        expect(authProvider.user, isNull);
        expect(await storage.hasToken(), false); // Token must be cleared!
        expect(callCount, 1); // No infinite retry loop!
      },
    );

    test(
      'TEST 4 & 10: Token persistence & application refresh restores state',
      () async {
        // Step 1: User authenticates
        await storage.saveToken('PERSISTED_TOKEN');

        final mockClient = MockClient((request) async {
          return http.Response(validUserJson, 200);
        });

        // Step 2: "Re-opening" or "refreshing" creates a fresh AuthProvider instance
        final freshAuthProvider = AuthProvider(
          authStorage: storage,
          userApiService: UserApiService(
            apiClient: ApiClient(client: mockClient),
            authStorage: storage,
          ),
        );

        await freshAuthProvider.initializeAuth();

        expect(freshAuthProvider.status, AuthStatus.authenticated);
        expect(freshAuthProvider.user?.email, 'user@example.com');
        expect(await storage.getToken(), 'PERSISTED_TOKEN');
      },
    );

    test(
      'TEST 8: Network failure -> friendly error state and retry mechanism works',
      () async {
        await storage.saveToken('VALID_TOKEN');

        var shouldFail = true;
        final mockClient = MockClient((request) async {
          if (shouldFail) {
            throw http.ClientException('Network unreachable');
          }
          return http.Response(validUserJson, 200);
        });

        final userApiService = UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: userApiService,
        );

        await authProvider.initializeAuth();

        expect(authProvider.status, AuthStatus.authenticationError);
        expect(authProvider.errorMessage, contains('internet connection'));
        expect(authProvider.isAuthenticated, false);

        // Now network recovers: call retry()
        shouldFail = false;
        await authProvider.retry();

        expect(authProvider.status, AuthStatus.authenticated);
        expect(authProvider.user, isNotNull);
        expect(authProvider.errorMessage, isNull);
      },
    );

    test(
      'TEST 9: Server 500 error -> friendly error state and retry works',
      () async {
        await storage.saveToken('VALID_TOKEN');

        var return500 = true;
        final mockClient = MockClient((request) async {
          if (return500) {
            return http.Response('Server Error', 500);
          }
          return http.Response(validUserJson, 200);
        });

        final authProvider = AuthProvider(
          authStorage: storage,
          userApiService: UserApiService(
            apiClient: ApiClient(client: mockClient),
            authStorage: storage,
          ),
        );

        await authProvider.initializeAuth();

        expect(authProvider.status, AuthStatus.authenticationError);
        expect(
          authProvider.errorMessage,
          'Unable to connect to Bit Tool services right now.',
        );

        return500 = false;
        await authProvider.retry();

        expect(authProvider.status, AuthStatus.authenticated);
        expect(authProvider.user?.fullName, 'First Last');
      },
    );

    test('signOut clears token and resets to unauthenticated', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(validUserJson, 200);
      });

      final authProvider = AuthProvider(
        authStorage: storage,
        userApiService: UserApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        ),
      );

      await authProvider.initializeAuth();
      expect(authProvider.isAuthenticated, true);

      await authProvider.signOut();
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.user, isNull);
      expect(await storage.hasToken(), false);
    });
  });
}
