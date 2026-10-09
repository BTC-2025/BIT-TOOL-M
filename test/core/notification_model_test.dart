import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/notification_model.dart';

void main() {
  group('NotificationModel Tests', () {
    test('parses standard notification JSON object correctly', () {
      final json = {
        'id': 'notif-101',
        'title': 'New Update',
        'message': 'System has been updated.',
        'isRead': false,
        'createdAt': '2026-10-09T08:00:00.000Z',
        'type': 'system',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-101');
      expect(model.title, 'New Update');
      expect(model.message, 'System has been updated.');
      expect(model.isRead, false);
      expect(model.type, 'system');
      expect(model.createdAt, isNotNull);
    });

    test('handles alternate field names and types gracefully', () {
      final json = {
        '_id': 12345,
        'heading': 'Meeting Alert',
        'body': 'Meeting starts in 10 minutes',
        'read': 1,
        'timestamp': 1760000000000,
        'category': 'calendar',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, '12345');
      expect(model.title, 'Meeting Alert');
      expect(model.message, 'Meeting starts in 10 minutes');
      expect(model.isRead, true);
      expect(model.type, 'calendar');
      expect(model.createdAt, isNotNull);
    });

    test('parses status string "read" as isRead = true', () {
      final json = {'id': '99', 'title': 'Test', 'status': 'read'};

      final model = NotificationModel.fromJson(json);
      expect(model.isRead, true);
    });

    test('calculates clean relative timeAgo strings', () {
      final now = DateTime.now();

      final justNowModel = NotificationModel(
        id: '1',
        title: 'T',
        message: 'M',
        createdAt: now.subtract(const Duration(seconds: 30)),
      );
      expect(justNowModel.timeAgo, 'Just now');

      final minutesModel = NotificationModel(
        id: '2',
        title: 'T',
        message: 'M',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(minutesModel.timeAgo, '5m ago');

      final hoursModel = NotificationModel(
        id: '3',
        title: 'T',
        message: 'M',
        createdAt: now.subtract(const Duration(hours: 3)),
      );
      expect(hoursModel.timeAgo, '3h ago');

      final yesterdayModel = NotificationModel(
        id: '4',
        title: 'T',
        message: 'M',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      expect(yesterdayModel.timeAgo, 'Yesterday');
    });

    test('copyWith creates modified clone correctly', () {
      const model = NotificationModel(
        id: '1',
        title: 'Initial',
        message: 'Initial message',
        isRead: false,
      );

      final updated = model.copyWith(isRead: true, title: 'Updated');

      expect(updated.id, '1');
      expect(updated.title, 'Updated');
      expect(updated.isRead, true);
      expect(model.isRead, false); // Original remains unchanged
    });

    test('toJson serializes correctly', () {
      const model = NotificationModel(
        id: '1',
        title: 'Title',
        message: 'Message',
        isRead: true,
        type: 'weather',
      );

      final map = model.toJson();
      expect(map['id'], '1');
      expect(map['title'], 'Title');
      expect(map['message'], 'Message');
      expect(map['isRead'], true);
      expect(map['type'], 'weather');
    });
  });
}
