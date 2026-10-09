import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../models/calendar_models.dart';

/// Dedicated service responsible for Calendar backend API communications.
class CalendarApiService {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  CalendarApiService({ApiClient? apiClient, AuthStorage? authStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _authStorage = authStorage ?? AuthStorage();

  /// Retrieves the persisted authentication token or throws [UnauthorizedException].
  Future<String> _requireToken() async {
    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[CalendarAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }
    if (!hasToken) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarAPI] Aborting request: no authentication token available in storage.',
        );
      }
      throw const UnauthorizedException('No authentication token available.');
    }
    return token.trim();
  }

  // ==========================================
  // Categories API
  // ==========================================

  /// Fetches event categories from the backend.
  Future<List<CalendarCategory>> getCategories() async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarCategoriesUri;

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Fetching categories: GET $uri');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final categories = _extractList(raw)
          .whereType<Map<String, dynamic>>()
          .map(CalendarCategory.fromJson)
          .toList();

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Parsed ${categories.length} category(ies).');
      }
      return categories;
    } catch (e) {
      _logError('getCategories', e);
      rethrow;
    }
  }

  /// Creates a new event category.
  Future<CalendarCategory> createCategory({
    required String name,
    required String color,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarCategoryCreateUri;

    final payload = <String, dynamic>{
      'name': name.trim(),
      'color': color.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Creating category "$name" (POST $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final category = CalendarCategory.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Category created successfully: ${category.id}');
      }
      return category;
    } catch (e) {
      _logError('createCategory', e);
      rethrow;
    }
  }

  // ==========================================
  // Events API
  // ==========================================

  /// Fetches events for a specific month and year.
  Future<List<CalendarEvent>> getMonthEvents({
    required int year,
    required int month,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarEventsMonthUri(year, month);

    if (kDebugMode) {
      debugPrint(
        '[CalendarAPI] Fetching events for year=$year month=$month (GET $uri)',
      );
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final rawList = _extractList(raw);
      final events = <CalendarEvent>[];
      for (final item in rawList) {
        if (item is Map) {
          try {
            final map = Map<String, dynamic>.from(item);
            events.add(CalendarEvent.fromJson(map));
          } catch (itemError) {
            if (kDebugMode) {
              debugPrint(
                '[CalendarAPI] Error parsing event from payload: $itemError; raw item: $item',
              );
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[CalendarAPI] Parsed ${events.length} event(s) for $year-$month.',
        );
      }
      return events;
    } catch (e) {
      _logError('getMonthEvents', e);
      rethrow;
    }
  }

  /// Creates a calendar event on the backend.
  Future<CalendarEvent> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String categoryId,
    String? description,
    String? location,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarEventCreateUri;

    final payload = <String, dynamic>{
      'title': title.trim(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'categoryId': categoryId.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Creating event "$title" (POST $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final event = CalendarEvent.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Event created successfully: ${event.id}');
      }
      return event;
    } catch (e) {
      _logError('createEvent', e);
      rethrow;
    }
  }

  /// Updates an existing calendar event.
  Future<CalendarEvent> updateEvent(
    String id, {
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? categoryId,
    String? description,
    String? location,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarEventUpdateUri(id);

    final payload = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (startTime != null) 'startTime': startTime.toIso8601String(),
      if (endTime != null) 'endTime': endTime.toIso8601String(),
      if (categoryId != null) 'categoryId': categoryId.trim(),
      if (description != null) 'description': description.trim(),
      if (location != null) 'location': location.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Updating event $id (PUT $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.put(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final event = CalendarEvent.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Event $id updated successfully.');
      }
      return event;
    } catch (e) {
      _logError('updateEvent($id)', e);
      rethrow;
    }
  }

  /// Deletes a calendar event.
  Future<bool> deleteEvent(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarEventDeleteUri(id);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Deleting event $id (DELETE $uri)');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint('[CalendarAPI] Event $id deleted successfully.');
      }
      return true;
    } catch (e) {
      _logError('deleteEvent($id)', e);
      rethrow;
    }
  }

  // ==========================================
  // Reminders API
  // ==========================================

  /// Fetches reminders for a specific date (YYYY-MM-DD).
  Future<List<CalendarReminder>> getReminders(String date) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarRemindersUri(date);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Fetching reminders for date=$date (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final reminders = _extractList(raw)
          .whereType<Map<String, dynamic>>()
          .map(CalendarReminder.fromJson)
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[CalendarAPI] Parsed ${reminders.length} reminder(s) for $date.',
        );
      }
      return reminders;
    } catch (e) {
      _logError('getReminders', e);
      rethrow;
    }
  }

  /// Creates a reminder for a specific date.
  Future<CalendarReminder> createReminder({
    required String title,
    required String date,
    required String time,
    String? description,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarReminderCreateUri;

    final payload = <String, dynamic>{
      'title': title.trim(),
      'date': date.trim(),
      'time': time.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Creating reminder "$title" (POST $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final reminder = CalendarReminder.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalendarAPI] Reminder created successfully: ${reminder.id}',
        );
      }
      return reminder;
    } catch (e) {
      _logError('createReminder', e);
      rethrow;
    }
  }

  /// Updates an existing reminder.
  Future<CalendarReminder> updateReminder(
    String id, {
    String? title,
    String? date,
    String? time,
    String? description,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarReminderUpdateUri(id);

    final payload = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (date != null) 'date': date.trim(),
      if (time != null) 'time': time.trim(),
      if (description != null) 'description': description.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Updating reminder $id (PUT $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.put(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final reminder = CalendarReminder.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Reminder $id updated successfully.');
      }
      return reminder;
    } catch (e) {
      _logError('updateReminder($id)', e);
      rethrow;
    }
  }

  /// Marks a reminder as completed.
  Future<CalendarReminder> completeReminder(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarReminderCompleteUri(id);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Marking reminder $id as completed (PUT $uri)');
    }

    try {
      final dynamic raw = await _apiClient.put(uri, token: token);
      final data = _extractMap(raw);
      final reminder = CalendarReminder.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Reminder $id completed successfully.');
      }
      return reminder;
    } catch (e) {
      _logError('completeReminder($id)', e);
      rethrow;
    }
  }

  /// Deletes a reminder.
  Future<bool> deleteReminder(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarReminderDeleteUri(id);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Deleting reminder $id (DELETE $uri)');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint('[CalendarAPI] Reminder $id deleted successfully.');
      }
      return true;
    } catch (e) {
      _logError('deleteReminder($id)', e);
      rethrow;
    }
  }

  // ==========================================
  // Date-Linked Notes API
  // ==========================================

  /// Fetches date-linked notes for a specific date (YYYY-MM-DD).
  Future<List<CalendarDateNote>> getDateNotes(String date) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarNotesUri(date);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Fetching date notes for date=$date (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final notes = _extractList(raw)
          .whereType<Map<String, dynamic>>()
          .map(CalendarDateNote.fromJson)
          .toList();

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Parsed ${notes.length} date note(s) for $date.');
      }
      return notes;
    } catch (e) {
      _logError('getDateNotes', e);
      rethrow;
    }
  }

  /// Creates a date-linked note.
  Future<CalendarDateNote> createDateNote({
    required String title,
    required String date,
    required String content,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarNoteCreateUri;

    final payload = <String, dynamic>{
      'title': title.trim(),
      'date': date.trim(),
      'content': content.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Creating date note "$title" (POST $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.post(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final note = CalendarDateNote.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Date note created successfully: ${note.id}');
      }
      return note;
    } catch (e) {
      _logError('createDateNote', e);
      rethrow;
    }
  }

  /// Updates an existing date-linked note.
  Future<CalendarDateNote> updateDateNote(
    String id, {
    String? title,
    String? content,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarNoteUpdateUri(id);

    final payload = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (content != null) 'content': content.trim(),
    };

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Updating date note $id (PUT $uri)');
    }

    try {
      final dynamic raw =
          await _apiClient.put(uri, body: payload, token: token);
      final data = _extractMap(raw);
      final note = CalendarDateNote.fromJson(data);

      if (kDebugMode) {
        debugPrint('[CalendarAPI] Date note $id updated successfully.');
      }
      return note;
    } catch (e) {
      _logError('updateDateNote($id)', e);
      rethrow;
    }
  }

  /// Deletes a date-linked note.
  Future<bool> deleteDateNote(String id) async {
    final token = await _requireToken();
    final uri = ApiConfig.calendarNoteDeleteUri(id);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Deleting date note $id (DELETE $uri)');
    }

    try {
      await _apiClient.delete(uri, token: token);
      if (kDebugMode) {
        debugPrint('[CalendarAPI] Date note $id deleted successfully.');
      }
      return true;
    } catch (e) {
      _logError('deleteDateNote($id)', e);
      rethrow;
    }
  }

  // ==========================================
  // Global Calendar Search API
  // ==========================================

  /// Performs a global calendar search across events, reminders, and date notes.
  Future<CalendarSearchResult> searchCalendar(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const CalendarSearchResult();
    }

    final token = await _requireToken();
    final uri = ApiConfig.calendarSearchUri(trimmed);

    if (kDebugMode) {
      debugPrint('[CalendarAPI] Searching calendar for "$trimmed" (GET $uri)');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      final data = _extractMap(raw);
      final result = CalendarSearchResult.fromJson(data);

      if (kDebugMode) {
        debugPrint(
          '[CalendarAPI] Search results: ${result.events.length} event(s), ${result.reminders.length} reminder(s), ${result.notes.length} note(s).',
        );
      }
      return result;
    } catch (e) {
      _logError('searchCalendar', e);
      rethrow;
    }
  }

  // ==========================================
  // Helper Parsers & Diagnostics
  // ==========================================

  List<dynamic> _extractList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map) {
      if (raw['data'] is List) return raw['data'] as List;
      if (raw['events'] is List) return raw['events'] as List;
      if (raw['categories'] is List) return raw['categories'] as List;
      if (raw['reminders'] is List) return raw['reminders'] as List;
      if (raw['notes'] is List) return raw['notes'] as List;
      if (raw['items'] is List) return raw['items'] as List;
      if (raw['result'] is List) return raw['result'] as List;
      if (raw['data'] is Map) {
        final sub = raw['data'] as Map;
        if (sub['events'] is List) return sub['events'] as List;
        if (sub['categories'] is List) return sub['categories'] as List;
        if (sub['reminders'] is List) return sub['reminders'] as List;
        if (sub['notes'] is List) return sub['notes'] as List;
        if (sub['items'] is List) return sub['items'] as List;
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw == null) return const {};
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) {
        return raw['data'] as Map<String, dynamic>;
      }
      return raw;
    }
    return const {};
  }

  void _logError(String operation, Object error) {
    if (kDebugMode) {
      debugPrint('[CalendarAPI] Error in $operation: $error');
      if (error is ServerException) {
        debugPrint(
          '[CalendarAPI] Server error status code: ${error.statusCode}',
        );
        debugPrint(
          '[CalendarAPI] Server error response body: ${error.responseBody}',
        );
      }
    }
  }
}
