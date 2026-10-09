import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/models/note_model.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/notes_provider.dart';
import 'package:bit_tools_backend/core/services/note_api_service.dart';
import 'package:bit_tools_backend/features/notes/notes_screen.dart';

class MockTestNoteApiService implements NoteApiService {
  List<NoteModel> mockNotes = [];
  Exception? errorToThrow;
  int getCalls = 0;
  int createCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<NoteModel>> getNotes({bool allApps = true}) async {
    getCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockNotes);
  }

  @override
  Future<NoteModel> getNoteById(String id) async {
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
    final created = NoteModel(
      id: 'created-id-1',
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
    final idx = mockNotes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final updated = mockNotes[idx].copyWith(
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
    throw const NotFoundException();
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
    mockNotes.removeWhere((n) => n.id == id);
    return true;
  }
}

class FakeAuthProvider extends AuthProvider {
  @override
  bool get isAuthenticated => true;

  @override
  UserModel? get user => const UserModel(
        id: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
      );
}

Widget _buildTestWidget({
  required NotesProvider notesProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? FakeAuthProvider(),
      ),
      ChangeNotifierProvider<NotesProvider>.value(
        value: notesProvider,
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: NotesScreen(),
      ),
    ),
  );
}

void main() {
  group('NotesScreen Widget Tests', () {
    late MockTestNoteApiService fakeService;
    late FakeAuthProvider fakeAuth;

    setUp(() {
      fakeService = MockTestNoteApiService();
      fakeAuth = FakeAuthProvider();
    });

    testWidgets('displays empty state message when no notes exist', (
      WidgetTester tester,
    ) async {
      fakeService.mockNotes = [];
      final provider = NotesProvider(null, fakeService, fakeAuth);

      await tester.pumpWidget(_buildTestWidget(notesProvider: provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('No notes in All Apps'), findsOneWidget);
    });

    testWidgets('renders real note cards returned from backend', (
      WidgetTester tester,
    ) async {
      fakeService.mockNotes = [
        const NoteModel(
          id: 'note-1',
          title: 'Quarterly Planning',
          content: 'Discuss OKRs and resource allocation',
          applicationName: 'Bit Tool',
          isPinned: true,
        ),
        const NoteModel(
          id: 'note-2',
          title: 'Shopping List',
          content: 'Apples, oranges, oat milk',
          applicationName: 'Cliks',
          isPinned: false,
        ),
      ];

      final provider = NotesProvider(null, fakeService, fakeAuth);

      await tester.pumpWidget(_buildTestWidget(notesProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Quarterly Planning'), findsOneWidget);
      expect(find.text('Discuss OKRs and resource allocation'), findsOneWidget);
      expect(find.text('Shopping List'), findsOneWidget);
      expect(find.text('Apples, oranges, oat milk'), findsOneWidget);
      expect(find.text('No notes found'), findsNothing);
    });

    testWidgets('displays error view with retry button on API failure', (
      WidgetTester tester,
    ) async {
      fakeService.errorToThrow = const ServerException('Backend offline', 500);
      final provider = NotesProvider(null, fakeService, fakeAuth);

      await tester.pumpWidget(_buildTestWidget(notesProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Backend offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping delete button opens confirmation dialog and can cancel', (
      WidgetTester tester,
    ) async {
      fakeService.mockNotes = [
        const NoteModel(
          id: 'del-me',
          title: 'Disposable Note',
          content: 'Should be removed',
          applicationName: 'Bit Tool',
        ),
      ];

      final provider = NotesProvider(null, fakeService, fakeAuth);

      await tester.pumpWidget(_buildTestWidget(notesProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Disposable Note'), findsOneWidget);

      // Find and tap the delete icon button
      final deleteBtn = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteBtn, findsWidgets);
      await tester.tap(deleteBtn.first);
      await tester.pumpAndSettle();

      // Verify Delete Confirmation Dialog is open
      expect(find.text('Delete Note'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to delete "Disposable Note"?'),
        findsOneWidget,
      );

      // Tap Cancel in AlertDialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      // Note still exists
      expect(find.text('Disposable Note'), findsOneWidget);
      expect(fakeService.deleteCalls, 0);
    });
  });
}
