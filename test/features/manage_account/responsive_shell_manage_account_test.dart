import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as p;
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/models/user_model.dart' as bit;
import 'package:bit_tools_backend/core/providers/app_providers.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/session_provider.dart';
import 'package:bit_tools_backend/core/providers/theme_provider.dart';
import 'package:bit_tools_backend/core/widgets/responsive_shell.dart';
import 'package:bit_tools_backend/features/manage_account/core/network/token_service.dart';
import 'package:bit_tools_backend/features/manage_account/presentation/manage_account_screen.dart';

class MockTestAuthStorage implements AuthStorage {
  String? _token = 'mock_sso_token';
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<bool> hasToken() async => _token != null;
  @override
  Future<void> removeToken() async => _token = null;
  @override
  Future<void> saveToken(String token) async => _token = token;
}

class TestAuthProvider extends AuthProvider {
  final bit.UserModel? _testUser;
  final AuthStorage _storage;

  TestAuthProvider({required bit.UserModel user, required AuthStorage storage})
      : _testUser = user,
        _storage = storage;

  @override
  bit.UserModel? get user => _testUser;

  @override
  bool get isAuthenticated => _testUser != null;

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  AuthStorage get authStorage => _storage;
}

void main() {
  setUp(() async {
    TokenService.cachedAccessToken = 'mock_token';
  });

  tearDown(() {
    TokenService.cachedAccessToken = null;
  });

  testWidgets('Tapping Manage your Account opens ManageAccountScreen', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;

      final mockStorage = MockTestAuthStorage();
      final authProvider = TestAuthProvider(
        storage: mockStorage,
        user: const bit.UserModel(
          id: 1,
          email: 'ravinew2004@bnxmail.com',
          fullName: 'Ravi Kumar C',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: p.MultiProvider(
            providers: [
              p.ChangeNotifierProvider(create: (_) => ThemeProvider()),
              p.ChangeNotifierProvider(create: (_) => SessionProvider()),
              p.ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              p.ChangeNotifierProxyProvider<SessionProvider, CalculatorProvider>(
                create: (ctx) => CalculatorProvider(ctx.read<SessionProvider>()),
                update: (_, session, prev) => prev ?? CalculatorProvider(session),
              ),
              p.ChangeNotifierProxyProvider<SessionProvider, CalendarProvider>(
                create: (ctx) => CalendarProvider(ctx.read<SessionProvider>()),
                update: (_, session, prev) => prev ?? CalendarProvider(session),
              ),
              p.ChangeNotifierProxyProvider<SessionProvider, NotesProvider>(
                create: (ctx) => NotesProvider(ctx.read<SessionProvider>()),
                update: (_, session, prev) => prev ?? NotesProvider(session),
              ),
              p.ChangeNotifierProxyProvider<SessionProvider, ContactsProvider>(
                create: (ctx) => ContactsProvider(ctx.read<SessionProvider>()),
                update: (_, session, prev) => prev ?? ContactsProvider(session),
              ),
              p.ChangeNotifierProvider(create: (_) => CurrencyConverterProvider()),
            ],
            child: const MaterialApp(
              home: ResponsiveShell(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find profile chip in header showing user name / email
      final profileFinder = find.text('Ravi Kumar C');
      expect(profileFinder, findsWidgets);

      // Tap on the user profile chip to open the profile dropdown dialog
      await tester.tap(profileFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the 'Manage your Account' button appears in the popup
      final manageAccountButton = find.text('Manage your Account');
      expect(manageAccountButton, findsOneWidget);

      // Tap 'Manage your Account'
      await tester.tap(manageAccountButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify navigation to ManageAccountScreen
      expect(find.byType(ManageAccountScreen), findsOneWidget);
    } finally {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
