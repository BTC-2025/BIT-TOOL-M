import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';

void main() {
  group('ApiClient Tests', () {
    test(
      'sends Authorization: Bearer <token> header dynamically when token provided',
      () async {
        String? recordedAuthHeader;
        String? recordedContentType;

        final mockClient = MockClient((request) async {
          recordedAuthHeader = request.headers['Authorization'];
          recordedContentType = request.headers['Content-Type'];
          return http.Response('{"success": true}', 200);
        });

        final apiClient = ApiClient(client: mockClient);
        const testToken = 'SECRET_BNX_TOKEN_XYZ';

        final response = await apiClient.get(
          Uri.parse('https://api.bnxmail.com/api/users/me'),
          token: testToken,
        );

        expect(recordedAuthHeader, 'Bearer $testToken');
        expect(recordedContentType, 'application/json');
        expect(response['success'], true);
      },
    );

    test(
      'TEST 2: does not include Authorization header if token is null or empty',
      () async {
        String? recordedAuthHeader;

        final mockClient = MockClient((request) async {
          recordedAuthHeader = request.headers['Authorization'];
          return http.Response('{"status": "ok"}', 200);
        });

        final apiClient = ApiClient(client: mockClient);
        await apiClient.get(
          Uri.parse('https://api.bnxmail.com/api/public'),
          token: null,
        );

        expect(recordedAuthHeader, isNull);
      },
    );

    test('TEST 3: throws UnauthorizedException on HTTP 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401);
      });

      final apiClient = ApiClient(client: mockClient);

      expect(
        () => apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('throws ForbiddenException on HTTP 403', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Forbidden"}', 403);
      });

      final apiClient = ApiClient(client: mockClient);

      expect(
        () => apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('throws NotFoundException on HTTP 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Not Found"}', 404);
      });

      final apiClient = ApiClient(client: mockClient);

      expect(
        () => apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('TEST 9: throws ServerException on HTTP 500, 502, 503, 504', () async {
      for (final code in [500, 502, 503, 504]) {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', code);
        });

        final apiClient = ApiClient(client: mockClient);

        expect(
          () =>
              apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'Unable to connect to Bit Tool services right now.',
            ),
          ),
        );
      }
    });

    test(
      'TEST 8: throws NetworkException on ClientException / connectivity failure',
      () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection failed');
        });

        final apiClient = ApiClient(client: mockClient);

        expect(
          () =>
              apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              'Unable to connect. Please check your internet connection.',
            ),
          ),
        );
      },
    );

    test('throws RequestTimeoutException on timeout', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Timed out');
      });

      final apiClient = ApiClient(client: mockClient);

      expect(
        () => apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
        throwsA(isA<RequestTimeoutException>()),
      );
    });

    test('throws InvalidResponseException on malformed JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html><body>Not JSON</body></html>', 200);
      });

      final apiClient = ApiClient(client: mockClient);

      expect(
        () => apiClient.get(Uri.parse('https://api.bnxmail.com/api/users/me')),
        throwsA(isA<InvalidResponseException>()),
      );
    });
  });
}
