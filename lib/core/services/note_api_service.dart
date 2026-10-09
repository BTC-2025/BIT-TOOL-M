import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../models/note_model.dart';

/// Dedicated service responsible for Notes backend API communications.
class NoteApiService {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  NoteApiService({ApiClient? apiClient, AuthStorage? authStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _authStorage = authStorage ?? AuthStorage();

  /// Retrieves the persisted authentication token or throws [UnauthorizedException].
  Future<String> _requireToken() async {
    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[NotesAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }
    if (!hasToken) {
      if (kDebugMode) {
        debugPrint(
          '[NotesAPI] Aborting request: no authentication token available in storage.',
        );
      }
      throw const UnauthorizedException('No authentication token available.');
    }
    return token.trim();
  }

  /// Retrieves notes from the backend, supporting cross-application retrieval via [allApps].
  Future<List<NoteModel>> getNotes({bool allApps = true}) async {
    final token = await _requireToken();
    final uri = ApiConfig.notesGetUri(allApps: allApps);

    if (kDebugMode) {
      debugPrint('[NotesAPI] Fetch initiated (allApps: $allApps).');
      debugPrint('[NotesAPI] Final request: GET $uri');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final notes = _extractNotesList(raw);
      if (kDebugMode) {
        debugPrint('[NotesAPI] Successfully parsed ${notes.length} note(s).');
      }
      return notes;
    } catch (e) {
      _logError('getNotes', e);
      rethrow;
    }
  }

  /// Retrieves a single note's fresh details by its unique backend ID.
  Future<NoteModel> getNoteById(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.noteGetByIdUri(id);

    if (kDebugMode) {
      debugPrint('[NotesAPI] Fetch note by ID: $id');
      debugPrint('[NotesAPI] Final request: GET $uri');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      return _extractSingleNote(raw);
    } catch (e) {
      _logError('getNoteById($id)', e);
      rethrow;
    }
  }

  /// Creates a new note on the backend.
  Future<NoteModel> createNote({
    required String title,
    required String content,
    String? color,
    bool isPinned = false,
    String? applicationName,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.noteCreateUri;

    final payload = <String, dynamic>{
      'title': title,
      'content': content,
      'color': color ?? '#A7F3D0',
      'isPinned': isPinned,
      if (applicationName != null && applicationName.trim().isNotEmpty)
        'applicationName': applicationName.trim(),
    };

    if (kDebugMode) {
      debugPrint('[NotesAPI] Create note initiated. Keys: ${payload.keys.toList()}');
      debugPrint('[NotesAPI] Final request: POST $uri');
    }

    try {
      final dynamic raw = await _apiClient.post(uri, body: payload, token: token);
      final createdNote = _extractSingleNote(raw);
      if (kDebugMode) {
        debugPrint(
          '[NotesAPI] Note created successfully with ID: ${createdNote.id}',
        );
      }
      return createdNote;
    } catch (e) {
      _logError('createNote', e);
      rethrow;
    }
  }

  /// Updates an existing note using partial payload updates.
  Future<NoteModel> updateNote(
    String id, {
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    bool? isArchived,
    String? applicationName,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.noteUpdateUri(id);

    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (color != null) 'color': color,
      if (isPinned != null) 'isPinned': isPinned,
      if (isArchived != null) 'isArchived': isArchived,
      if (applicationName != null && applicationName.trim().isNotEmpty)
        'applicationName': applicationName.trim(),
    };

    if (kDebugMode) {
      debugPrint(
        '[NotesAPI] Update note $id initiated. Keys: ${payload.keys.toList()}',
      );
      debugPrint('[NotesAPI] Final request: PUT $uri');
    }

    try {
      final dynamic raw = await _apiClient.put(uri, body: payload, token: token);
      final updatedNote = _extractSingleNote(raw);
      if (kDebugMode) {
        debugPrint('[NotesAPI] Note $id updated successfully.');
      }
      return updatedNote;
    } catch (e) {
      _logError('updateNote($id)', e);
      rethrow;
    }
  }

  /// Deletes a note by its backend ID.
  Future<bool> deleteNote(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.noteDeleteUri(id);

    if (kDebugMode) {
      debugPrint('[NotesAPI] Delete note initiated for ID: $id');
      debugPrint('[NotesAPI] Final request: DELETE $uri');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint('[NotesAPI] Note $id deleted successfully.');
      }
      return true;
    } catch (e) {
      _logError('deleteNote($id)', e);
      rethrow;
    }
  }

  /// Toggles the pin status of a note.
  Future<NoteModel> togglePin(String id, bool isPinned) =>
      updateNote(id, isPinned: isPinned);

  /// Toggles the archive status of a note.
  Future<NoteModel> toggleArchive(String id, bool isArchived) =>
      updateNote(id, isArchived: isArchived);

  // --- Helper Parsers ---

  List<NoteModel> _extractNotesList(dynamic raw) {
    if (raw == null) return [];

    List<dynamic>? list;

    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      if (raw['data'] is List) {
        list = raw['data'] as List<dynamic>;
      } else if (raw['notes'] is List) {
        list = raw['notes'] as List<dynamic>;
      } else if (raw['items'] is List) {
        list = raw['items'] as List<dynamic>;
      } else if (raw['data'] is Map<String, dynamic>) {
        final dataMap = raw['data'] as Map<String, dynamic>;
        if (dataMap['notes'] is List) {
          list = dataMap['notes'] as List<dynamic>;
        } else if (dataMap['data'] is List) {
          list = dataMap['data'] as List<dynamic>;
        } else if (dataMap['items'] is List) {
          list = dataMap['items'] as List<dynamic>;
        }
      }
    }

    if (list == null) {
      throw const FormatException(
        'Server returned an unexpected notes list response format.',
      );
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) => NoteModel.fromJson(item))
        .toList();
  }

  NoteModel _extractSingleNote(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return NoteModel.fromJson(raw['data'] as Map<String, dynamic>);
      } else if (raw['note'] is Map<String, dynamic>) {
        return NoteModel.fromJson(raw['note'] as Map<String, dynamic>);
      } else if (raw.containsKey('id')) {
        return NoteModel.fromJson(raw);
      }
    }

    throw const FormatException(
      'Server returned an unexpected single note response format.',
    );
  }

  void _logError(String method, Object error) {
    if (!kDebugMode) return;
    debugPrint('[NotesAPI] Error in $method: $error');
    if (error is ServerException) {
      debugPrint('[NotesAPI] Server error status code: ${error.statusCode}');
      if (error.responseBody != null) {
        debugPrint('[NotesAPI] Server error response body: ${error.responseBody}');
      }
    }
  }
}
