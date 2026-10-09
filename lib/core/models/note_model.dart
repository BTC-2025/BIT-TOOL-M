import 'package:flutter/foundation.dart';

/// Strongly-typed model representing a note record from the Bit Tool backend.
@immutable
class NoteModel {
  final String id;
  final String? userEmail;
  final String applicationName;
  final String title;
  final String content;
  final bool isPinned;
  final String color;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> items;
  final List<dynamic> tags;

  const NoteModel({
    required this.id,
    this.userEmail,
    this.applicationName = 'Bit Tool',
    this.title = '',
    this.content = '',
    this.isPinned = false,
    this.color = '#A7F3D0',
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.tags = const [],
  });

  /// Backwards-compatibility alias for [applicationName].
  String get category => applicationName;

  /// Backwards-compatibility alias for [color].
  String get colorHex => color;

  /// Effective display title, defaulting to 'Untitled Note' if empty.
  String get displayTitle => title.trim().isEmpty ? 'Untitled Note' : title.trim();

  /// Deserializes a [NoteModel] from backend JSON.
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final id = json['id']?.toString() ?? '';
    final userEmail = json['userEmail']?.toString();
    final appName = json['applicationName']?.toString() ??
        json['appName']?.toString() ??
        json['category']?.toString() ??
        'Bit Tool';
    final title = json['title']?.toString() ?? '';
    final content = json['content']?.toString() ?? '';
    final isPinned = json['isPinned'] == true ||
        json['isPinned'] == 'true' ||
        json['isPinned'] == 1;
    final color = json['color']?.toString() ??
        json['colorHex']?.toString() ??
        '#A7F3D0';
    final isArchived = json['isArchived'] == true ||
        json['isArchived'] == 'true' ||
        json['isArchived'] == 1;

    final createdAt = parseDateTime(json['createdAt']);
    final updatedAt = parseDateTime(json['updatedAt']) ?? createdAt;

    final items = json['items'] is List ? List<dynamic>.from(json['items'] as List) : const [];
    final tags = json['tags'] is List ? List<dynamic>.from(json['tags'] as List) : const [];

    return NoteModel(
      id: id,
      userEmail: userEmail,
      applicationName: appName,
      title: title,
      content: content,
      isPinned: isPinned,
      color: color,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: items,
      tags: tags,
    );
  }

  /// Serializes the [NoteModel] to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (userEmail != null) 'userEmail': userEmail,
    'applicationName': applicationName,
    'title': title,
    'content': content,
    'isPinned': isPinned,
    'color': color,
    'isArchived': isArchived,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'items': items,
    'tags': tags,
  };

  /// Formats creation payload for documented POST /create request.
  static Map<String, dynamic> toCreateJson({
    required String title,
    required String content,
    String? color,
    bool isPinned = false,
    String? applicationName,
  }) {
    return {
      'title': title,
      'content': content,
      'color': color ?? '#A7F3D0',
      'isPinned': isPinned,
      if (applicationName != null && applicationName.trim().isNotEmpty)
        'applicationName': applicationName.trim(),
    };
  }

  /// Formats partial update payload for documented PUT /update/:id request.
  static Map<String, dynamic> toUpdateJson({
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    bool? isArchived,
    String? applicationName,
  }) {
    return {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (color != null) 'color': color,
      if (isPinned != null) 'isPinned': isPinned,
      if (isArchived != null) 'isArchived': isArchived,
      if (applicationName != null && applicationName.trim().isNotEmpty)
        'applicationName': applicationName.trim(),
    };
  }

  /// Returns a copy of this [NoteModel] with the specified fields updated.
  NoteModel copyWith({
    String? id,
    String? userEmail,
    String? applicationName,
    String? title,
    String? content,
    bool? isPinned,
    String? color,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<dynamic>? items,
    List<dynamic>? tags,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      applicationName: applicationName ?? this.applicationName,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userEmail == other.userEmail &&
          applicationName == other.applicationName &&
          title == other.title &&
          content == other.content &&
          isPinned == other.isPinned &&
          color == other.color &&
          isArchived == other.isArchived &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userEmail.hashCode ^
      applicationName.hashCode ^
      title.hashCode ^
      content.hashCode ^
      isPinned.hashCode ^
      color.hashCode ^
      isArchived.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'NoteModel(id: $id, title: $title, app: $applicationName, pinned: $isPinned, archived: $isArchived)';
}

/// Backwards-compatibility type alias.
typedef NoteItem = NoteModel;
