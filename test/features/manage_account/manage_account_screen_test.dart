import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/features/manage_account/presentation/manage_account_screen.dart';
import 'package:bit_tools_backend/features/manage_account/data/providers/account_provider.dart';
import 'package:bit_tools_backend/features/manage_account/models/account_model.dart';
import 'package:bit_tools_backend/features/manage_account/core/network/token_service.dart';

void main() {
  setUp(() async {
    TokenService.cachedAccessToken = 'mock_test_token';
  });

  tearDown(() {
    TokenService.cachedAccessToken = null;
  });

  group('ManageAccountScreen Widget Tests', () {
    testWidgets('Renders ManageAccountScreen with tabs and top app bar', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              accountsProvider.overrideWith((ref) {
                final notifier = AccountsNotifier();
                notifier.state = [
                  const AccountModel(
                    id: 'ravi@bnxmail.com',
                    name: 'Ravi Kumar C',
                    email: 'ravi@bnxmail.com',
                    avatarColor: Color(0xFF195BAC),
                    isActive: true,
                  ),
                ];
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: ManageAccountScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify top app bar title contains 'Account'
        expect(find.text('Account'), findsWidgets);

        // Verify sidebar navigation tab labels
        expect(find.text('Home'), findsWidgets);
        expect(find.text('Personal info'), findsWidgets);
        expect(find.text('Payment &\nsubscription'), findsWidgets);
        expect(find.text('Team & Sub-IDs'), findsWidgets);
        expect(find.text('Account storage'), findsWidgets);
        expect(find.text('B2Auth'), findsWidgets);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Tapping sidebar tabs switches active tab view', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              accountsProvider.overrideWith((ref) {
                final notifier = AccountsNotifier();
                notifier.state = [
                  const AccountModel(
                    id: 'ravi@bnxmail.com',
                    name: 'Ravi Kumar C',
                    email: 'ravi@bnxmail.com',
                    avatarColor: Color(0xFF195BAC),
                    isActive: true,
                  ),
                ];
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: ManageAccountScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap on 'Personal info' tab
        await tester.tap(find.text('Personal info').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify Personal info header or content appears
        expect(find.textContaining('Personal info'), findsWidgets);

        // Tap on 'Account storage' tab
        await tester.tap(find.text('Account storage').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify storage appears in full page
        expect(find.textContaining('Storage'), findsWidgets);

        // Pop back to continue testing other tabs
        final backBtn = find.byTooltip('Back to Account');
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn.first);
        } else {
          final navigator = tester.state<NavigatorState>(find.byType(Navigator));
          navigator.pop();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap on 'B2Auth' tab
        await tester.tap(find.text('B2Auth').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.textContaining('B2Auth'), findsWidgets);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
