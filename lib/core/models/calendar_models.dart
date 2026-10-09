import 'package:flutter/foundation.dart';

/// Strongly-typed model for event categories.
@immutable
class CalendarCategory {
  final String id;
  final String name;
  final String color;
  final String? userEmail;
  final String applicationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalendarCategory({
    required this.id,
    required this.name,
    this.color = '#3B82F6',
    this.userEmail,
    this.applicationName = 'Bit Tool',
    this.createdAt,
    this.updatedAt,
  });

  factory CalendarCategory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return CalendarCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString() ?? '#3B82F6',
      userEmail: json['userEmail']?.toString(),
      applicationName: json['applicationName']?.toString() ?? 'Bit Tool',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    if (userEmail != null) 'userEmail': userEmail,
    'applicationName': applicationName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  CalendarCategory copyWith({
    String? id,
    String? name,
    String? color,
    String? userEmail,
    String? applicationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      userEmail: userEmail ?? this.userEmail,
      applicationName: applicationName ?? this.applicationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ color.hashCode;

  @override
  String toString() => 'CalendarCategory(id: $id, name: $name, color: $color)';
}

/// Strongly-typed model for calendar events.
@immutable
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? date;
  final String? categoryId;
  final CalendarCategory? categoryModel;
  final String location;
  final String? color;
  final String status;
  final String? userEmail;
  final String applicationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    this.date,
    this.categoryId,
    this.categoryModel,
    this.location = '',
    this.color,
    this.status = 'scheduled',
    this.userEmail,
    this.applicationName = 'Bit Tool',
    this.createdAt,
    this.updatedAt,
  });

  /// String category name for backward compatibility with existing callers.
  String get category => categoryModel?.name ?? 'General';

  /// Category object reference.
  CalendarCategory? get categoryObj => categoryModel;

  /// Nullable location if raw value is needed.
  String? get rawLocation => location.isEmpty ? null : location;

  /// Effective color hex string.
  String get colorHex => color ?? categoryModel?.color ?? 'FF2196F3';

  /// Backwards-compatibility getter.
  bool get isRecurring => false;

  /// Effective category name alias.
  String get categoryName => category;

  /// Effective location alias.
  String get effectiveLocation => location;

  /// Formatted date string in YYYY-MM-DD format.
  String get formattedDate {
    if (date != null && date!.trim().isNotEmpty) {
      final s = date!.trim();
      final match = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(s);
      if (match != null) {
        final y = match.group(1)!;
        final m = match.group(2)!.padLeft(2, '0');
        final d = match.group(3)!.padLeft(2, '0');
        return '$y-$m-$d';
      }
    }
    return '${startTime.year.toString().padLeft(4, '0')}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
  }

  /// Checks if this event matches the specified calendar year, month, and day.
  bool matchesDay(int y, int m, int d) {
    if (startTime.year == y && startTime.month == m && startTime.day == d) {
      return true;
    }
    if (date != null && date!.trim().isNotEmpty) {
      final s = date!.trim();
      final match = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(s);
      if (match != null) {
        final parsedY = int.tryParse(match.group(1)!);
        final parsedM = int.tryParse(match.group(2)!);
        final parsedD = int.tryParse(match.group(3)!);
        if (parsedY == y && parsedM == m && parsedD == d) {
          return true;
        }
      }
      final parsed = DateTime.tryParse(s);
      if (parsed != null &&
          parsed.year == y &&
          parsed.month == m &&
          parsed.day == d) {
        return true;
      }
    }
    return false;
  }

  /// Checks if this event falls on the specified DateTime (day precision).
  bool matchesDate(DateTime targetDate) =>
      matchesDay(targetDate.year, targetDate.month, targetDate.day);

  /// Checks if this event matches an application name filter.
  bool matchesApp(String filter) {
    if (filter == 'All Apps') return true;
    final normalizedFilter = filter.trim().toLowerCase();
    final normalizedApp = applicationName.trim().toLowerCase();
    if (normalizedApp == normalizedFilter) return true;
    if (normalizedFilter == 'bit tool') {
      return normalizedApp.isEmpty ||
          normalizedApp == 'web' ||
          normalizedApp == 'web app' ||
          normalizedApp == 'browser' ||
          normalizedApp == 'chrome' ||
          normalizedApp == 'bit-tool' ||
          normalizedApp == 'bit_tool';
    }
    return false;
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.toLocal();
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    final rawDate = json['date'] ??
        json['eventDate'] ??
        json['startDate'] ??
        json['start_date'];
    final rawStart = json['startTime'] ??
        json['start_time'] ??
        json['time'] ??
        json['start'];
    final rawEnd = json['endTime'] ??
        json['end_time'] ??
        json['end'];

    final (parsedStart, parsedEnd, resolvedDateStr) = _parseEventDateTimes(
      rawDate: rawDate,
      rawStart: rawStart,
      rawEnd: rawEnd,
    );

    CalendarCategory? cat;
    if (json['category'] is Map<String, dynamic>) {
      cat = CalendarCategory.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['category'] is Map) {
      cat = CalendarCategory.fromJson(
        Map<String, dynamic>.from(json['category'] as Map),
      );
    }

    final eventId = json['id']?.toString() ?? json['_id']?.toString() ?? '';
    final catId = json['categoryId']?.toString() ??
        json['category_id']?.toString() ??
        cat?.id;
    final email = json['userEmail']?.toString() ??
        json['user_email']?.toString() ??
        json['email']?.toString();
    final appName = json['applicationName']?.toString() ??
        json['application_name']?.toString() ??
        json['appName']?.toString() ??
        json['app_name']?.toString() ??
        'Bit Tool';

    return CalendarEvent(
      id: eventId,
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['details']?.toString() ??
          '',
      startTime: parsedStart,
      endTime: parsedEnd,
      date: resolvedDateStr,
      categoryId: catId,
      categoryModel: cat,
      location: json['location']?.toString() ?? '',
      color: json['color']?.toString(),
      status: json['status']?.toString() ?? 'scheduled',
      userEmail: email,
      applicationName: appName,
      createdAt: parseNullableDate(json['createdAt']),
      updatedAt: parseNullableDate(json['updatedAt']),
    );
  }

  static (DateTime, DateTime, String?) _parseEventDateTimes({
    required dynamic rawDate,
    required dynamic rawStart,
    required dynamic rawEnd,
  }) {
    final startStr = rawStart?.toString().trim();
    final endStr = rawEnd?.toString().trim();
    final dateStr = rawDate?.toString().trim();

    final hasExplicitDate = dateStr != null && dateStr.isNotEmpty;

    // Check if rawStart can be directly parsed as an ISO date-time
    DateTime? directStart;
    if (startStr != null && startStr.isNotEmpty) {
      directStart = DateTime.tryParse(startStr);
    }

    DateTime? directEnd;
    if (endStr != null && endStr.isNotEmpty) {
      directEnd = DateTime.tryParse(endStr);
    }

    // Helper to parse time-of-day (hour and minute) from various formats
    (int, int)? parseHourMinute(String? s) {
      if (s == null || s.isEmpty) return null;

      // 12-hour AM/PM: e.g. "9:30 AM", "09:30pm", "9:00:00 AM"
      final ampmMatch = RegExp(
        r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(am|pm)$',
        caseSensitive: false,
      ).firstMatch(s);
      if (ampmMatch != null) {
        var h = int.parse(ampmMatch.group(1)!);
        final min = int.parse(ampmMatch.group(2)!);
        final isPm = ampmMatch.group(3)!.toLowerCase() == 'pm';
        if (isPm && h < 12) h += 12;
        if (!isPm && h == 12) h = 0;
        return (h, min);
      }

      // 24-hour time: "09:00", "09:00:00", "9:00"
      final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(s);
      if (timeMatch != null && !s.contains('T') && !s.contains('-')) {
        final h = int.parse(timeMatch.group(1)!);
        final min = int.parse(timeMatch.group(2)!);
        if (h >= 0 && h < 24 && min >= 0 && min < 60) {
          return (h, min);
        }
      }

      // Full ISO date-time string: "2026-10-14T09:00:00.000Z" or "2026-10-14 09:00:00"
      final dt = DateTime.tryParse(s);
      if (dt != null) {
        final local = dt.toLocal();
        return (local.hour, local.minute);
      }

      return null;
    }

    // If no explicit date was provided, and directStart is already a full ISO date-time:
    if (!hasExplicitDate && directStart != null) {
      final endTime = directEnd ?? directStart.add(const Duration(hours: 1));
      final resolvedDate =
          '${directStart.year.toString().padLeft(4, '0')}-${directStart.month.toString().padLeft(2, '0')}-${directStart.day.toString().padLeft(2, '0')}';
      return (directStart, endTime, resolvedDate);
    }

    // 1. Determine target calendar date
    int? year;
    int? month;
    int? day;
    String? resolvedDateStr;

    if (hasExplicitDate) {
      final match = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(dateStr);
      if (match != null) {
        year = int.tryParse(match.group(1)!);
        month = int.tryParse(match.group(2)!);
        day = int.tryParse(match.group(3)!);
      } else {
        final dt = DateTime.tryParse(dateStr);
        if (dt != null) {
          final local = dt.toLocal();
          year = local.year;
          month = local.month;
          day = local.day;
        }
      }
      if (year != null && month != null && day != null) {
        resolvedDateStr =
            '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
    }

    // Fallback: extract date from directStart if not yet resolved
    if (year == null || month == null || day == null) {
      if (directStart != null) {
        year = directStart.year;
        month = directStart.month;
        day = directStart.day;
      } else if (startStr != null) {
        final match = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(startStr);
        if (match != null) {
          year = int.tryParse(match.group(1)!);
          month = int.tryParse(match.group(2)!);
          day = int.tryParse(match.group(3)!);
        }
      }
    }

    // Fallback to today if no date found
    if (year == null || month == null || day == null) {
      final now = DateTime.now();
      year = now.year;
      month = now.month;
      day = now.day;
    }

    resolvedDateStr ??=
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    // If explicit date matches directStart's calendar date, preserve directStart
    if (hasExplicitDate && directStart != null) {
      if (directStart.year == year &&
          directStart.month == month &&
          directStart.day == day) {
        final endTime = directEnd ?? directStart.add(const Duration(hours: 1));
        return (directStart, endTime, resolvedDateStr);
      }
    }

    // Construct startTime from parsed hours and minutes
    final startHm = parseHourMinute(startStr);
    final startTime = startHm != null
        ? DateTime(year, month, day, startHm.$1, startHm.$2)
        : (directStart ?? DateTime(year, month, day, 9, 0));

    // Construct endTime
    final endHm = parseHourMinute(endStr);
    DateTime endTime;
    if (endHm != null) {
      endTime = DateTime(year, month, day, endHm.$1, endHm.$2);
      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }
    } else if (directEnd != null) {
      endTime = directEnd;
    } else {
      endTime = startTime.add(const Duration(hours: 1));
    }

    return (startTime, endTime, resolvedDateStr);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date ??
        '${startTime.year.toString().padLeft(4, '0')}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}',
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    if (categoryId != null) 'categoryId': categoryId,
    if (categoryModel != null) 'category': categoryModel!.toJson(),
    if (location.isNotEmpty) 'location': location,
    if (color != null) 'color': color,
    'status': status,
    if (userEmail != null) 'userEmail': userEmail,
    'applicationName': applicationName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? date,
    String? categoryId,
    CalendarCategory? categoryModel,
    String? location,
    String? color,
    String? status,
    String? userEmail,
    String? applicationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryModel: categoryModel ?? this.categoryModel,
      location: location ?? this.location,
      color: color ?? this.color,
      status: status ?? this.status,
      userEmail: userEmail ?? this.userEmail,
      applicationName: applicationName ?? this.applicationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ startTime.hashCode ^ endTime.hashCode;

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, date: $formattedDate, start: $startTime, end: $endTime)';
}

/// Strongly-typed model for calendar reminders.
@immutable
class CalendarReminder {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String status;
  final String? repeatType;
  final String? categoryId;
  final CalendarCategory? category;
  final String? userEmail;
  final String applicationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalendarReminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    this.status = 'pending',
    this.repeatType = 'none',
    this.categoryId,
    this.category,
    this.userEmail,
    this.applicationName = 'Bit Tool',
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory CalendarReminder.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    String parseDateStr(dynamic v) {
      if (v == null) return '';
      final str = v.toString();
      if (str.length >= 10) return str.substring(0, 10);
      return str;
    }

    CalendarCategory? cat;
    if (json['category'] is Map<String, dynamic>) {
      cat = CalendarCategory.fromJson(json['category'] as Map<String, dynamic>);
    }

    return CalendarReminder(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: parseDateStr(json['date']),
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      repeatType: json['repeatType']?.toString() ?? 'none',
      categoryId: json['categoryId']?.toString() ?? cat?.id,
      category: cat,
      userEmail: json['userEmail']?.toString(),
      applicationName: json['applicationName']?.toString() ?? 'Bit Tool',
      createdAt: parseNullableDate(json['createdAt']),
      updatedAt: parseNullableDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'time': time,
    'status': status,
    'repeatType': repeatType,
    if (categoryId != null) 'categoryId': categoryId,
    if (category != null) 'category': category!.toJson(),
    if (userEmail != null) 'userEmail': userEmail,
    'applicationName': applicationName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  CalendarReminder copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? status,
    String? repeatType,
    String? categoryId,
    CalendarCategory? category,
    String? userEmail,
    String? applicationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      repeatType: repeatType ?? this.repeatType,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      userEmail: userEmail ?? this.userEmail,
      applicationName: applicationName ?? this.applicationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarReminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'CalendarReminder(id: $id, title: $title, date: $date, status: $status)';
}

/// Strongly-typed model for calendar date-linked notes.
@immutable
class CalendarDateNote {
  final String id;
  final String title;
  final String content;
  final String date;
  final String? categoryId;
  final CalendarCategory? category;
  final String? userEmail;
  final String applicationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalendarDateNote({
    required this.id,
    required this.title,
    this.content = '',
    required this.date,
    this.categoryId,
    this.category,
    this.userEmail,
    this.applicationName = 'Bit Tool',
    this.createdAt,
    this.updatedAt,
  });

  factory CalendarDateNote.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    String parseDateStr(dynamic v) {
      if (v == null) return '';
      final str = v.toString();
      if (str.length >= 10) return str.substring(0, 10);
      return str;
    }

    CalendarCategory? cat;
    if (json['category'] is Map<String, dynamic>) {
      cat = CalendarCategory.fromJson(json['category'] as Map<String, dynamic>);
    }

    return CalendarDateNote(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      date: parseDateStr(json['date']),
      categoryId: json['categoryId']?.toString() ?? cat?.id,
      category: cat,
      userEmail: json['userEmail']?.toString(),
      applicationName: json['applicationName']?.toString() ?? 'Bit Tool',
      createdAt: parseNullableDate(json['createdAt']),
      updatedAt: parseNullableDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date,
    if (categoryId != null) 'categoryId': categoryId,
    if (category != null) 'category': category!.toJson(),
    if (userEmail != null) 'userEmail': userEmail,
    'applicationName': applicationName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  CalendarDateNote copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? categoryId,
    CalendarCategory? category,
    String? userEmail,
    String? applicationName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarDateNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      userEmail: userEmail ?? this.userEmail,
      applicationName: applicationName ?? this.applicationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDateNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;

  @override
  String toString() =>
      'CalendarDateNote(id: $id, title: $title, date: $date)';
}

/// Strongly-typed model for global calendar search results.
@immutable
class CalendarSearchResult {
  final List<CalendarEvent> events;
  final List<CalendarDateNote> notes;
  final List<CalendarReminder> reminders;

  const CalendarSearchResult({
    this.events = const [],
    this.notes = const [],
    this.reminders = const [],
  });

  const CalendarSearchResult.empty()
      : events = const [],
        notes = const [],
        reminders = const [];

  bool get isEmpty => events.isEmpty && notes.isEmpty && reminders.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory CalendarSearchResult.fromJson(Map<String, dynamic> json) {
    List<CalendarEvent> parseEvents(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map(CalendarEvent.fromJson)
            .toList();
      }
      return const [];
    }

    List<CalendarDateNote> parseNotes(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map(CalendarDateNote.fromJson)
            .toList();
      }
      return const [];
    }

    List<CalendarReminder> parseReminders(dynamic v) {
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map(CalendarReminder.fromJson)
            .toList();
      }
      return const [];
    }

    return CalendarSearchResult(
      events: parseEvents(json['events']),
      notes: parseNotes(json['notes']),
      reminders: parseReminders(json['reminders']),
    );
  }
}

/// Represents a holiday or official leave day on the calendar.
@immutable
class CalendarHoliday {
  final String name;
  final DateTime date;
  final bool isLeave;

  const CalendarHoliday({
    required this.name,
    required this.date,
    this.isLeave = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarHoliday &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => name.hashCode ^ date.year ^ date.month ^ date.day;

  @override
  String toString() => 'CalendarHoliday(name: $name, date: $date)';
}

/// Dynamic algorithm to compute holidays and standard calendar leaves for any year and month.
/// No hardcoded dates are used — dates are dynamically calculated for any month and year.
class HolidayHelper {
  static List<CalendarHoliday> getLeavesForMonth(int year, int month) {
    final leaves = <CalendarHoliday>[];

    // Helper: find nth occurrence of weekday in month (1 = Monday, ..., 7 = Sunday)
    DateTime? nthWeekday(int weekday, int n) {
      int count = 0;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final d = DateTime(year, month, day);
        if (d.weekday == weekday) {
          count++;
          if (count == n) return d;
        }
      }
      return null;
    }

    // Helper: find last occurrence of weekday in month
    DateTime? lastWeekday(int weekday) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = daysInMonth; day >= 1; day--) {
        final d = DateTime(year, month, day);
        if (d.weekday == weekday) return d;
      }
      return null;
    }

    switch (month) {
      case 1:
        leaves.add(CalendarHoliday(name: "New Year's Day", date: DateTime(year, 1, 1)));
        final mlk = nthWeekday(DateTime.monday, 3);
        if (mlk != null) {
          leaves.add(CalendarHoliday(name: 'MLK Day', date: mlk));
        }
        break;

      case 2:
        final pres = nthWeekday(DateTime.monday, 3);
        if (pres != null) {
          leaves.add(CalendarHoliday(name: "Presidents' Day", date: pres));
        }
        break;

      case 3:
        leaves.add(CalendarHoliday(name: "Women's Day", date: DateTime(year, 3, 8)));
        break;

      case 4:
        leaves.add(CalendarHoliday(name: 'Earth Day', date: DateTime(year, 4, 22)));
        break;

      case 5:
        leaves.add(CalendarHoliday(name: 'Labor Day', date: DateTime(year, 5, 1)));
        final mem = lastWeekday(DateTime.monday);
        if (mem != null) {
          leaves.add(CalendarHoliday(name: 'Memorial Day', date: mem));
        }
        break;

      case 6:
        leaves.add(CalendarHoliday(name: 'Juneteenth', date: DateTime(year, 6, 19)));
        break;

      case 7:
        leaves.add(CalendarHoliday(name: 'Independence Day', date: DateTime(year, 7, 4)));
        break;

      case 9:
        final labor = nthWeekday(DateTime.monday, 1);
        if (labor != null) {
          leaves.add(CalendarHoliday(name: 'Labor Day', date: labor));
        }
        break;

      case 10:
        // Columbus Day is 2nd Monday of October (e.g. Oct 12, 2026)
        final columbus = nthWeekday(DateTime.monday, 2);
        if (columbus != null) {
          leaves.add(CalendarHoliday(name: 'Columbus Day', date: columbus));
        }
        // Halloween is October 31
        leaves.add(CalendarHoliday(name: 'Halloween', date: DateTime(year, 10, 31)));
        break;

      case 11:
        leaves.add(CalendarHoliday(name: 'Veterans Day', date: DateTime(year, 11, 11)));
        final thanks = nthWeekday(DateTime.thursday, 4);
        if (thanks != null) {
          leaves.add(CalendarHoliday(name: 'Thanksgiving', date: thanks));
        }
        break;

      case 12:
        leaves.add(CalendarHoliday(name: 'Christmas Eve', date: DateTime(year, 12, 24)));
        leaves.add(CalendarHoliday(name: 'Christmas Day', date: DateTime(year, 12, 25)));
        leaves.add(CalendarHoliday(name: "New Year's Eve", date: DateTime(year, 12, 31)));
        break;
    }

    return leaves;
  }
}
