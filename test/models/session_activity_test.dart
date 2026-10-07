import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/session_activity.dart';

void main() {
  group('SessionActivity Model', () {
    test('serializes and deserializes correctly to/from JSON', () {
      final now = DateTime.now();
      final activity = SessionActivity(
        id: 'test-123',
        iconName: 'security',
        timestamp: now,
        device: 'MacBook Pro',
        module: 'Authentication',
        duration: '150ms',
        status: 'Success',
        description: 'Biometric authorization successful',
        category: 'Security',
      );

      final json = activity.toJson();
      expect(json['id'], equals('test-123'));
      expect(json['iconName'], equals('security'));
      expect(json['module'], equals('Authentication'));
      expect(json['category'], equals('Security'));

      final fromJson = SessionActivity.fromJson(json);
      expect(fromJson.id, equals(activity.id));
      expect(fromJson.iconName, equals(activity.iconName));
      expect(fromJson.device, equals(activity.device));
      expect(fromJson.module, equals(activity.module));
      expect(fromJson.duration, equals(activity.duration));
      expect(fromJson.status, equals(activity.status));
      expect(fromJson.description, equals(activity.description));
      expect(fromJson.category, equals(activity.category));
    });
  });
}
