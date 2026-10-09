import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/services/calendar_api_service.dart';

void main() {
  group('CalendarApiService Tests', () {
    late AuthStorage storage;
    const testToken = 'MOCK_CALENDAR_JWT_TOKEN';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test('throws UnauthorizedException if no auth token is stored', () async {
      final mockClient = MockClient((_) async => http.Response('[]', 200));
      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getMonthEvents(year: 2026, month: 10),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('getEventsForMonth sends GET with year and zero-padded month query parameters', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/calendar/events/month');
        expect(request.url.queryParameters['year'], '2026');
        expect(request.url.queryParameters['month'], '08');
        expect(request.headers['Authorization'], 'Bearer $testToken');
        expect(request.headers['Content-Type'], 'application/json');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': [
              {
                'id': 'evt-101',
                'title': 'Sprint Kickoff',
                'description': 'Sprint 42 planning',
                'startTime': '2026-08-01T09:00:00.000Z',
                'endTime': '2026-08-01T10:00:00.000Z',
                'category': {
                  'id': 'cat-1',
                  'name': 'Sprint',
                  'color': '#3B82F6',
                },
              }
            ],
          }),
          200,
        );
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final events = await service.getMonthEvents(year: 2026, month: 8);
      expect(events.length, 1);
      expect(events.first.id, 'evt-101');
      expect(events.first.title, 'Sprint Kickoff');
      expect(events.first.category, 'Sprint');
    });

    test('createEvent verifies contract: sends ISO-8601 strings and category (without redundant date)', () async {
      await storage.saveToken(testToken);

      final start = DateTime.utc(2026, 10, 9, 10, 0);
      final end = DateTime.utc(2026, 10, 9, 11, 0);

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/calendar/events');
        expect(request.headers['Authorization'], 'Bearer $testToken');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Architecture Review');
        expect(body['description'], 'Discuss API schema');
        expect(body.containsKey('date'), isFalse);
        expect(body['startTime'], start.toIso8601String());
        expect(body['endTime'], end.toIso8601String());
        expect(body['categoryId'], 'cat-eng');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'evt-created-1',
              'title': 'Architecture Review',
              'description': 'Discuss API schema',
              'startTime': start.toIso8601String(),
              'endTime': end.toIso8601String(),
              'categoryId': 'cat-eng',
            },
          }),
          201,
        );
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final event = await service.createEvent(
        title: 'Architecture Review',
        description: 'Discuss API schema',
        startTime: start,
        endTime: end,
        categoryId: 'cat-eng',
      );

      expect(event.id, 'evt-created-1');
      expect(event.title, 'Architecture Review');
    });

    test('updateEvent sends PUT /api/calendar/events/:id', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/calendar/events/evt-999');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Renamed Event');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'evt-999',
              'title': 'Renamed Event',
              'startTime': '2026-10-09T10:00:00.000Z',
              'endTime': '2026-10-09T11:00:00.000Z',
            },
          }),
          200,
        );
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final updated = await service.updateEvent(
        'evt-999',
        title: 'Renamed Event',
      );
      expect(updated.title, 'Renamed Event');
    });

    test('deleteEvent sends DELETE /api/calendar/events/:id', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/calendar/events/evt-del');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Event deleted successfully',
          }),
          200,
        );
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      await expectLater(service.deleteEvent('evt-del'), completes);
    });

    test('getCategories and createCategory interact with /api/calendar/categories', () async {
      await storage.saveToken(testToken);

      var isPost = false;
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/calendar/categories');
        if (request.method == 'POST') {
          isPost = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'New Category');
          expect(body['color'], '#10B981');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'cat-new-uuid',
                'name': 'New Category',
                'color': '#10B981',
              },
            }),
            201,
          );
        } else {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': [
                {
                  'id': 'cat-1',
                  'name': 'Personal',
                  'color': '#3B82F6',
                }
              ],
            }),
            200,
          );
        }
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final list = await service.getCategories();
      expect(list.length, 1);
      expect(list.first.name, 'Personal');

      final created = await service.createCategory(
        name: 'New Category',
        color: '#10B981',
      );
      expect(isPost, isTrue);
      expect(created.id, 'cat-new-uuid');
      expect(created.name, 'New Category');
    });

    test('Reminders CRUD and completion endpoints work correctly', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/api/calendar/reminders');
          expect(request.url.queryParameters['date'], '2026-10-09');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': [
                {
                  'id': 'rem-1',
                  'title': 'Call Partner',
                  'date': '2026-10-09',
                  'time': '15:30',
                  'status': 'pending',
                }
              ],
            }),
            200,
          );
        } else if (request.method == 'POST') {
          expect(request.url.path, '/api/calendar/reminders');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['title'], 'New Reminder');
          expect(body['date'], '2026-10-09');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'rem-created',
                'title': 'New Reminder',
                'date': '2026-10-09',
                'time': '11:00',
                'status': 'pending',
              },
            }),
            201,
          );
        } else if (request.method == 'PUT' && request.url.path.endsWith('/complete')) {
          expect(request.url.path, '/api/calendar/reminders/rem-1/complete');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'rem-1',
                'title': 'Call Partner',
                'date': '2026-10-09',
                'time': '15:30',
                'status': 'completed',
              },
            }),
            200,
          );
        } else if (request.method == 'DELETE') {
          expect(request.url.path, '/api/calendar/reminders/rem-1');
          return http.Response(
            jsonEncode({'status': 'success', 'message': 'Reminder deleted'}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final reminders = await service.getReminders('2026-10-09');
      expect(reminders.length, 1);
      expect(reminders.first.isCompleted, isFalse);

      final created = await service.createReminder(
        title: 'New Reminder',
        date: '2026-10-09',
        time: '11:00',
      );
      expect(created.id, 'rem-created');

      final completed = await service.completeReminder('rem-1');
      expect(completed.isCompleted, isTrue);

      await expectLater(service.deleteReminder('rem-1'), completes);
    });

    test('Date-Linked Notes CRUD verifies schema without color field', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, '/api/calendar/notes');
          expect(request.url.queryParameters['date'], '2026-10-09');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': [
                {
                  'id': 'dnote-1',
                  'title': 'Standup Notes',
                  'date': '2026-10-09',
                  'content': 'Sprint items',
                }
              ],
            }),
            200,
          );
        } else if (request.method == 'POST') {
          expect(request.url.path, '/api/calendar/notes');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['title'], 'New Note');
          expect(body['date'], '2026-10-09');
          expect(body['content'], 'Body content');
          // Backend rejects request containing "color" field
          expect(body.containsKey('color'), isFalse);

          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'dnote-created',
                'title': 'New Note',
                'date': '2026-10-09',
                'content': 'Body content',
              },
            }),
            201,
          );
        } else if (request.method == 'DELETE') {
          expect(request.url.path, '/api/calendar/notes/dnote-1');
          return http.Response(
            jsonEncode({'status': 'success', 'message': 'Note deleted'}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final notes = await service.getDateNotes('2026-10-09');
      expect(notes.length, 1);
      expect(notes.first.title, 'Standup Notes');

      final created = await service.createDateNote(
        title: 'New Note',
        date: '2026-10-09',
        content: 'Body content',
      );
      expect(created.id, 'dnote-created');

      await expectLater(service.deleteDateNote('dnote-1'), completes);
    });

    test('searchCalendar sends query parameter and parses unified response', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/calendar/search');
        expect(request.url.queryParameters['query'], 'quarterly');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'events': [
                {
                  'id': 'evt-q',
                  'title': 'Quarterly Review',
                  'startTime': '2026-10-09T10:00:00.000Z',
                  'endTime': '2026-10-09T11:00:00.000Z',
                }
              ],
              'notes': [
                {
                  'id': 'note-q',
                  'title': 'Quarterly Notes',
                  'date': '2026-10-09',
                  'content': 'Targets met',
                }
              ],
              'reminders': [
                {
                  'id': 'rem-q',
                  'title': 'Quarterly Tax',
                  'date': '2026-10-15',
                }
              ],
            },
          }),
          200,
        );
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final results = await service.searchCalendar('quarterly');
      expect(results.events.length, 1);
      expect(results.events.first.title, 'Quarterly Review');
      expect(results.notes.length, 1);
      expect(results.notes.first.title, 'Quarterly Notes');
      expect(results.reminders.length, 1);
      expect(results.reminders.first.title, 'Quarterly Tax');
    });

    test('handles 500 server error by throwing ApiException', () async {
      await storage.saveToken(testToken);

      final mockClient = MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = CalendarApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getMonthEvents(year: 2026, month: 10),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
