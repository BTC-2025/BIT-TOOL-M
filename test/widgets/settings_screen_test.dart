import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/providers/theme_provider.dart';
import 'package:bit_tools_backend/features/settings/settings_screen.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('renders Settings title, subtitle, and profile information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Manage your preferences and account'), findsOneWidget);

      // Verify Profile card content
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Your personal information'), findsOneWidget);
      expect(find.text('Ravi Kumar C'), findsOneWidget);
      expect(find.text('ravinew2004@bnxmail.com'), findsOneWidget);
      expect(find.text('ACCOUNT TYPE'), findsOneWidget);
      expect(find.text('BUSINESS'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('8072909876'), findsOneWidget);
      expect(find.text('RECOVERY EMAIL'), findsOneWidget);
      expect(find.text('chandran123@bnxmail.com'), findsOneWidget);
      expect(find.text('DATE OF BIRTH'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('0.02 GB / 15.00 GB'), findsOneWidget);
    });

    testWidgets('renders Appearance card and toggles between Light and Dark mode', (
      WidgetTester tester,
    ) async {
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
    });

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

    testWidgets('renders About Bit Tool card with version 1.0.0 and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SettingsScreen())),
      );
      await tester.pumpAndSettle();

      // Verify About card content
      expect(find.text('About Bit Tool'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(
        find.textContaining('Bit Tool is a premium suite of productivity applications'),
        findsOneWidget,
      );
    });
  });
}
