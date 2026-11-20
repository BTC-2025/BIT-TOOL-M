import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/features/storage/models/storage_quota.dart';
import 'package:bit_tools_backend/features/storage/models/vault_file.dart';
import 'package:bit_tools_backend/features/storage/pages/macos_storage_page.dart';
import 'package:bit_tools_backend/features/storage/data/providers/storage_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storage Models Tests', () {
    test('StorageQuota model calculations and formatting', () {
      final quota = StorageQuota.fromJson({
        'email': 'user@bnxmail.com',
        'storageLimit': 5368709120, // 5 GB
        'storageUsed': 1073741824, // 1 GB
        'storagePercentage': 20.0,
      });

      expect(quota.email, equals('user@bnxmail.com'));
      expect(quota.storageLimit, equals(5368709120));
      expect(quota.storageUsed, equals(1073741824));
      expect(quota.storagePercentage, equals(20.0));
      expect(quota.fraction, closeTo(0.2, 0.01));
      expect(StorageQuota.formatBytes(1073741824), equals('1 GB'));
    });

    test('VaultFile model correctly parses JSON', () {
      final vaultJson = {
        'id': 123,
        'filename': 'Backup_Archive.zip',
        'size': 20971520, // 20 MB
        'contentType': 'application/zip',
        'createdAt': '2026-11-20T10:00:00Z',
      };

      final file = VaultFile.fromJson(vaultJson);
      expect(file.id, equals(123));
      expect(file.filename, equals('Backup_Archive.zip'));
      expect(file.size, equals(20971520));
      expect(file.sizeFormatted, equals('20 MB'));
      expect(file.contentType, equals('application/zip'));
    });
  });

  group('MacOsStoragePage Widget Tests', () {
    testWidgets('Renders MacOsStoragePage and navigates tabs without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      try {
        const mockQuota = StorageQuota(
          email: 'testuser@bnxmail.com',
          storageLimit: 5368709120,
          storageUsed: 10485760, // ~10 MB
          storagePercentage: 0.19,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageQuotaProvider.overrideWith(
                (ref) => StorageQuotaNotifier()
                  ..state = const AsyncValue.data(mockQuota),
              ),
            ],
            child: const MaterialApp(
              home: MacOsStoragePage(
                initialEmail: 'testuser@bnxmail.com',
                initialName: 'Test User',
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Storage top bar / header
        expect(find.text('Storage'), findsWidgets);
        expect(find.text('Test User'), findsWidgets);

        // Verify Sidebar items exist
        expect(find.text('Home'), findsWidgets);
        expect(find.text('Bnx mail'), findsWidgets);
        expect(find.text('Cliks'), findsWidgets);
        expect(find.text('Cliks Business'), findsWidgets);
        expect(find.text('Storage Usage'), findsWidgets);
        expect(find.text('Recycle Bin'), findsWidgets);
        expect(find.text('Manage Apps'), findsWidgets);
        expect(find.text('Settings'), findsWidgets);

        // Tap Bnx mail
        await tester.tap(find.text('Bnx mail').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Cliks Business
        await tester.tap(find.text('Cliks Business').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Storage Usage
        await tester.tap(find.text('Storage Usage').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap Settings
        await tester.tap(find.text('Settings').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap back to Home
        await tester.tap(find.text('Home').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Application Storage'), findsWidgets);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
