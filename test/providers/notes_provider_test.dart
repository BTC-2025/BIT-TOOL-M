import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/providers/session_provider.dart';
import 'package:bit_tools_backend/core/providers/app_providers.dart';

void main() {
  group('NotesProvider', () {
    late SessionProvider sessionProvider;
    late NotesProvider notesProvider;

    setUp(() {
      sessionProvider = SessionProvider();
      notesProvider = NotesProvider(sessionProvider);
    });

    test('initializes with seed notes', () {
      expect(notesProvider.notes, isNotEmpty);
      expect(notesProvider.notes.length, equals(4));
    });

    test('addNote inserts a new note at beginning', () {
      final initialCount = notesProvider.notes.length;
      notesProvider.addNote(
        title: 'New Idea',
        content: 'Clean architecture implementation',
        category: 'Ideas',
        colorHex: '#10B981',
        isPinned: true,
      );

      expect(notesProvider.notes.length, equals(initialCount + 1));
      expect(notesProvider.notes.first.title, equals('New Idea'));
      expect(notesProvider.notes.first.isPinned, isTrue);
    });

    test('updateNote modifies existing note details', () {
      final firstNoteId = notesProvider.notes.first.id;
      notesProvider.updateNote(
        firstNoteId,
        title: 'Updated Title',
        content: 'Updated Content',
      );

      final updated = notesProvider.notes.firstWhere(
        (n) => n.id == firstNoteId,
      );
      expect(updated.title, equals('Updated Title'));
      expect(updated.content, equals('Updated Content'));
    });

    test('togglePin toggles the pinned status', () {
      final firstNote = notesProvider.notes.first;
      final prevPinned = firstNote.isPinned;

      notesProvider.togglePin(firstNote.id);
      expect(firstNote.isPinned, equals(!prevPinned));
    });

    test('deleteNote removes note from list', () {
      final initialCount = notesProvider.notes.length;
      final idToDelete = notesProvider.notes.first.id;

      notesProvider.deleteNote(idToDelete);
      expect(notesProvider.notes.length, equals(initialCount - 1));
      expect(notesProvider.notes.any((n) => n.id == idToDelete), isFalse);
    });
  });
}
