// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import '../lib/bit_tool_api_module.dart';

void main() {
  group('BitToolApiRegistry Tests', () {
    test('Registry contains all module endpoints and zero login endpoints', () {
      const all = BitToolApiRegistry.allEndpoints;

      expect(all.length, greaterThanOrEqualTo(30));

      // Strictly verify no login endpoints exist
      for (final ep in all) {
        expect(ep.path.toLowerCase().contains('/auth/login'), isFalse,
            reason: 'Login endpoints must not be included');
        expect(ep.path.toLowerCase().contains('/login'), isFalse,
            reason: 'Login endpoints must not be included');
      }
    });

    test('Available modules include all feature modules', () {
      final modules = BitToolApiRegistry.availableModules;

      expect(modules, contains('Contacts'));
      expect(modules, contains('Notes'));
      expect(modules, contains('Calendar'));
      expect(modules, contains('Calculator'));
      expect(modules, contains('Notifications'));
      expect(modules, contains('Weather'));
      expect(modules, contains('Currency'));
      expect(modules, contains('User Profile'));
    });

    test('Search filters endpoints accurately', () {
      final contactsResults = BitToolApiRegistry.search('Contacts');
      expect(contactsResults, isNotEmpty);

      final rentSearch = BitToolApiRegistry.search('Rent');
      expect(rentSearch, isNotEmpty);

      final postMethods = BitToolApiRegistry.search('POST');
      expect(postMethods, isNotEmpty);
    });

    test('JSON serialization contains expected structure', () {
      final json = BitToolApiRegistry.toJson();
      expect(json['totalEndpoints'], equals(BitToolApiRegistry.allEndpoints.length));
      expect(json['modules'], isA<Map>());
      expect((json['modules'] as Map).containsKey('Contacts'), isTrue);
    });
  });

  group('BitToolApiModule Facade Tests', () {
    test('Facade initializes all services without login requirement', () {
      final module = BitToolApiModule(
        tokenProvider: () async => 'test_token_from_host_app',
      );

      expect(module.contacts, isNotNull);
      expect(module.notes, isNotNull);
      expect(module.calendar, isNotNull);
      expect(module.calculator, isNotNull);
      expect(module.notifications, isNotNull);
      expect(module.weather, isNotNull);
      expect(module.currency, isNotNull);
      expect(module.userProfile, isNotNull);
      expect(module.allEndpoints.length, equals(BitToolApiRegistry.allEndpoints.length));
    });
  });
}
