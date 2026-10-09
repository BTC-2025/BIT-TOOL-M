import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/services/note_api_service.dart';

void main() {
  group('NoteApiService Tests', () {
    late AuthStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    test('throws UnauthorizedException when no token exists and aborts request', () async {
      var requestSent = false;
      final mockClient = MockClient((request) async {
        requestSent = true;
        return http.Response('[]', 200);
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getNotes(),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(requestSent, isFalse);
    });

    test('getNotes with allApps=true sends GET /?allApps=true with Bearer token', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/api/notes'));
        expect(request.url.queryParameters['allApps'], 'true');
        expect(request.headers['Authorization'], 'Bearer VALID_NOTES_TOKEN');
        expect(request.headers['Content-Type'], 'application/json');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Notes retrieved successfully',
            'data': [
              {
                'id': 'note-1',
                'title': 'Cross App Note',
                'content': 'From Cliks',
                'applicationName': 'Cliks',
                'isPinned': true,
                'color': '#A7F3D0',
                'isArchived': false,
              },
              {
                'id': 'note-2',
                'title': 'Bit Tool Note',
                'content': 'Personal note',
                'applicationName': 'Bit Tool',
                'isPinned': false,
                'color': '#FDE047',
                'isArchived': false,
              },
            ],
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final notes = await service.getNotes(allApps: true);
      expect(notes.length, 2);
      expect(notes[0].id, 'note-1');
      expect(notes[0].applicationName, 'Cliks');
      expect(notes[0].isPinned, isTrue);
      expect(notes[1].id, 'note-2');
      expect(notes[1].applicationName, 'Bit Tool');
    });

    test('getNotes with allApps=false sends GET / without allApps parameter', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/api/notes'));
        expect(request.url.queryParameters.containsKey('allApps'), isFalse);

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': [
              {
                'id': 'note-app-only',
                'title': 'App Only Note',
                'content': 'Scoped note',
                'applicationName': 'BNX Mail',
                'isPinned': false,
                'color': '#A7F3D0',
                'isArchived': false,
              },
            ],
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final notes = await service.getNotes(allApps: false);
      expect(notes.length, 1);
      expect(notes.first.id, 'note-app-only');
    });

    test('getNoteById sends GET /:id and returns single NoteModel', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/api/notes/note-999'));

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'note-999',
              'title': 'Specific Note',
              'content': 'Detailed content',
              'applicationName': 'Bit Tool',
              'isPinned': false,
              'color': '#BAE6FD',
              'isArchived': false,
            },
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final note = await service.getNoteById('note-999');
      expect(note.id, 'note-999');
      expect(note.title, 'Specific Note');
      expect(note.color, '#BAE6FD');
    });

    test('createNote sends POST /create with documented body payload', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/api/notes/create'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'New Test Note');
        expect(body['content'], 'Testing creation flow');
        expect(body['color'], '#FBCFE8');
        expect(body['isPinned'], true);
        expect(body['applicationName'], 'Bit Tool');

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'created-uuid-123',
              'title': body['title'],
              'content': body['content'],
              'color': body['color'],
              'isPinned': body['isPinned'],
              'applicationName': body['applicationName'],
              'isArchived': false,
            },
          }),
          201,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final created = await service.createNote(
        title: 'New Test Note',
        content: 'Testing creation flow',
        color: '#FBCFE8',
        isPinned: true,
        applicationName: 'Bit Tool',
      );

      expect(created.id, 'created-uuid-123');
      expect(created.title, 'New Test Note');
      expect(created.isPinned, isTrue);
    });

    test('updateNote sends PUT /update/:id with partial payload', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/api/notes/update/target-note-id'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Updated Title Only');
        expect(body.containsKey('content'), isFalse);
        expect(body.containsKey('color'), isFalse);

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'target-note-id',
              'title': 'Updated Title Only',
              'content': 'Existing content unchanged',
              'color': '#A7F3D0',
              'isPinned': false,
              'applicationName': 'Bit Tool',
              'isArchived': false,
            },
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final updated = await service.updateNote(
        'target-note-id',
        title: 'Updated Title Only',
      );

      expect(updated.id, 'target-note-id');
      expect(updated.title, 'Updated Title Only');
    });

    test('togglePin calls updateNote with isPinned value', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/api/notes/update/pin-test-id'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['isPinned'], true);

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'pin-test-id',
              'isPinned': true,
            },
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final pinned = await service.togglePin('pin-test-id', true);
      expect(pinned.isPinned, isTrue);
    });

    test('toggleArchive calls updateNote with isArchived value', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/api/notes/update/archive-test-id'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['isArchived'], true);

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': {
              'id': 'archive-test-id',
              'isArchived': true,
            },
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final archived = await service.toggleArchive('archive-test-id', true);
      expect(archived.isArchived, isTrue);
    });

    test('deleteNote sends DELETE /delete/:id and returns true on success', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, endsWith('/api/notes/delete/del-test-id'));

        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': null,
          }),
          200,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      final deleted = await service.deleteNote('del-test-id');
      expect(deleted, isTrue);
    });

    test('maps HTTP 400 to ApiException with statusCode 400', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Title cannot be empty'}),
          400,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.createNote(title: '', content: ''),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('maps HTTP 404 to NotFoundException', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Note not found'}),
          404,
        );
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getNoteById('non-existent-id'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('maps HTTP 500 to ServerException', () async {
      await storage.saveToken('VALID_NOTES_TOKEN');

      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = NoteApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );

      expect(
        () => service.getNotes(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
