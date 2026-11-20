import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/features/manage_account/models/account_model.dart';
import 'package:bit_tools_backend/features/manage_account/models/blocked_contact_model.dart';
import 'package:bit_tools_backend/features/manage_account/models/signature_model.dart';
import 'package:bit_tools_backend/features/manage_account/models/two_factor_model.dart';
import 'package:bit_tools_backend/features/manage_account/models/user_model.dart';
import 'package:bit_tools_backend/features/manage_account/models/user_settings_model.dart';
import 'package:bit_tools_backend/features/manage_account/data/repositories/storage_repository.dart';

void main() {
  group('Manage Account Models Tests', () {
    test('StorageQuota correctly parses and computes formatting and fractions', () {
      final quota = StorageQuota.fromJson({
        'email': 'ravi@bnxmail.com',
        'storageLimit': 5368709120, // 5 GB
        'storageUsed': 9311354, // ~8.88 MB
        'storagePercentage': 0.17,
      });

      expect(quota.email, 'ravi@bnxmail.com');
      expect(quota.storageLimitBytes, 5368709120);
      expect(quota.storageUsedBytes, 9311354);
      expect(quota.limitFormatted, '5 GB');
      expect(quota.usedFormatted, contains('MB'));
      expect(quota.fraction, greaterThan(0.0));
      expect(quota.fraction, lessThan(1.0));
      expect(quota.status, 'Normal');
      expect(quota.statusColor, const Color(0xFF10B981));
    });

    test('AccountModel copyWith and defaults work correctly', () {
      const account = AccountModel(
        id: 'acc-1',
        name: 'Ravi Kumar',
        email: 'ravi@bnxmail.com',
        avatarColor: Colors.blue,
        isActive: true,
      );

      final updated = account.copyWith(
        name: 'Ravi Kumar C',
        avatarUrl: 'https://example.com/photo.png',
      );

      expect(updated.id, 'acc-1');
      expect(updated.name, 'Ravi Kumar C');
      expect(updated.email, 'ravi@bnxmail.com');
      expect(updated.avatarUrl, 'https://example.com/photo.png');
      expect(updated.isActive, true);
    });

    test('UserModel parses from JSON accurately', () {
      final user = UserModel.fromJson({
        'email': 'user@bnxmail.com',
        'name': 'Test User',
        'firstName': 'Test',
        'lastName': 'User',
        'role': 'user',
        'avatarUrl': 'https://example.com/avatar.jpg',
      });

      expect(user.email, 'user@bnxmail.com');
      expect(user.name, 'Test User');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('TwoFactorSetupData parses secret and QR code correctly', () {
      final data = TwoFactorSetupData.fromJson({
        'secret': 'JBSWY3DPEHPK3PXP',
        'qrCode': 'data:image/png;base64,iVBORw0KGgo...',
      });

      expect(data.secret, 'JBSWY3DPEHPK3PXP');
      expect(data.qrCode, startsWith('data:image/png'));
    });

    test('BlockedContact parses correctly', () {
      final contact = BlockedContact.fromJson({
        'email': 'spam@example.com',
        'blockedAt': '2026-11-19T10:00:00Z',
      });

      expect(contact.email, 'spam@example.com');
      expect(contact.blockedAt, isNotNull);
    });

    test('UserSettings parses settings correctly', () {
      final settings = UserSettings.fromJson({
        'twoFactorEnabled': true,
        'language': 'en',
        'themeMode': 'dark',
      });

      expect(settings.twoFactorEnabled, true);
      expect(settings.language, 'en');
      expect(settings.themeMode, 'dark');
    });

    test('SignatureModel parses signature fields', () {
      final sig = SignatureModel.fromJson({
        'id': 'sig-1',
        'name': 'Work Signature',
        'content': 'Best regards,\nRavi',
        'isDefault': true,
      });

      expect(sig.id, 'sig-1');
      expect(sig.name, 'Work Signature');
      expect(sig.content, contains('Best regards'));
      expect(sig.isDefault, true);
    });
  });
}
