import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/calendar_models.dart';

void main() {
  group('CalendarCategory Model Tests', () {
    test('fromJson parses complete category record', () {
      final json = {
        'id': 'cat-123',
        'name': 'Work',
        'color': '#3B82F6',
        'createdAt': '2026-10-09T05:00:00.000Z',
        'updatedAt': '2026-10-09T05:30:00.000Z',
      };

      final cat = CalendarCategory.fromJson(json);

      expect(cat.id, 'cat-123');
      expect(cat.name, 'Work');
      expect(cat.color, '#3B82F6');
      expect(cat.createdAt, DateTime.parse('2026-10-09T05:00:00.000Z'));
      expect(cat.updatedAt, DateTime.parse('2026-10-09T05:30:00.000Z'));
    });

    test('fromJson provides safe defaults for null/missing fields', () {
      final cat =
          CalendarCategory.fromJson(const {'id': 'cat-minimal', 'name': 'Personal'});

      expect(cat.id, 'cat-minimal');
      expect(cat.name, 'Personal');
      expect(cat.color, '#3B82F6');
      expect(cat.createdAt, isNull);
      expect(cat.updatedAt, isNull);
    });

    test('toJson and copyWith work as expected', () {
      const original = CalendarCategory(
        id: 'cat-1',
        name: 'Urgent',
        color: '#EF4444',
      );

      final copy = original.copyWith(name: 'Critical');
      expect(copy.id, 'cat-1');
      expect(copy.name, 'Critical');
      expect(copy.color, '#EF4444');

      final json = original.toJson();
      expect(json['id'], 'cat-1');
      expect(json['name'], 'Urgent');
      expect(json['color'], '#EF4444');
    });
  });

  group('CalendarEvent Model Tests', () {
    test('fromJson parses event with nested category and ISO strings', () {
      final json = {
        'id': 'evt-1',
        'title': 'Q4 Strategy Review',
        'description': 'Review quarterly goals',
        'startTime': '2026-10-09T10:00:00.000Z',
        'endTime': '2026-10-09T11:30:00.000Z',
        'location': 'Conference Room A',
        'color': 'FF2563EB',
        'status': 'scheduled',
        'userEmail': 'test@bnxmail.com',
        'applicationName': 'Bit Tool',
        'category': {
          'id': 'cat-work',
          'name': 'Corporate Strategy',
          'color': '#2563EB',
        },
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.id, 'evt-1');
      expect(event.title, 'Q4 Strategy Review');
      expect(event.description, 'Review quarterly goals');
      expect(event.startTime, DateTime.parse('2026-10-09T10:00:00.000Z'));
      expect(event.endTime, DateTime.parse('2026-10-09T11:30:00.000Z'));
      expect(event.location, 'Conference Room A');
      expect(event.rawLocation, 'Conference Room A');
      expect(event.color, 'FF2563EB');
      expect(event.status, 'scheduled');
      expect(event.userEmail, 'test@bnxmail.com');
      expect(event.applicationName, 'Bit Tool');
      expect(event.category, 'Corporate Strategy');
      expect(event.categoryObj?.id, 'cat-work');
      expect(event.colorHex, 'FF2563EB');
      expect(event.isRecurring, isFalse);
    });

    test('backward compatibility getters work when optional fields are omitted', () {
      final json = {
        'id': 'evt-min',
        'title': 'Team Sync',
        'startTime': '2026-10-09T09:00:00.000Z',
        'endTime': '2026-10-09T09:30:00.000Z',
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.id, 'evt-min');
      expect(event.title, 'Team Sync');
      expect(event.description, '');
      expect(event.location, '');
      expect(event.rawLocation, isNull);
      expect(event.category, 'General');
      expect(event.categoryObj, isNull);
      expect(event.colorHex, 'FF2196F3');
    });

    test('toJson and copyWith preserve non-empty properties', () {
      final event = CalendarEvent(
        id: 'evt-test',
        title: 'Original Title',
        startTime: DateTime.utc(2026, 10, 9, 14, 0),
        endTime: DateTime.utc(2026, 10, 9, 15, 0),
        location: 'Virtual',
      );

      final updated = event.copyWith(title: 'Updated Title');
      expect(updated.id, 'evt-test');
      expect(updated.title, 'Updated Title');
      expect(updated.location, 'Virtual');

      final json = updated.toJson();
      expect(json['id'], 'evt-test');
      expect(json['title'], 'Updated Title');
      expect(json['location'], 'Virtual');
      expect(json['startTime'], '2026-10-09T14:00:00.000Z');
    });

    test('fromJson parses web app (Chrome) event format with separate date and time strings', () {
      final json = {
        '_id': 'web-evt-101',
        'title': 'WEB_SYNC_TEST_20261014',
        'description': 'Created from Chrome browser',
        'date': '2026-10-14',
        'startTime': '09:00',
        'endTime': '10:30',
        'category_id': 'cat-web',
        'application_name': 'Web',
        'user_email': 'user@bit-tool.com',
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.id, 'web-evt-101');
      expect(event.title, 'WEB_SYNC_TEST_20261014');
      expect(event.description, 'Created from Chrome browser');
      expect(event.date, '2026-10-14');
      expect(event.startTime.year, 2026);
      expect(event.startTime.month, 10);
      expect(event.startTime.day, 14);
      expect(event.startTime.hour, 9);
      expect(event.startTime.minute, 0);
      expect(event.endTime.year, 2026);
      expect(event.endTime.month, 10);
      expect(event.endTime.day, 14);
      expect(event.endTime.hour, 10);
      expect(event.endTime.minute, 30);
      expect(event.categoryId, 'cat-web');
      expect(event.applicationName, 'Web');
      expect(event.userEmail, 'user@bit-tool.com');

      // Verify matchesDay correctly matches October 14
      expect(event.matchesDay(2026, 10, 14), isTrue);
      expect(event.matchesDay(2026, 10, 9), isFalse);

      // Verify matchesApp correctly matches Bit Tool and All Apps filter
      expect(event.matchesApp('All Apps'), isTrue);
      expect(event.matchesApp('Bit Tool'), isTrue);
    });

    test('fromJson parses 12-hour AM/PM and seconds time strings from web inputs', () {
      final json = {
        'id': 'web-evt-102',
        'title': 'Afternoon Sync',
        'date': '2026-10-15',
        'startTime': '02:30 PM',
        'endTime': '03:45 PM',
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.startTime.year, 2026);
      expect(event.startTime.month, 10);
      expect(event.startTime.day, 15);
      expect(event.startTime.hour, 14);
      expect(event.startTime.minute, 30);
      expect(event.endTime.hour, 15);
      expect(event.endTime.minute, 45);
      expect(event.matchesDay(2026, 10, 15), isTrue);
    });
  });

  group('CalendarReminder Model Tests', () {
    test('fromJson parses reminder and calculates isCompleted', () {
      final jsonPending = {
        'id': 'rem-1',
        'title': 'Submit Report',
        'date': '2026-10-09',
        'time': '16:00',
        'description': 'Send PDF',
        'status': 'pending',
      };

      final remPending = CalendarReminder.fromJson(jsonPending);
      expect(remPending.id, 'rem-1');
      expect(remPending.title, 'Submit Report');
      expect(remPending.date, '2026-10-09');
      expect(remPending.time, '16:00');
      expect(remPending.description, 'Send PDF');
      expect(remPending.status, 'pending');
      expect(remPending.isCompleted, isFalse);

      final jsonCompleted = {
        'id': 'rem-2',
        'title': 'Done Task',
        'date': '2026-10-09',
        'status': 'completed',
      };
      final remCompleted = CalendarReminder.fromJson(jsonCompleted);
      expect(remCompleted.isCompleted, isTrue);
    });

    test('toJson and copyWith behave properly', () {
      const rem = CalendarReminder(
        id: 'rem-3',
        title: 'Pay Invoice',
        date: '2026-10-15',
        time: '12:00',
      );

      final completed = rem.copyWith(status: 'completed');
      expect(completed.isCompleted, isTrue);

      final json = rem.toJson();
      expect(json['id'], 'rem-3');
      expect(json['title'], 'Pay Invoice');
      expect(json['status'], 'pending');
    });
  });

  group('CalendarDateNote Model Tests', () {
    test('fromJson parses date-linked note', () {
      final json = {
        'id': 'dnote-1',
        'title': 'Daily Standup Notes',
        'date': '2026-10-09',
        'content': 'Discussed release blockers',
        'applicationName': 'Bit Tool',
        'userEmail': 'dev@bnxmail.com',
      };

      final note = CalendarDateNote.fromJson(json);

      expect(note.id, 'dnote-1');
      expect(note.title, 'Daily Standup Notes');
      expect(note.date, '2026-10-09');
      expect(note.content, 'Discussed release blockers');
      expect(note.applicationName, 'Bit Tool');
      expect(note.userEmail, 'dev@bnxmail.com');
    });

    test('toJson and copyWith update correctly', () {
      const note = CalendarDateNote(
        id: 'dnote-2',
        title: 'Review Plan',
        date: '2026-10-10',
        content: 'Check PRs',
      );

      final updated = note.copyWith(content: 'Checked all 5 PRs');
      expect(updated.content, 'Checked all 5 PRs');

      final json = updated.toJson();
      expect(json['title'], 'Review Plan');
      expect(json['content'], 'Checked all 5 PRs');
      expect(json['date'], '2026-10-10');
    });
  });

  group('CalendarSearchResult Model Tests', () {
    test('fromJson parses search result containing events, notes, and reminders', () {
      final json = {
        'events': [
          {
            'id': 'evt-1',
            'title': 'Planning',
            'startTime': '2026-10-09T10:00:00.000Z',
            'endTime': '2026-10-09T11:00:00.000Z',
          }
        ],
        'notes': [
          {
            'id': 'note-1',
            'title': 'Sprint Review',
            'date': '2026-10-09',
            'content': 'Notes content',
          }
        ],
        'reminders': [
          {
            'id': 'rem-1',
            'title': 'Call Partner',
            'date': '2026-10-09',
          }
        ],
      };

      final result = CalendarSearchResult.fromJson(json);

      expect(result.events.length, 1);
      expect(result.events.first.title, 'Planning');
      expect(result.notes.length, 1);
      expect(result.notes.first.title, 'Sprint Review');
      expect(result.reminders.length, 1);
      expect(result.reminders.first.title, 'Call Partner');
      expect(result.isEmpty, isFalse);
    });

    test('empty factory creates empty search result', () {
      const empty = CalendarSearchResult.empty();
      expect(empty.isEmpty, isTrue);
      expect(empty.events, isEmpty);
      expect(empty.notes, isEmpty);
      expect(empty.reminders, isEmpty);
    });
  });

  group('CalendarHoliday and HolidayHelper Tests', () {
    test('HolidayHelper dynamically computes leaves for October 2026 without hardcoding', () {
      final leaves = HolidayHelper.getLeavesForMonth(2026, 10);
      expect(leaves.length, 2);

      final columbus = leaves.firstWhere((h) => h.name == 'Columbus Day');
      expect(columbus.date.year, 2026);
      expect(columbus.date.month, 10);
      expect(columbus.date.day, 12); // 2nd Monday of October 2026 is October 12

      final halloween = leaves.firstWhere((h) => h.name == 'Halloween');
      expect(halloween.date.year, 2026);
      expect(halloween.date.month, 10);
      expect(halloween.date.day, 31);
    });

    test('HolidayHelper dynamically computes 2nd Monday for other years without hardcoded dates', () {
      final leaves2025 = HolidayHelper.getLeavesForMonth(2025, 10);
      final columbus2025 = leaves2025.firstWhere((h) => h.name == 'Columbus Day');
      expect(columbus2025.date.day, 13); // 2nd Monday of October 2025 is October 13

      final leaves2027 = HolidayHelper.getLeavesForMonth(2027, 10);
      final columbus2027 = leaves2027.firstWhere((h) => h.name == 'Columbus Day');
      expect(columbus2027.date.day, 11); // 2nd Monday of October 2027 is October 11
    });

    test('HolidayHelper dynamically calculates November Thanksgiving (4th Thursday)', () {
      final leavesNov2026 = HolidayHelper.getLeavesForMonth(2026, 11);
      final thanksgiving2026 =
          leavesNov2026.firstWhere((h) => h.name == 'Thanksgiving');
      expect(thanksgiving2026.date.day, 26); // 4th Thursday of November 2026 is Nov 26
    });

    test('CalendarHoliday equality and toString work correctly', () {
      final h1 = CalendarHoliday(name: 'Halloween', date: DateTime(2026, 10, 31));
      final h2 = CalendarHoliday(name: 'Halloween', date: DateTime(2026, 10, 31));
      expect(h1, equals(h2));
      expect(h1.toString(), contains('Halloween'));
    });
  });
}
