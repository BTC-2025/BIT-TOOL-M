class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String colorHex;
  final String category; // Meeting, Birthday, Holiday
  final String location;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    required this.colorHex,
    required this.category,
    required this.location,
  });
}

class ContactItem {
  final String id;
  final String photoUrl;
  final String name;
  final String company;
  final String designation;
  final String phone;
  final String email;
  final String department;
  final String location;
  final String notes;
  bool isFavorite;
  bool isBlocked;

  ContactItem({
    required this.id,
    required this.photoUrl,
    required this.name,
    required this.company,
    required this.designation,
    required this.phone,
    required this.email,
    required this.department,
    required this.location,
    required this.notes,
    this.isFavorite = false,
    this.isBlocked = false,
  });
}

class NoteItem {
  final String id;
  String title;
  String content;
  DateTime updatedAt;
  String category; // General, Work, Personal, Ideas, Todo
  bool isPinned;
  String colorHex;

  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.category = 'General',
    this.isPinned = false,
    this.colorHex = '#3B82F6',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
    'category': category,
    'isPinned': isPinned,
    'colorHex': colorHex,
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    category: json['category'] as String? ?? 'General',
    isPinned: json['isPinned'] as bool? ?? false,
    colorHex: json['colorHex'] as String? ?? '#3B82F6',
  );
}
