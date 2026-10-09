import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/services/calculator_api_service.dart';

void main() {
  group('CalculatorApiService Endpoint and Contract Tests', () {
    late AuthStorage storage;
    const testToken = 'MOCK_CALCULATOR_TOKEN_12345';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test('throws UnauthorizedException if no auth token is stored', () async {
      final mockClient = MockClient((_) async => http.Response('[]', 200));
      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getHistory(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('GET /history sends correct headers and returns parsed sessions', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/calculator/history');
        expect(request.headers['Authorization'], 'Bearer $testToken');
        expect(request.headers['Accept'], 'application/json');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': [
              {
                'id': 'sess-1',
                'title': 'Tape - 10:15',
                'mode': 'standard',
                'currency': 'INR',
                'applicationName': 'Bit Tool',
                'totalAmount': 500.0,
                'items': [
                  {
                    'id': 'item-1',
                    'sequence': 1,
                    'value': 500.0,
                    'operator': '+',
                    'runningTotal': 500.0,
                  }
                ],
              }
            ]
          }),
          200,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final history = await service.getHistory();
      expect(history.length, 1);
      expect(history[0].id, 'sess-1');
      expect(history[0].title, 'Tape - 10:15');
      expect(history[0].totalAmount, 500.0);
    });

    test('POST /sessions sends title, mode, currency, and parses created session', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/calculator/sessions');
        expect(request.headers['Authorization'], 'Bearer $testToken');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body);
        expect(body['title'], 'Tape - 11:00');
        expect(body['mode'], 'business');
        expect(body['currency'], 'INR');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'new-sess-123',
              'title': 'Tape - 11:00',
              'mode': 'business',
              'currency': 'INR',
              'applicationName': 'Bit Tool',
              'items': [],
            }
          }),
          201,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final session = await service.createSession(
        title: 'Tape - 11:00',
        mode: 'business',
        currency: 'INR',
      );

      expect(session.id, 'new-sess-123');
      expect(session.title, 'Tape - 11:00');
    });

    test('POST /sessions/:sessionId/items sends sequence, value, operator, runningTotal, and label', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/calculator/sessions/sess-99/items');
        expect(request.headers['Authorization'], 'Bearer $testToken');

        final body = jsonDecode(request.body);
        expect(body['sequence'], 1);
        expect(body['value'], 100);
        expect(body['operator'], '+');
        expect(body['runningTotal'], 100);
        expect(body['label'], 'Base deposit');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'tape-item-991',
              'sequence': 1,
              'value': 100,
              'operator': '+',
              'runningTotal': 100,
              'label': 'Base deposit',
            }
          }),
          201,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final item = await service.addSessionItem(
        sessionId: 'sess-99',
        sequence: 1,
        value: 100.0,
        operator: '+',
        runningTotal: 100.0,
        label: 'Base deposit',
      );

      expect(item.id, 'tape-item-991');
      expect(item.sequence, 1);
      expect(item.value, 100.0);
      expect(item.operator, '+');
    });

    test('GET /sessions/:id returns detailed session with tape items', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/calculator/sessions/sess-42');
        expect(request.headers['Authorization'], 'Bearer $testToken');

        return http.Response(
          jsonEncode({
            'id': 'sess-42',
            'title': 'Tape - Details',
            'mode': 'standard',
            'currency': 'INR',
            'applicationName': 'Cliks',
            'items': [
              {
                'id': 'it-1',
                'sequence': 1,
                'value': 200,
                'operator': '+',
                'runningTotal': 200,
              },
              {
                'id': 'it-2',
                'sequence': 2,
                'value': 50,
                'operator': '+',
                'runningTotal': 250,
              },
            ]
          }),
          200,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final session = await service.getSessionDetails('sess-42');
      expect(session.id, 'sess-42');
      expect(session.applicationName, 'Cliks');
      expect(session.items.length, 2);
      expect(session.items.last.runningTotal, 250.0);
    });

    test('DELETE /sessions/:id removes specific session', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/calculator/sessions/del-10');
        expect(request.headers['Authorization'], 'Bearer $testToken');
        return http.Response('', 204);
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      await expectLater(service.deleteSession('del-10'), completes);
    });

    test('DELETE /sessions clears all standard history', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/calculator/sessions');
        expect(request.headers['Authorization'], 'Bearer $testToken');
        return http.Response(jsonEncode({'status': 'success'}), 200);
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      await expectLater(service.clearHistory(), completes);
    });

    test('Compare Endpoints: CRUD operations work correctly', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $testToken');

        if (request.method == 'GET' && request.url.path == '/api/calculator/compare/history') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'cmp-1',
                  'title': 'Electronics Comparison',
                  'items': [],
                }
              ]
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/calculator/compare/sessions') {
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'cmp-new',
                'title': body['title'],
                'items': [],
              }
            }),
            201,
          );
        }

        if (request.method == 'POST' &&
            request.url.path == '/api/calculator/compare/sessions/cmp-new/items') {
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'item-cmp-1',
                'description': body['description'],
                'valueA': body['valueA'],
                'valueB': body['valueB'],
              }
            }),
            201,
          );
        }

        if (request.method == 'PUT' &&
            request.url.path == '/api/calculator/compare/sessions/cmp-new/items/item-cmp-1') {
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'data': {
                'id': 'item-cmp-1',
                'description': body['description'],
                'valueA': body['valueA'],
                'valueB': body['valueB'],
              }
            }),
            200,
          );
        }

        if (request.method == 'DELETE' &&
            request.url.path == '/api/calculator/compare/sessions/cmp-new/items/item-cmp-1') {
          return http.Response('', 204);
        }

        if (request.method == 'DELETE' &&
            request.url.path == '/api/calculator/compare/sessions/cmp-new') {
          return http.Response('', 204);
        }

        if (request.method == 'DELETE' &&
            request.url.path == '/api/calculator/compare/history') {
          return http.Response('', 200);
        }

        return http.Response('Not Found', 404);
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      // 1. Get history
      final history = await service.getCompareHistory();
      expect(history.length, 1);
      expect(history[0].title, 'Electronics Comparison');

      // 2. Create session
      final createdSession = await service.createCompareSession(title: 'Grocery Store');
      expect(createdSession.id, 'cmp-new');

      // 3. Add item
      final createdItem = await service.addCompareItem(
        sessionId: createdSession.id,
        description: 'Apples',
        valueA: 100,
        valueB: 120,
      );
      expect(createdItem.id, 'item-cmp-1');

      // 4. Update item
      final updatedItem = await service.updateCompareItem(
        sessionId: createdSession.id,
        itemId: createdItem.id,
        description: 'Organic Apples',
        valueA: 110,
        valueB: 125,
      );
      expect(updatedItem.description, 'Organic Apples');

      // 5. Delete item
      await expectLater(
        service.deleteCompareItem(
          sessionId: createdSession.id,
          itemId: createdItem.id,
        ),
        completes,
      );

      // 6. Delete session
      await expectLater(
        service.deleteCompareSession(createdSession.id),
        completes,
      );

      // 7. Clear compare history
      await expectLater(
        service.clearCompareHistory(),
        completes,
      );
    });

    test('handles 404 NotFound error correctly', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Session not found'}),
          404,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getSessionDetails('missing-id'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('handles 500 Server error correctly', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'message': 'Internal database error'}),
          500,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getHistory(),
        throwsA(isA<ServerException>()),
      );
    });

    test('GET /history/all parses cross-app sessions from data.rows envelope', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/calculator/history/all');
        expect(request.headers['Authorization'], 'Bearer $testToken');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'count': 3,
              'rows': [
                {
                  'id': 'bnx-1',
                  'title': 'Tape - 15:47 [BNX Mail]',
                  'applicationName': 'BNX Mail',
                  'totalAmount': 100.0,
                  'items': [
                    {'id': 'i-1', 'sequence': 1, 'value': 99.0, 'operator': '=', 'runningTotal': 99.0},
                    {'id': 'i-2', 'sequence': 2, 'value': 1.0, 'operator': '+', 'runningTotal': 100.0},
                  ],
                },
                {
                  'id': 'bit-1',
                  'title': 'Tape - 10:06:05',
                  'applicationName': 'Bit Tool',
                  'totalAmount': 7553.0,
                  'items': [],
                },
                {
                  'id': 'cliks-1',
                  'title': 'Tape - 14:20:00 [Cliks]',
                  'applicationName': 'Cliks',
                  'totalAmount': 2450.0,
                  'items': [],
                },
              ],
            },
          }),
          200,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final sessions = await service.getHistoryAll();
      expect(sessions.length, 3);
      expect(sessions[0].applicationName, 'BNX Mail');
      expect(sessions[0].items.length, 2);
      expect(sessions[1].applicationName, 'Bit Tool');
      expect(sessions[2].applicationName, 'Cliks');
    });

    test('GET /history handles empty collection in data.rows gracefully', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'count': 0,
              'rows': [],
            },
          }),
          200,
        );
      });

      final service = CalculatorApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final sessions = await service.getHistory();
      expect(sessions.isEmpty, true);
    });
  });
}
