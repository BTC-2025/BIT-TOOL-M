import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/services/contact_api_service.dart';

void main() {
  group('ContactApiService Tests', () {
    late AuthStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test(
      'throws UnauthorizedException when no token exists and aborts request',
      () async {
        var requestSent = false;
        final mockClient = MockClient((request) async {
          requestSent = true;
          return http.Response('[]', 200);
        });

        final service = ContactApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );

        expect(
          () => service.getPaginatedContacts(),
          throwsA(isA<UnauthorizedException>()),
        );
        expect(requestSent, isFalse);
      },
    );

    test('getPaginatedContacts parses real Sequelize {count, rows} backend response', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/get'));
        expect(request.url.queryParameters['page'], '2');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.headers['Authorization'], 'Bearer VALID_TOKEN');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contacts retrieved successfully',
            'data': {
              'count': 25,
              'rows': [
                {
                  'id': '215052d5-2832-4968-8e17-85315022c6ae',
                  'userEmail': 'test@bnxmail.com',
                  'applicationName': 'BNX Mail',
                  'externalId': null,
                  'name': 'Bruce Wayne',
                  'phonenumber': '+1234567890',
                  'email': 'bruce@wayne.com',
                  'role': 'Executive',
                  'createdAt': '2026-08-13T12:12:05.955Z',
                  'updatedAt': '2026-08-13T12:12:05.955Z',
                  'deletedAt': null,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final result = await service.getPaginatedContacts(page: 2, limit: 10);

      expect(result.contacts.length, 1);
      expect(result.contacts.first.id, '215052d5-2832-4968-8e17-85315022c6ae');
      expect(result.contacts.first.fullName, 'Bruce Wayne');
      expect(result.contacts.first.firstName, 'Bruce');
      expect(result.contacts.first.lastName, 'Wayne');
      expect(result.contacts.first.phone, '+1234567890');
      expect(result.contacts.first.role, 'Executive');
      expect(result.pagination.page, 2);
      expect(result.pagination.total, 25);
      expect(result.pagination.totalPages, 3);
      expect(result.pagination.hasNextPage, isTrue);
    });

    test('getPaginatedContacts handles empty rows list correctly', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contacts retrieved successfully',
            'data': {
              'count': 0,
              'rows': [],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final result = await service.getPaginatedContacts(page: 1, limit: 20);

      expect(result.contacts, isEmpty);
      expect(result.pagination.total, 0);
      expect(result.pagination.totalPages, 1);
    });

    test('getPaginatedContacts throws InvalidResponseException on malformed response', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': 'unexpected string instead of map or list',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getPaginatedContacts(),
        throwsA(isA<InvalidResponseException>()),
      );
    });

    test('getAllContacts sends GET /get-all and parses {count, rows} envelope', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/get-all'));
        expect(request.headers['Authorization'], 'Bearer VALID_TOKEN');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contacts retrieved successfully',
            'data': {
              'count': 2,
              'rows': [
                {
                  'id': '1',
                  'name': 'Clark Kent',
                  'email': 'clark@dailyplanet.com',
                  'phonenumber': '111111',
                  'role': 'Reporter',
                },
                {
                  'id': '2',
                  'name': 'Lois Lane',
                  'email': 'lois@dailyplanet.com',
                  'phonenumber': '222222',
                  'role': 'Reporter',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final contacts = await service.getAllContacts();

      expect(contacts.length, 2);
      expect(contacts[0].fullName, 'Clark Kent');
      expect(contacts[0].phone, '111111');
      expect(contacts[1].fullName, 'Lois Lane');
    });

    test('getAllContacts automatically paginates across multiple pages until all records are fetched', () async {
      await storage.saveToken('VALID_TOKEN');

      final requestedOffsets = <String?>[];
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/get-all'));
        final offset = request.url.queryParameters['offset'];
        requestedOffsets.add(offset);

        if (offset == '0') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'count': 3,
                'rows': [
                  {'id': 'c1', 'name': 'First Contact', 'email': 'first@test.com'},
                  {'id': 'c2', 'name': 'Second Contact', 'email': 'second@test.com'},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (offset == '2') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'count': 3,
                'rows': [
                  {'id': 'c3', 'name': 'Third Contact', 'email': 'third@test.com'},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('[]', 200);
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final contacts = await service.getAllContacts(pageSize: 2);

      expect(contacts.length, 3);
      expect(contacts.map((c) => c.id).toList(), ['c1', 'c2', 'c3']);
      expect(requestedOffsets, ['0', '2']);
    });

    test('getAllContacts deduplicates records with identical IDs', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'count': 3,
              'rows': [
                {'id': 'dup-1', 'name': 'Duplicate User', 'email': 'dup@test.com'},
                {'id': 'dup-1', 'name': 'Duplicate User', 'email': 'dup@test.com'},
                {'id': 'unique-2', 'name': 'Unique User', 'email': 'uniq@test.com'},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final contacts = await service.getAllContacts();

      expect(contacts.length, 2);
      expect(contacts.map((c) => c.id).toList(), ['dup-1', 'unique-2']);
    });

    test('getContactById sends GET /get/:id and returns ContactModel', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/get/42'));

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contact retrieved successfully',
            'data': {
              'id': '42',
              'name': 'Diana Prince',
              'email': 'diana@themyscira.org',
              'phonenumber': '333333',
              'role': 'Diplomat',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final contact = await service.getContactById('42');

      expect(contact.id, '42');
      expect(contact.fullName, 'Diana Prince');
      expect(contact.email, 'diana@themyscira.org');
      expect(contact.phone, '333333');
      expect(contact.role, 'Diplomat');
    });

    test('createContact sends POST /add with verified backend body schema', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/add'));
        expect(request.headers['Authorization'], 'Bearer VALID_TOKEN');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Barry Allen');
        expect(body['email'], 'barry@ccpd.org');
        expect(body['phonenumber'], '123456');
        expect(body['role'], 'Forensics');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contact created successfully',
            'data': {
              'id': '99',
              'name': 'Barry Allen',
              'email': 'barry@ccpd.org',
              'phonenumber': '123456',
              'role': 'Forensics',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final created = await service.createContact(
        firstName: 'Barry',
        lastName: 'Allen',
        email: 'barry@ccpd.org',
        phone: '123456',
        role: 'Forensics',
      );

      expect(created.id, '99');
      expect(created.fullName, 'Barry Allen');
      expect(created.phone, '123456');
      expect(created.role, 'Forensics');
    });

    test('updateContact sends PUT /update/:id with verified backend schema', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/update/99'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Barry Allen');
        expect(body['phonenumber'], '987654');
        expect(body['role'], 'Scientist');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contact updated successfully',
            'data': {
              'id': '99',
              'name': 'Barry Allen',
              'email': 'barry@ccpd.org',
              'phonenumber': '987654',
              'role': 'Scientist',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final updated = await service.updateContact(
        '99',
        firstName: 'Barry',
        lastName: 'Allen',
        email: 'barry@ccpd.org',
        phone: '987654',
        role: 'Scientist',
      );

      expect(updated.id, '99');
      expect(updated.phone, '987654');
      expect(updated.role, 'Scientist');
    });

    test('deleteContact sends DELETE /delete/:id and returns true on success', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, endsWith('/delete/99'));
        expect(request.headers['Authorization'], 'Bearer VALID_TOKEN');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Contact deleted successfully',
            'data': null,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final result = await service.deleteContact('99');
      expect(result, isTrue);
    });

    test('HTTP 500 throws ServerException', () async {
      await storage.saveToken('VALID_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ContactApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getPaginatedContacts(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
