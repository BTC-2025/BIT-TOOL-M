import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/calendar_models.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/calendar_provider.dart';
import 'package:bit_tools_backend/core/services/calendar_api_service.dart';

class FakeCalendarApiService implements CalendarApiService {
  List<CalendarEvent> mockEvents = [];
  List<CalendarCategory> mockCategories = [];
  List<CalendarReminder> mockReminders = [];
  List<CalendarDateNote> mockNotes = [];
  CalendarSearchResult? mockSearchResult;
  Exception? errorToThrow;

  int getMonthEventsCalls = 0;
  int createEventCalls = 0;
  int updateEventCalls = 0;
  int deleteEventCalls = 0;
  int getCategoriesCalls = 0;
  int createCategoryCalls = 0;
  int getRemindersCalls = 0;
  int completeReminderCalls = 0;
  int deleteReminderCalls = 0;
  int searchCalls = 0;

  @override
  Future<List<CalendarCategory>> getCategories() async {
    getCategoriesCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockCategories);
  }

  @override
  Future<CalendarCategory> createCategory({
    required String name,
    required String color,
  }) async {
    createCategoryCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final cat = CalendarCategory(
      id: 'cat-mock-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: color,
    );
    mockCategories.add(cat);
    return cat;
  }

  @override
  Future<List<CalendarEvent>> getMonthEvents({
    required int year,
    required int month,
  }) async {
    getMonthEventsCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockEvents);
  }

  @override
  Future<CalendarEvent> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? categoryId,
    String? description,
    String? location,
  }) async {
    createEventCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final event = CalendarEvent(
      id: 'evt-mock-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      startTime: startTime,
      endTime: endTime,
      categoryId: categoryId,
      description: description ?? '',
      location: location ?? '',
    );
    mockEvents.add(event);
    return event;
  }

  @override
  Future<CalendarEvent> updateEvent(
    String id, {
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? categoryId,
    String? description,
    String? location,
  }) async {
    updateEventCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final index = mockEvents.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final old = mockEvents[index];
      final updated = old.copyWith(
        title: title ?? old.title,
        startTime: startTime ?? old.startTime,
        endTime: endTime ?? old.endTime,
        categoryId: categoryId ?? old.categoryId,
        description: description ?? old.description,
        location: location ?? old.location,
      );
      mockEvents[index] = updated;
      return updated;
    }
    throw Exception('Event not found');
  }

  @override
  Future<bool> deleteEvent(String id) async {
    deleteEventCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockEvents.removeWhere((e) => e.id == id);
    return true;
  }

  @override
  Future<List<CalendarReminder>> getReminders(String date) async {
    getRemindersCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockReminders.where((r) => r.date == date));
  }

  @override
  Future<CalendarReminder> createReminder({
    required String title,
    required String date,
    String? time,
    String? description,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final reminder = CalendarReminder(
      id: 'rem-mock-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      date: date,
      time: time ?? '09:00',
      description: description ?? '',
      status: 'pending',
    );
    mockReminders.add(reminder);
    return reminder;
  }

  @override
  Future<CalendarReminder> updateReminder(
    String id, {
    String? title,
    String? date,
    String? time,
    String? description,
    String? status,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final index = mockReminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final old = mockReminders[index];
      final updated = old.copyWith(
        title: title ?? old.title,
        date: date ?? old.date,
        time: time ?? old.time,
        description: description ?? old.description,
        status: status ?? old.status,
      );
      mockReminders[index] = updated;
      return updated;
    }
    throw Exception('Reminder not found');
  }

  @override
  Future<CalendarReminder> completeReminder(String id) async {
    completeReminderCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final index = mockReminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final updated = mockReminders[index].copyWith(status: 'completed');
      mockReminders[index] = updated;
      return updated;
    }
    throw Exception('Reminder not found');
  }

  @override
  Future<bool> deleteReminder(String id) async {
    deleteReminderCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockReminders.removeWhere((r) => r.id == id);
    return true;
  }

  @override
  Future<List<CalendarDateNote>> getDateNotes(String date) async {
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockNotes.where((n) => n.date == date));
  }

  @override
  Future<CalendarDateNote> createDateNote({
    required String title,
    required String date,
    required String content,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final note = CalendarDateNote(
      id: 'dnote-mock-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      date: date,
      content: content,
    );
    mockNotes.add(note);
    return note;
  }

  @override
  Future<CalendarDateNote> updateDateNote(
    String id, {
    String? title,
    String? content,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    final index = mockNotes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final old = mockNotes[index];
      final updated = old.copyWith(
        title: title ?? old.title,
        content: content ?? old.content,
      );
      mockNotes[index] = updated;
      return updated;
    }
    throw Exception('Note not found');
  }

  @override
  Future<bool> deleteDateNote(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    mockNotes.removeWhere((n) => n.id == id);
    return true;
  }

  @override
  Future<CalendarSearchResult> searchCalendar(String query) async {
    searchCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return mockSearchResult ?? const CalendarSearchResult.empty();
  }
}

class FakeAuthProvider extends Fake implements AuthProvider {
  UserModel? mockUser;
  bool mockIsAuthenticated = true;

  @override
  UserModel? get user => mockUser;

  @override
  bool get isAuthenticated => mockIsAuthenticated;
}

void main() {
  group('CalendarProvider Unit & State Tests', () {
    late FakeCalendarApiService apiService;
    late FakeAuthProvider authProvider;
    late CalendarProvider provider;

    setUp(() {
      apiService = FakeCalendarApiService();
      authProvider = FakeAuthProvider();
      authProvider.mockUser = const UserModel(
        id: 149,
        email: 'user149@bnxmail.com',
        fullName: 'Account 149',
      );

      provider = CalendarProvider(
        null,
        apiService,
        authProvider,
      );
    });

    test('initialization sets initial date and loads month data', () async {
      apiService.mockEvents = [
        CalendarEvent(
          id: 'evt-init',
          title: 'Initial Event',
          startTime: DateTime.utc(2026, 10, 9, 9, 0),
          endTime: DateTime.utc(2026, 10, 9, 10, 0),
        ),
      ];

      await provider.fetchMonthEvents();

      expect(provider.status, CalendarStatus.loaded);
      expect(provider.events.length, 1);
      expect(provider.events.first.title, 'Initial Event');
      expect(apiService.getMonthEventsCalls, greaterThanOrEqualTo(1));
    });

    test('month navigation correctly transitions months and loads events', () async {
      final initialMonth = provider.currentMonth.month;
      final initialYear = provider.currentMonth.year;

      await provider.nextMonth();
      final expectedNextMonth = initialMonth == 12 ? 1 : initialMonth + 1;
      expect(provider.currentMonth.month, expectedNextMonth);

      await provider.previousMonth();
      expect(provider.currentMonth.month, initialMonth);
      expect(provider.currentMonth.year, initialYear);
    });

    test('selectDate updates selectedDate and fetches date-linked reminders/notes', () async {
      final targetDate = DateTime(2026, 10, 15);
      final formattedDate = CalendarProvider.formatDate(targetDate);

      apiService.mockReminders = [
        CalendarReminder(
          id: 'rem-15',
          title: 'Review Taxes',
          date: formattedDate,
          time: '10:00',
        ),
      ];
      apiService.mockNotes = [
        CalendarDateNote(
          id: 'note-15',
          title: 'Tax Notes',
          date: formattedDate,
          content: 'Details here',
        ),
      ];

      await provider.selectDate(targetDate);

      expect(provider.selectedDate, targetDate);
      expect(provider.selectedDateReminders.length, 1);
      expect(provider.selectedDateReminders.first.title, 'Review Taxes');
      expect(provider.selectedDateNotes.length, 1);
      expect(provider.selectedDateNotes.first.title, 'Tax Notes');
    });

    test('createEvent adds event to collection and refreshes state', () async {
      final newEvent = await provider.createEvent(
        title: 'New Strategy Meeting',
        startTime: DateTime.utc(2026, 10, 9, 14, 0),
        endTime: DateTime.utc(2026, 10, 9, 15, 0),
        categoryId: 'cat-mock',
        description: 'Plan Q1 roadmap',
      );

      expect(newEvent.title, 'New Strategy Meeting');
      expect(provider.events.any((e) => e.title == 'New Strategy Meeting'), isTrue);
      expect(apiService.createEventCalls, 1);
    });

    test('updateEvent modifies event and updates local state', () async {
      final created = await provider.createEvent(
        title: 'Original Title',
        startTime: DateTime.utc(2026, 10, 9, 10, 0),
        endTime: DateTime.utc(2026, 10, 9, 11, 0),
        categoryId: 'cat-mock',
      );

      final updated = await provider.updateEvent(
        created.id,
        title: 'Updated Title',
      );

      expect(updated.title, 'Updated Title');
      final found = provider.events.firstWhere((e) => e.id == created.id);
      expect(found.title, 'Updated Title');
    });

    test('deleteEvent removes event from list', () async {
      final created = await provider.createEvent(
        title: 'To Be Deleted',
        startTime: DateTime.utc(2026, 10, 9, 12, 0),
        endTime: DateTime.utc(2026, 10, 9, 13, 0),
        categoryId: 'cat-mock',
      );
      expect(provider.events.any((e) => e.id == created.id), isTrue);

      await provider.deleteEvent(created.id);
      expect(provider.events.any((e) => e.id == created.id), isFalse);
    });

    test('createCategory adds category to categories list', () async {
      final cat = await provider.createCategory(
        name: 'Design',
        color: '#8B5CF6',
      );

      expect(cat.name, 'Design');
      expect(provider.categories.any((c) => c.name == 'Design'), isTrue);
    });

    test('completeReminder marks reminder completed and updates state', () async {
      final dateStr = CalendarProvider.formatDate(provider.selectedDate);
      final rem = await provider.createReminder(
        title: 'Check Builds',
        date: dateStr,
        time: '16:00',
      );

      expect(rem.isCompleted, isFalse);

      await provider.completeReminder(rem.id);

      final updated = provider.selectedDateReminders.firstWhere((r) => r.id == rem.id);
      expect(updated.isCompleted, isTrue);
      expect(apiService.completeReminderCalls, 1);
    });

    test('search updates searchResults and clearSearch resets query', () async {
      apiService.mockSearchResult = CalendarSearchResult(
        events: [
          CalendarEvent(
            id: 'evt-s',
            title: 'Found Event',
            startTime: DateTime.utc(2026, 10, 9, 9, 0),
            endTime: DateTime.utc(2026, 10, 9, 10, 0),
          )
        ],
      );

      await provider.searchCalendar('Found');
      expect(provider.searchQuery, 'Found');
      expect(provider.searchResults?.events.length, 1);
      expect(provider.searchResults?.events.first.title, 'Found Event');

      provider.clearSearch();
      expect(provider.searchQuery, '');
      expect(provider.searchResults, isNull);
    });

    test('account switching invalidates old state and re-fetches for new account', () async {
      // Setup data for Account 149
      await provider.createEvent(
        title: 'Account 149 Meeting',
        startTime: DateTime.utc(2026, 10, 9, 10, 0),
        endTime: DateTime.utc(2026, 10, 9, 11, 0),
        categoryId: 'cat-mock',
      );
      expect(provider.events.isNotEmpty, isTrue);

      // Switch to Account 269
      final newAuth = FakeAuthProvider();
      newAuth.mockUser = const UserModel(
        id: 269,
        email: 'user269@bnxmail.com',
        fullName: 'Account 269',
      );

      // Account 269 has fresh empty events
      apiService.mockEvents = [
        CalendarEvent(
          id: 'evt-269',
          title: 'Account 269 Exclusive',
          startTime: DateTime.utc(2026, 10, 9, 15, 0),
          endTime: DateTime.utc(2026, 10, 9, 16, 0),
        )
      ];

      provider.updateAuth(newAuth);

      // Verify old events were invalidated and new account data loaded
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.events.any((e) => e.title == 'Account 149 Meeting'), isFalse);
      expect(provider.events.any((e) => e.title == 'Account 269 Exclusive'), isTrue);
    });

    test('unauthenticated updateAuth clears all calendar data', () async {
      await provider.createEvent(
        title: 'Private Event',
        startTime: DateTime.utc(2026, 10, 9, 10, 0),
        endTime: DateTime.utc(2026, 10, 9, 11, 0),
        categoryId: 'cat-mock',
      );
      expect(provider.events.isNotEmpty, isTrue);

      final unauth = FakeAuthProvider();
      unauth.mockIsAuthenticated = false;
      unauth.mockUser = null;

      provider.updateAuth(unauth);

      expect(provider.events, isEmpty);
      expect(provider.categories, isEmpty);
      expect(provider.selectedDateReminders, isEmpty);
      expect(provider.selectedDateNotes, isEmpty);
    });
  });
}
