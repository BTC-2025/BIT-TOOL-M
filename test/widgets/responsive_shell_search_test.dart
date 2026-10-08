import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/providers/session_provider.dart';
import 'package:bit_tools_backend/core/providers/app_providers.dart';
import 'package:bit_tools_backend/core/providers/theme_provider.dart';
import 'package:bit_tools_backend/core/widgets/responsive_shell.dart';
import 'package:bit_tools_backend/features/notes/notes_screen.dart';
import 'package:bit_tools_backend/features/contacts/contacts_screen.dart';

Widget _createTestWidget() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SessionProvider()),
      ChangeNotifierProxyProvider<SessionProvider, CalculatorProvider>(
        create: (context) =>
            CalculatorProvider(context.read<SessionProvider>()),
        update: (_, session, previous) =>
            previous ?? CalculatorProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, CalendarProvider>(
        create: (context) =>
            CalendarProvider(context.read<SessionProvider>()),
        update: (_, session, previous) =>
            previous ?? CalendarProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, NotesProvider>(
        create: (context) => NotesProvider(context.read<SessionProvider>()),
        update: (_, session, previous) => previous ?? NotesProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, ContactsProvider>(
        create: (context) =>
            ContactsProvider(context.read<SessionProvider>()),
        update: (_, session, previous) =>
            previous ?? ContactsProvider(session),
      ),
    ],
    child: const MaterialApp(
      home: ResponsiveShell(),
    ),
  );
}

void main() {
  group('Header Search Tests', () {
    testWidgets('renders search field in header on desktop view', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // Verify search input field exists
      final searchField = find.byKey(const ValueKey('HeaderSearchField'));
      expect(searchField, findsOneWidget);
      expect(find.text('Search tools, contacts...'), findsOneWidget);
    });

    testWidgets('typing query in search field displays matching results overlay', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byKey(const ValueKey('HeaderSearchField'));
      await tester.tap(searchField);
      await tester.enterText(searchField, 'Notes');
      await tester.pumpAndSettle();

      // Results overlay should show matching tools and category
      expect(find.text('TOOLS'), findsOneWidget);
      expect(find.text('Personal notes, scratchpad & markdown docs'), findsOneWidget);

      // Tap on the result to navigate to Notes
      await tester.tap(find.text('Personal notes, scratchpad & markdown docs'));
      await tester.pumpAndSettle();

      // Screen should now display NotesScreen
      expect(find.byType(NotesScreen), findsOneWidget);
    });

    testWidgets('searching for contacts displays matching contacts and navigates', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // Enter search query for seeded contact
      final searchField = find.byKey(const ValueKey('HeaderSearchField'));
      await tester.tap(searchField);
      await tester.enterText(searchField, 'virat');
      await tester.pumpAndSettle();

      expect(find.text('CONTACTS'), findsOneWidget);
      expect(find.text('virat kholi'), findsOneWidget);

      // Tap the contact
      await tester.tap(find.text('virat kholi'));
      await tester.pumpAndSettle();

      // Switched to Contacts screen
      expect(find.byType(ContactsScreen), findsOneWidget);
    });
  });
}
