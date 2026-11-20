import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/features/manage_account/data/providers/account_provider.dart';
import 'package:bit_tools_backend/features/manage_account/data/repositories/storage_repository.dart';
import 'package:bit_tools_backend/features/manage_account/models/account_model.dart';
import 'package:bit_tools_backend/features/manage_account/presentation/manage_account_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Multi-Account Switching Tests', () {
    testWidgets('ManageAccountScreen binds dynamically to initialEmail and does not show fixed fallback', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ManageAccountScreen(
                initialEmail: 'ramaniteam123@bnxmail.com',
                initialName: 'ramaniteam123',
                initialAccountType: 'BUSINESS',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        for (final elem in find.byType(Text).evaluate()) {
          final t = elem.widget as Text;
          if (t.data != null && t.data!.contains('Welcome')) {
            print('DEBUG WELCOME: "${t.data}"');
          }
        }

        // 1. Welcome Header must say ramaniteam123
        expect(find.text('Welcome, ramaniteam123'), findsOneWidget);

        // 2. Emails & Identities card MUST display ramaniteam123@bnxmail.com, NEVER ravinew2004
        expect(find.text('ramaniteam123@bnxmail.com'), findsAtLeastNWidgets(1));
        expect(find.text('ravinew2004@bnxmail.com'), findsNothing);

        // 3. Storage text must NOT be the hardcoded 8.88 MB if quota is clean
        expect(find.text('8.88 MB of 5 GB used'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('AccountsNotifier switches accounts and activeAccountProvider updates dynamically', () async {
      final container = ProviderContainer(
        overrides: [
          accountsProvider.overrideWith((ref) {
            final notifier = AccountsNotifier();
            notifier.state = [
              const AccountModel(
                id: 'ramaniteam123@bnxmail.com',
                name: 'Ramani Team',
                email: 'ramaniteam123@bnxmail.com',
                avatarColor: Color(0xFF195BAC),
                isActive: true,
                accountType: 'BUSINESS',
              ),
              const AccountModel(
                id: 'chandran123@bnxmail.com',
                name: 'Chandran C',
                email: 'chandran123@bnxmail.com',
                avatarColor: Color(0xFF22C55E),
                isActive: false,
                accountType: 'PERSONAL',
              ),
            ];
            return notifier;
          }),
        ],
      );

      try {
        // Verify active account initially
        expect(container.read(activeAccountProvider).email, 'ramaniteam123@bnxmail.com');
        expect(container.read(activeAccountProvider).name, 'Ramani Team');

        // Switch to chandran123
        await container.read(accountsProvider.notifier).switchAccount('chandran123@bnxmail.com');

        // Active account must now be chandran123
        expect(container.read(activeAccountProvider).email, 'chandran123@bnxmail.com');
        expect(container.read(activeAccountProvider).name, 'Chandran C');
        expect(container.read(activeAccountProvider).accountType, 'PERSONAL');
      } finally {
        container.dispose();
      }
    });

    test('StorageQuota dynamically computes fraction and formatted bytes', () {
      final quota1 = StorageQuota.fromJson({
        'email': 'ramaniteam123@bnxmail.com',
        'storageLimit': 1073741824, // 1 GB
        'storageUsed': 0,
        'storagePercentage': 0.0,
      });

      expect(quota1.usedFormatted, '0 B');
      expect(quota1.limitFormatted, '1 GB');
      expect(quota1.fraction, 0.0);

      final quota2 = StorageQuota.fromJson({
        'email': 'user2@bnxmail.com',
        'storageLimit': 5368709120, // 5 GB
        'storageUsed': 2684354560, // 2.5 GB
        'storagePercentage': 50.0,
      });

      expect(quota2.usedFormatted, '2.50 GB');
      expect(quota2.limitFormatted, '5 GB');
      expect(quota2.fraction, 0.5);
    });
  });
}
