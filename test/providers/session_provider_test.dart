import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/providers/session_provider.dart';

void main() {
  group('SessionProvider', () {
    late SessionProvider provider;

    setUp(() {
      provider = SessionProvider();
    });

    test('initializes with seed activities', () {
      expect(provider.activities, isNotEmpty);
      expect(provider.activities.length, greaterThanOrEqualTo(5));
    });

    test('logActivity prepends a new activity', () {
      final initialCount = provider.activities.length;

      provider.logActivity(
        iconName: 'fingerprint',
        device: 'Test Device',
        module: 'Security Unit',
        duration: '10ms',
        status: 'Success',
        description: 'Mock session event',
        category: 'Test',
      );

      expect(provider.activities.length, equals(initialCount + 1));
      expect(provider.activities.first.module, equals('Security Unit'));
      expect(
        provider.activities.first.description,
        equals('Mock session event'),
      );
      expect(provider.activities.first.category, equals('Test'));
    });

    test('clearHistory removes previous items and logs a system activity', () {
      provider.clearHistory();

      expect(provider.activities.length, equals(1));
      expect(provider.activities.first.module, equals('Session Tracking'));
      expect(provider.activities.first.category, equals('System'));
    });
  });
}
