import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/models/note_model.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/notes_provider.dart';
import 'package:bit_tools_backend/core/services/note_api_service.dart';

class FakeNoteApiService implements NoteApiService {
  List<NoteModel> mockNotes = [];
  Exception? errorToThrow;
  int getCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int getByIdCalls = 0;
  bool? lastAllApps;

  @override
  Future<List<NoteModel>> getNotes({bool allApps = true}) async {
    getCalls++;
    lastAllApps = allApps;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockNotes);
  }

  @override
  Future<NoteModel> getNoteById(String id) async {
    getByIdCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return mockNotes.firstWhere((n) => n.id == id);
  }

  @override
  Future<NoteModel> createNote({
    required String title,
    required String content,
    String? color,
    bool isPinned = false,
    String? applicationName,
  }) async {
    createCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final created = NoteModel(
      id: 'mock-created-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      color: color ?? '#A7F3D0',
      isPinned: isPinned,
      applicationName: applicationName ?? 'Bit Tool',
    );
    mockNotes.add(created);
    return created;
  }

  @override
  Future<NoteModel> updateNote(
    String id, {
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    bool? isArchived,
    String? applicationName,
  }) async {
    updateCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final idx = mockNotes.indexWhere((n) => n.id == id);
    if (idx == -1) throw const NotFoundException('Note not found');
    final existing = mockNotes[idx];
    final updated = existing.copyWith(
      title: title,
      content: content,
      color: color,
      isPinned: isPinned,
      isArchived: isArchived,
      applicationName: applicationName,
    );
    mockNotes[idx] = updated;
    return updated;
  }

  @override
  Future<NoteModel> togglePin(String id, bool isPinned) async {
    return updateNote(id, isPinned: isPinned);
  }

  @override
  Future<NoteModel> toggleArchive(String id, bool isArchived) async {
    return updateNote(id, isArchived: isArchived);
  }

  @override
  Future<bool> deleteNote(String id) async {
    deleteCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockNotes.removeWhere((n) => n.id == id);
    return true;
  }
}

class FakeAuthProvider extends AuthProvider {
  bool _mockAuth = true;
  UserModel? _mockUser = const UserModel(
    id: 1,
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: 'ADMIN',
  );

  @override
  bool get isAuthenticated => _mockAuth;

  @override
  UserModel? get user => _mockUser;

  void setAuthenticated(bool authenticated, [UserModel? user]) {
    _mockAuth = authenticated;
    _mockUser = user;
    notifyListeners();
  }
}

void main() {
  group('NotesProvider Tests', () {
    late FakeNoteApiService fakeService;
    late FakeAuthProvider fakeAuth;
    late NotesProvider provider;

    setUp(() {
      fakeService = FakeNoteApiService();
      fakeAuth = FakeAuthProvider();
      provider = NotesProvider(null, fakeService, fakeAuth);
    });

    test('initial state contains no hardcoded notes when unauthenticated', () {
      final unauthProvider = NotesProvider(null, fakeService);
      expect(unauthProvider.status, NotesStatus.initial);
      expect(unauthProvider.notes, isEmpty);
      expect(unauthProvider.filteredNotes, isEmpty);
      expect(unauthProvider.hasError, isFalse);
      expect(unauthProvider.errorMessage, isNull);
    });

    test('fetchNotes loads real records and sets status to loaded', () async {
      fakeService.mockNotes = [
        const NoteModel(
          id: 'note-1',
          title: 'Backend Note',
          content: 'Verified body',
          applicationName: 'Bit Tool',
          isPinned: false,
        ),
      ];

      await provider.fetchNotes(allApps: true);

      expect(provider.status, NotesStatus.loaded);
      expect(provider.notes.length, 1);
      expect(provider.notes.first.id, 'note-1');
      expect(provider.notes.first.title, 'Backend Note');
      expect(provider.hasError, isFalse);
    });

    test('fetchNotes with empty collection sets status to loaded without mock notes', () async {
      fakeService.mockNotes = [];

      await provider.fetchNotes(allApps: true);

      expect(provider.status, NotesStatus.loaded);
      expect(provider.notes, isEmpty);
      expect(provider.hasError, isFalse);
    });

    test('fetchNotes sets error state on API failure', () async {
      fakeService.errorToThrow = const ServerException('Server offline', 500);

      await provider.fetchNotes(allApps: true);

      expect(provider.status, NotesStatus.error);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('Server offline'));
      expect(provider.notes, isEmpty);
    });

    test('filteredNotes filters by search query across title and content', () async {
      fakeService.mockNotes = [
        const NoteModel(
          id: '1',
          title: 'Grocery List',
          content: 'Milk, bread, eggs',
          applicationName: 'Bit Tool',
        ),
        const NoteModel(
          id: '2',
          title: 'Flutter Architecture',
          content: 'Implement clean separation of providers and services',
          applicationName: 'Bit Tool',
        ),
      ];

      await provider.fetchNotes(allApps: true);

      provider.setSearchQuery('eggs');
      expect(provider.filteredNotes.length, 1);
      expect(provider.filteredNotes.first.id, '1');

      provider.setSearchQuery('architecture');
      expect(provider.filteredNotes.length, 1);
      expect(provider.filteredNotes.first.id, '2');

      provider.setSearchQuery('non-existent');
      expect(provider.filteredNotes, isEmpty);

      provider.setSearchQuery('');
      expect(provider.filteredNotes.length, 2);
    });

    test('filteredNotes respects applicationName and Archived filters', () async {
      fakeService.mockNotes = [
        const NoteModel(
          id: '1',
          title: 'Bit Tool Note',
          applicationName: 'Bit Tool',
          isArchived: false,
        ),
        const NoteModel(
          id: '2',
          title: 'Cliks Note',
          applicationName: 'Cliks',
          isArchived: false,
        ),
        const NoteModel(
          id: '3',
          title: 'Archived Note',
          applicationName: 'Bit Tool',
          isArchived: true,
        ),
      ];

      await provider.fetchNotes(allApps: true);

      // 'All Apps' tab shows non-archived notes from all apps
      provider.setSelectedFilter('All Apps');
      expect(provider.filteredNotes.length, 2);
      expect(provider.filteredNotes.map((n) => n.id), containsAll(['1', '2']));

      // 'Bit Tool' tab shows only Bit Tool non-archived notes
      provider.setSelectedFilter('Bit Tool');
      expect(provider.filteredNotes.length, 1);
      expect(provider.filteredNotes.first.id, '1');

      // 'Cliks' tab shows only Cliks non-archived notes
      provider.setSelectedFilter('Cliks');
      expect(provider.filteredNotes.length, 1);
      expect(provider.filteredNotes.first.id, '2');

      // 'Archived' tab shows only archived notes
      provider.setSelectedFilter('Archived');
      expect(provider.filteredNotes.length, 1);
      expect(provider.filteredNotes.first.id, '3');
    });

    test('pinned notes are sorted first in notes collection', () async {
      fakeService.mockNotes = [
        NoteModel(
          id: '1',
          title: 'Unpinned New',
          isPinned: false,
          createdAt: DateTime(2026, 10, 9, 12, 0),
        ),
        NoteModel(
          id: '2',
          title: 'Pinned Old',
          isPinned: true,
          createdAt: DateTime(2026, 10, 8, 12, 0),
        ),
      ];

      await provider.fetchNotes(allApps: true);

      expect(provider.notes.first.id, '2');
      expect(provider.notes.last.id, '1');
    });

    test('createNote persists note to backend and updates list', () async {
      await provider.fetchNotes(allApps: true);
      expect(provider.notes, isEmpty);

      final created = await provider.createNote(
        title: 'New Idea',
        content: 'Clean architecture',
        color: '#10B981',
        isPinned: true,
        applicationName: 'Bit Tool',
      );

      expect(fakeService.createCalls, 1);
      expect(provider.notes.length, 1);
      expect(provider.notes.first.title, 'New Idea');
      expect(provider.notes.first.isPinned, isTrue);
      expect(created.title, 'New Idea');
    });

    test('updateNote modifies note in collection', () async {
      fakeService.mockNotes = [
        const NoteModel(
          id: 'n1',
          title: 'Old Title',
          content: 'Old Content',
        ),
      ];

      await provider.fetchNotes(allApps: true);

      await provider.updateNote('n1', title: 'Updated Title');

      expect(fakeService.updateCalls, 1);
      expect(provider.notes.first.title, 'Updated Title');
      expect(provider.notes.first.content, 'Old Content');
    });

    test('togglePin toggles pin state and re-sorts pinned note first', () async {
      fakeService.mockNotes = [
        const NoteModel(id: '1', title: 'Note 1', isPinned: false),
        const NoteModel(id: '2', title: 'Note 2', isPinned: false),
      ];

      await provider.fetchNotes(allApps: true);

      await provider.togglePin('2');

      expect(provider.notes.first.id, '2');
      expect(provider.notes.first.isPinned, isTrue);
    });

    test('toggleArchive toggles archive state', () async {
      fakeService.mockNotes = [
        const NoteModel(id: '1', title: 'Note 1', isArchived: false),
      ];

      await provider.fetchNotes(allApps: true);

      await provider.toggleArchive('1');

      expect(provider.notes.first.isArchived, isTrue);
    });

    test('deleteNote removes note from provider collection', () async {
      fakeService.mockNotes = [
        const NoteModel(id: 'del-1', title: 'To Delete'),
      ];

      await provider.fetchNotes(allApps: true);
      expect(provider.notes.length, 1);

      await provider.deleteNote('del-1');

      expect(fakeService.deleteCalls, 1);
      expect(provider.notes, isEmpty);
    });

    test('account switching clears previous notes and triggers fresh load for new account', () async {
      fakeService.mockNotes = [
        const NoteModel(id: 'acc1-note', title: 'Account 1 Note'),
      ];

      await provider.fetchNotes(allApps: true);
      expect(provider.notes.length, 1);
      expect(provider.notes.first.id, 'acc1-note');

      // Switch to account 2
      fakeService.mockNotes = [
        const NoteModel(id: 'acc2-note', title: 'Account 2 Note'),
      ];

      fakeAuth.setAuthenticated(
        true,
        const UserModel(id: 2, email: 'acc2@example.com'),
      );
      provider.updateAuth(fakeAuth);

      // Previous account's notes are immediately cleared
      expect(provider.notes.any((n) => n.id == 'acc1-note'), isFalse);

      // Allow async fetch to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.notes.length, 1);
      expect(provider.notes.first.id, 'acc2-note');
    });

    test('logout invalidates notes state and clears all displayed records', () async {
      fakeService.mockNotes = [
        const NoteModel(id: 'secret-note', title: 'Private User Note'),
      ];

      await provider.fetchNotes(allApps: true);
      expect(provider.notes.length, 1);

      fakeAuth.setAuthenticated(false, null);
      provider.updateAuth(fakeAuth);

      expect(provider.notes, isEmpty);
      expect(provider.filteredNotes, isEmpty);
      expect(provider.status, NotesStatus.initial);
    });
  });
}
