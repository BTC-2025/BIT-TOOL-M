import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/note_model.dart';

void main() {
  group('NoteModel Tests', () {
    test('fromJson parses full backend schema correctly', () {
      final json = {
        'id': '6fa85f64-5717-4562-b3fc-2c963f66afa6',
        'userEmail': 'ravinew2004@bnxmail.com',
        'applicationName': 'Bit Tool',
        'title': 'Production Note',
        'content': 'Test content body',
        'isPinned': true,
        'color': '#A7F3D0',
        'isArchived': false,
        'createdAt': '2026-10-09T06:40:00.000Z',
        'updatedAt': '2026-10-09T06:45:00.000Z',
        'items': ['task 1', 'task 2'],
        'tags': ['work', 'urgent'],
      };

      final note = NoteModel.fromJson(json);

      expect(note.id, '6fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(note.userEmail, 'ravinew2004@bnxmail.com');
      expect(note.applicationName, 'Bit Tool');
      expect(note.category, 'Bit Tool');
      expect(note.title, 'Production Note');
      expect(note.content, 'Test content body');
      expect(note.isPinned, isTrue);
      expect(note.color, '#A7F3D0');
      expect(note.colorHex, '#A7F3D0');
      expect(note.isArchived, isFalse);
      expect(note.createdAt, DateTime.parse('2026-10-09T06:40:00.000Z'));
      expect(note.updatedAt, DateTime.parse('2026-10-09T06:45:00.000Z'));
      expect(note.items, ['task 1', 'task 2']);
      expect(note.tags, ['work', 'urgent']);
    });

    test('fromJson safely handles missing and null fields', () {
      final json = <String, dynamic>{
        'id': 'note-1',
      };

      final note = NoteModel.fromJson(json);

      expect(note.id, 'note-1');
      expect(note.userEmail, isNull);
      expect(note.applicationName, 'Bit Tool');
      expect(note.title, '');
      expect(note.content, '');
      expect(note.isPinned, isFalse);
      expect(note.color, '#A7F3D0');
      expect(note.isArchived, isFalse);
      expect(note.createdAt, isNull);
      expect(note.updatedAt, isNull);
      expect(note.items, isEmpty);
      expect(note.tags, isEmpty);
    });

    test('fromJson handles alternative appName and category keys', () {
      final jsonWithAppName = {
        'id': '1',
        'appName': 'BNX Mail',
      };
      expect(NoteModel.fromJson(jsonWithAppName).applicationName, 'BNX Mail');

      final jsonWithCategory = {
        'id': '2',
        'category': 'Cliks Business',
      };
      expect(NoteModel.fromJson(jsonWithCategory).applicationName, 'Cliks Business');
    });

    test('displayTitle returns trimmed title or Untitled Note fallback', () {
      const emptyNote = NoteModel(id: '1', title: '');
      expect(emptyNote.displayTitle, 'Untitled Note');

      const whitespaceNote = NoteModel(id: '2', title: '   ');
      expect(whitespaceNote.displayTitle, 'Untitled Note');

      const titledNote = NoteModel(id: '3', title: '  My Important Note  ');
      expect(titledNote.displayTitle, 'My Important Note');
    });

    test('toJson produces complete serialization map', () {
      final note = NoteModel(
        id: 'note-123',
        userEmail: 'user@example.com',
        applicationName: 'Cliks',
        title: 'Meeting Notes',
        content: 'Action items listed here',
        isPinned: true,
        color: '#FDE047',
        isArchived: false,
        createdAt: DateTime.parse('2026-10-09T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-10-09T01:00:00.000Z'),
        items: const ['item1'],
        tags: const ['tag1'],
      );

      final json = note.toJson();

      expect(json['id'], 'note-123');
      expect(json['userEmail'], 'user@example.com');
      expect(json['applicationName'], 'Cliks');
      expect(json['title'], 'Meeting Notes');
      expect(json['content'], 'Action items listed here');
      expect(json['isPinned'], isTrue);
      expect(json['color'], '#FDE047');
      expect(json['isArchived'], isFalse);
      expect(json['createdAt'], '2026-10-09T00:00:00.000Z');
      expect(json['updatedAt'], '2026-10-09T01:00:00.000Z');
      expect(json['items'], ['item1']);
      expect(json['tags'], ['tag1']);
    });

    test('toCreateJson produces documented create body payload', () {
      final body = NoteModel.toCreateJson(
        title: 'New Note',
        content: 'New content body',
        color: '#BAE6FD',
        isPinned: true,
        applicationName: 'Bit Tool',
      );

      expect(body, {
        'title': 'New Note',
        'content': 'New content body',
        'color': '#BAE6FD',
        'isPinned': true,
        'applicationName': 'Bit Tool',
      });
    });

    test('toCreateJson omits applicationName when null', () {
      final body = NoteModel.toCreateJson(
        title: 'New Note',
        content: 'New content body',
      );

      expect(body.containsKey('applicationName'), isFalse);
      expect(body['title'], 'New Note');
      expect(body['content'], 'New content body');
      expect(body['color'], '#A7F3D0');
      expect(body['isPinned'], isFalse);
    });

    test('toUpdateJson produces partial update payload with only non-null values', () {
      final partialUpdate = NoteModel.toUpdateJson(
        title: 'Only Title Updated',
      );

      expect(partialUpdate, {'title': 'Only Title Updated'});
      expect(partialUpdate.containsKey('content'), isFalse);
      expect(partialUpdate.containsKey('color'), isFalse);
      expect(partialUpdate.containsKey('isPinned'), isFalse);
      expect(partialUpdate.containsKey('isArchived'), isFalse);

      final pinUpdate = NoteModel.toUpdateJson(
        isPinned: true,
      );
      expect(pinUpdate, {'isPinned': true});

      final archiveUpdate = NoteModel.toUpdateJson(
        isArchived: true,
      );
      expect(archiveUpdate, {'isArchived': true});
    });

    test('copyWith updates only provided attributes', () {
      const original = NoteModel(
        id: '1',
        title: 'Original Title',
        content: 'Original Content',
        isPinned: false,
        color: '#A7F3D0',
        applicationName: 'Bit Tool',
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isPinned: true,
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated Title');
      expect(updated.content, 'Original Content');
      expect(updated.isPinned, isTrue);
      expect(updated.color, '#A7F3D0');
      expect(updated.applicationName, 'Bit Tool');
    });

    test('equality and hashCode compare note identity accurately', () {
      const note1 = NoteModel(
        id: '1',
        title: 'Title',
        content: 'Content',
        applicationName: 'Bit Tool',
      );

      const note2 = NoteModel(
        id: '1',
        title: 'Title',
        content: 'Content',
        applicationName: 'Bit Tool',
      );

      const note3 = NoteModel(
        id: '2',
        title: 'Different Title',
        content: 'Content',
        applicationName: 'Bit Tool',
      );

      expect(note1, equals(note2));
      expect(note1.hashCode, equals(note2.hashCode));
      expect(note1, isNot(equals(note3)));
    });
  });
}
