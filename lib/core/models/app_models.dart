class MailItem {
  final String id;
  final String sender;
  final String receiver;
  final String subject;
  final DateTime time;
  final String priority;
  final List<String> attachments;
  final String body;
  final String status; // Read, Unread
  final String category; // Inbox, Sent, Draft, Spam, Trash, Archive
  final List<String> tags;
  bool isStarred;
  bool isImportant;

  MailItem({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.subject,
    required this.time,
    required this.priority,
    required this.attachments,
    required this.body,
    required this.status,
    required this.category,
    required this.tags,
    this.isStarred = false,
    this.isImportant = false,
  });
}

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

class ChatMessage {
  final String id;
  final String senderName;
  final String messageText;
  final DateTime time;
  final bool isSentByMe;
  final String status; // Sent, Delivered, Read
  final bool isPinned;
  final String category; // Inbox, Sent, Archived, Pinned, Draft

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.messageText,
    required this.time,
    required this.isSentByMe,
    required this.status,
    this.isPinned = false,
    this.category = 'Inbox',
  });
}

class FileItem {
  final String id;
  final String name;
  final String size;
  final String category; // Recent, Uploaded, Downloaded, Shared, Deleted, Favorite
  final String fileType; // PDF, CSV, PNG, DOCX
  final DateTime lastModified;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.category,
    required this.fileType,
    required this.lastModified,
  });
}
