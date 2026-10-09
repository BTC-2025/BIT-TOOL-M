import 'package:flutter/foundation.dart';

/// Strongly typed model representing a notification item.
@immutable
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final String? type;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.isRead = false,
    this.createdAt,
    this.type,
    this.metadata,
  });

  /// Safely constructs a [NotificationModel] from raw JSON.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? json['notificationId'];
    final id = rawId?.toString() ?? '';

    final title =
        json['title']?.toString() ??
        json['subject']?.toString() ??
        json['heading']?.toString() ??
        json['name']?.toString() ??
        '';

    final message =
        json['message']?.toString() ??
        json['body']?.toString() ??
        json['content']?.toString() ??
        json['description']?.toString() ??
        json['text']?.toString() ??
        '';

    final rawIsRead = json['isRead'] ?? json['read'] ?? json['is_read'];
    final isRead = rawIsRead is bool
        ? rawIsRead
        : (rawIsRead == 1 ||
              rawIsRead?.toString().toLowerCase() == 'true' ||
              json['status']?.toString().toLowerCase() == 'read');

    DateTime? createdAt;
    final rawTime =
        json['createdAt'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['date'] ??
        json['time'];
    if (rawTime is String) {
      createdAt = DateTime.tryParse(rawTime);
    } else if (rawTime is num) {
      final intTime = rawTime.toInt();
      if (intTime > 100000000000) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(intTime);
      } else {
        createdAt = DateTime.fromMillisecondsSinceEpoch(intTime * 1000);
      }
    }

    final type = json['type']?.toString() ?? json['category']?.toString();

    Map<String, dynamic>? metadata;
    if (json['metadata'] is Map<String, dynamic>) {
      metadata = json['metadata'] as Map<String, dynamic>;
    }

    return NotificationModel(
      id: id,
      title: title,
      message: message,
      isRead: isRead,
      createdAt: createdAt,
      type: type,
      metadata: metadata,
    );
  }

  /// Returns a clean relative time string (e.g., 'Just now', '5m ago', '2h ago').
  String get timeAgo {
    if (createdAt == null) return '';
    final difference = DateTime.now().difference(createdAt!);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt!.year}-${createdAt!.month.toString().padLeft(2, '0')}-${createdAt!.day.toString().padLeft(2, '0')}';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'isRead': isRead,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (type != null) 'type': type,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          message == other.message &&
          isRead == other.isRead &&
          createdAt == other.createdAt &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, title, message, isRead, createdAt, type);
}
