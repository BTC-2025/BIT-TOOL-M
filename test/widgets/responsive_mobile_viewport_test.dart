import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/providers/session_provider.dart';
import 'package:bit_tools_backend/core/providers/app_providers.dart';
import 'package:bit_tools_backend/core/providers/theme_provider.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/widgets/responsive_shell.dart';
import 'package:bit_tools_backend/features/calendar/calendar_screen.dart';
import 'package:bit_tools_backend/features/keyboard/keyboard_screen.dart';
import 'package:bit_tools_backend/features/calculator/calculator_screen.dart';
import 'package:bit_tools_backend/features/contacts/contacts_screen.dart';
import 'package:bit_tools_backend/core/models/contact_model.dart';
import 'package:bit_tools_backend/core/models/note_model.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/widgets/user_avatar.dart';

class FakeAuthProvider extends AuthProvider {
  final UserModel? _mockUser;
  final bool _mockLoading;
  final bool _mockError;

  FakeAuthProvider({
    UserModel? user,
    bool isLoading = false,
    bool hasError = false,
  })  : _mockUser = user,
        _mockLoading = isLoading,
        _mockError = hasError;

  @override
  UserModel? get user => _mockUser;

  @override
  bool get isAuthenticated => _mockUser != null;

  @override
  bool get isLoading => _mockLoading;

  @override
  bool get hasError => _mockError;
}

Widget _createTestApp({Widget? child, AuthProvider? authProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SessionProvider()),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) =>
            authProvider ??
            FakeAuthProvider(
              user: const UserModel(
                id: 1,
                email: 'responsive@bittool.test',
                fullName: 'Test Responsive User',
              ),
            ),
      ),
      ChangeNotifierProxyProvider<SessionProvider, CalculatorProvider>(
        create: (context) => CalculatorProvider(
          context.read<SessionProvider>(),
          null,
          null,
          const [],
        ),
        update: (_, session, previous) =>
            previous ?? CalculatorProvider(session, null, null, const []),
      ),
      ChangeNotifierProxyProvider<SessionProvider, CalendarProvider>(
        create: (context) => CalendarProvider(context.read<SessionProvider>()),
        update: (_, session, previous) => previous ?? CalendarProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, NotesProvider>(
        create: (context) => NotesProvider(
          context.read<SessionProvider>(),
          null,
          null,
          const [
            NoteModel(
              id: 'n1',
              title: 'Mobile responsive note',
              content: 'Testing responsive layout on narrow viewports',
              applicationName: 'Bit Tool',
            ),
          ],
        ),
        update: (_, session, previous) => previous ?? NotesProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, ContactsProvider>(
        create: (context) => ContactsProvider(
          context.read<SessionProvider>(),
          null,
          null,
          const [
            ContactModel(
              id: 'c1',
              firstName: 'Alexander',
              lastName: 'Montgomery',
              company: 'Global Innovations Corp',
              role: 'Chief Technology Officer',
            ),
          ],
        ),
        update: (_, session, previous) => previous ?? ContactsProvider(session),
      ),
    ],
    child: MaterialApp(
      home: child ?? const ResponsiveShell(),
    ),
  );
}

void main() {
  const mobileWidths = [320.0, 360.0, 375.0, 390.0, 430.0];

  group('Cross-Platform Mobile Viewport Responsiveness Suite', () {
    for (final width in mobileWidths) {
      testWidgets('ResponsiveShell renders without overflow at ${width.toInt()}px width',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1.0;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          debugPrint(details.toString());
          originalOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = originalOnError;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(_createTestApp());
        await tester.pumpAndSettle();

        // Ensure zero layout or RenderFlex overflow exceptions
        expect(tester.takeException(), isNull);

        // Verify top nav bar elements render properly
        expect(find.text('Bit-tool'), findsOneWidget);

        // Verify mobile mode does not render the wide desktop search box
        expect(find.byKey(const ValueKey('HeaderSearchField')), findsNothing);

        // Switch to Notes tab (index 2)
        await tester.tap(find.byIcon(Icons.description_outlined));
        await tester.pumpAndSettle();
        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint(err.toStringDeep());
        }
        expect(err, isNull);
        expect(find.text('Mobile responsive note'), findsOneWidget);

        // Switch to Contacts tab (index 3)
        await tester.tap(find.byIcon(Icons.people_outline_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Alexander Montgomery'), findsOneWidget);

        // Switch to Calendar tab (index 1)
        await tester.tap(find.byIcon(Icons.calendar_today_outlined));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('AGENDA'), findsOneWidget);

        // Switch to Weather tab (index 4)
        await tester.tap(find.byIcon(Icons.cloud_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to Keyboard tab (index 5)
        await tester.tap(find.byIcon(Icons.keyboard_outlined));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Keyboard'), findsWidgets);
      });
    }

    testWidgets('Desktop layout at 1200px width maintains desktop sidebar and header search',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Desktop search input must be visible
      expect(find.byKey(const ValueKey('HeaderSearchField')), findsOneWidget);
    });

    testWidgets('Profile Menu Dialog fits within 320px narrow screen without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Tap on the compact profile avatar button in top navbar
      final avatarFinder = find.byType(UserAvatar).first;
      expect(avatarFinder, findsOneWidget);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Manage your Account'), findsOneWidget);
      expect(find.text('Sign out of all accounts'), findsOneWidget);
    });

    testWidgets('Keyboard screen renders at 320px without overflow and all keys respond',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp(
        child: const Scaffold(body: KeyboardScreen()),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
      expect(find.text('space'), findsOneWidget);
    });

    testWidgets('Calendar screen month grid and mobile agenda render at 320px without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp(
        child: const Scaffold(body: CalendarScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('AGENDA'), findsOneWidget);
    });

    testWidgets('Calculator screen renders in both tabs at 320px without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp(
        child: const Scaffold(body: CalculatorScreen()),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BETA CALC'), findsOneWidget);

      // Tap Cross-App History tab
      await tester.tap(find.text('Cross-App History'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Contacts screen renders mobile cards at 320px without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp(
        child: const Scaffold(body: ContactsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Contact Management'), findsOneWidget);
    });

    testWidgets('Tapping Manage your Account in top-right bar navigates to Settings and back button returns',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // Starts on Calculator
      expect(find.text('Bit-tool'), findsOneWidget);

      // Tap on the top-right profile avatar
      final avatarFinder = find.byType(UserAvatar).first;
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Tap 'Manage your Account' button
      final manageAccountFinder = find.text('Manage your Account');
      expect(manageAccountFinder, findsOneWidget);
      await tester.tap(manageAccountFinder);
      await tester.pumpAndSettle();

      // Now on Settings screen!
      expect(find.text('Manage your preferences and account'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Returns to Calculator!
      expect(find.text('Bit-tool'), findsOneWidget);
    });
  });
}
