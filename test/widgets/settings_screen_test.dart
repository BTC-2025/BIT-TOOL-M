import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/theme_provider.dart';
import 'package:bit_tools_backend/core/widgets/user_avatar.dart';
import 'package:bit_tools_backend/features/settings/settings_screen.dart';

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

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('renders guest state when unauthenticated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Manage your preferences and account'), findsOneWidget);

      // Verify Profile card in guest state
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Your personal information'), findsOneWidget);
      expect(find.text('Guest Account'), findsOneWidget);
      expect(
        find.text('Sign in to sync your tools & preferences'),
        findsOneWidget,
      );
      expect(find.text('Sign In'), findsOneWidget);

      // Dynamic info tiles for guest
      expect(find.text('ACCOUNT TYPE'), findsOneWidget);
      expect(find.text('GUEST'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('RECOVERY EMAIL'), findsOneWidget);
      expect(find.text('DATE OF BIRTH'), findsOneWidget);
      expect(find.text('Not set'), findsNWidgets(3));
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('0.00 GB / 15.00 GB'), findsOneWidget);
    });

    testWidgets('renders dynamic user details and avatar when authenticated', (
      WidgetTester tester,
    ) async {
      final fakeUser = UserModel(
        id: 42,
        email: 'alex.morgan@bnxmail.com',
        fullName: 'Alex Morgan',
        accountType: 'BUSINESS',
        phoneNumber: '+1 555-0199',
        recoveryEmail: 'alex.backup@bnxmail.com',
        dob: '1992-08-14',
        isPrimary: true,
        storageUsed: (3.5 * 1024 * 1024 * 1024).toInt(),
        storageLimit: (20 * 1024 * 1024 * 1024).toInt(),
        organization: const OrganizationModel(id: 1, name: 'Acme Corp'),
        profilePictureUrl: 'https://api.bnxmail.com/avatars/42.png',
      );

      final fakeAuth = FakeAuthProvider(user: fakeUser);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: fakeAuth,
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Settings'), findsOneWidget);

      // Verify Profile card authenticated header and badge
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(
        find.text('Active account and personal credentials'),
        findsOneWidget,
      );

      // Dynamic User Identity
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('alex.morgan@bnxmail.com'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // Dynamic info tiles
      expect(find.text('ACCOUNT TYPE'), findsOneWidget);
      expect(find.text('BUSINESS'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('+1 555-0199'), findsOneWidget);
      expect(find.text('RECOVERY EMAIL'), findsOneWidget);
      expect(find.text('alex.backup@bnxmail.com'), findsOneWidget);
      expect(find.text('DATE OF BIRTH'), findsOneWidget);
      expect(find.text('1992-08-14'), findsOneWidget);

      // Dynamic storage bar
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('3.50 GB / 20.00 GB'), findsOneWidget);
    });

    testWidgets(
      'renders Appearance card and toggles between Light and Dark mode',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SettingsScreen())),
        );
        await tester.pumpAndSettle();

        // Verify Appearance card content
        expect(find.text('Appearance'), findsOneWidget);
        expect(find.text('Customize your workspace'), findsOneWidget);
        expect(find.text('Light Mode'), findsOneWidget);
        expect(find.text('Dark Mode'), findsOneWidget);

        // Tap Dark Mode option
        await tester.tap(find.text('Dark Mode'));
        await tester.pumpAndSettle();

        // Tap Light Mode option
        await tester.tap(find.text('Light Mode'));
        await tester.pumpAndSettle();

        expect(find.text('Light Mode'), findsOneWidget);
      },
    );

    testWidgets('toggles dark mode via ThemeProvider', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, tp, _) => MaterialApp(
              themeMode: tp.themeMode,
              home: const Scaffold(body: SettingsScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, false);

      // Tap Dark Mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, true);

      // Tap Light Mode
      await tester.tap(find.text('Light Mode'));
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, false);
    });

    testWidgets(
      'renders About Bit Tool card with version 1.0.0 and description',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SettingsScreen())),
        );
        await tester.pumpAndSettle();

        // Verify About card content
        expect(find.text('About Bit Tool'), findsOneWidget);
        expect(find.text('Version 1.0.0'), findsOneWidget);
        expect(
          find.textContaining(
            'Bit Tool is a premium suite of productivity applications',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
