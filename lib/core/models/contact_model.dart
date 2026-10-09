import 'package:flutter/foundation.dart';

/// Strongly-typed model for contacts returned by or sent to the backend Contacts API.
@immutable
class ContactModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String company;
  final String notes;
  final String role;
  final String department;
  final String location;
  final String photoUrl;
  final String applicationName;
  final bool isFavorite;
  final bool isBlocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ContactModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.company = '',
    this.notes = '',
    this.role = '',
    this.department = '',
    this.location = '',
    this.photoUrl = '',
    this.applicationName = '',
    this.isFavorite = false,
    this.isBlocked = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed full name combining firstName and lastName.
  String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '$first $last';
    } else if (first.isNotEmpty) {
      return first;
    } else if (last.isNotEmpty) {
      return last;
    }
    if (email.trim().isNotEmpty) return email.trim();
    if (phone.trim().isNotEmpty) return phone.trim();
    return 'Unnamed Contact';
  }

  /// Compatibility alias for widgets expecting `name`.
  String get name => fullName;

  /// Compatibility alias for widgets expecting `designation`.
  String get designation => role.isNotEmpty ? role : company;

  /// Single letter uppercase initial for table avatar badge.
  String get initial {
    final clean = fullName.trim();
    if (clean.isNotEmpty && clean != 'Unnamed Contact') {
      return clean[0].toUpperCase();
    }
    return '?';
  }

  /// Splits a single user-entered full name string into firstName and lastName components.
  /// Example: 'John Michael Doe' -> firstName: 'John', lastName: 'Michael Doe'.
  static (String, String) parseFullName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ('', '');
    }
    final tokens = trimmed.split(RegExp(r'\s+'));
    if (tokens.length == 1) {
      return (tokens.first, '');
    }
    final first = tokens.first;
    final last = tokens.sublist(1).join(' ');
    return (first, last);
  }

  /// Constructs a [ContactModel] from backend JSON.
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    String cleanString(dynamic value) {
      if (value == null) return '';
      final str = value.toString().trim();
      if (str.toLowerCase() == 'null') return '';
      return str;
    }

    var first = cleanString(json['firstName']);
    var last = cleanString(json['lastName']);

    // If firstName/lastName are absent but fullName/name exists, parse them
    if (first.isEmpty && last.isEmpty) {
      final compositeName = cleanString(json['fullName'] ?? json['name']);
      if (compositeName.isNotEmpty) {
        final (pFirst, pLast) = parseFullName(compositeName);
        first = pFirst;
        last = pLast;
      }
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        final str = value.toString().trim();
        if (str.isEmpty || str.toLowerCase() == 'null') return null;
        return DateTime.tryParse(str);
      } catch (_) {
        return null;
      }
    }

    return ContactModel(
      id: cleanString(
        json['id'] ?? json['_id'] ?? json['contactId'],
      ),
      firstName: first,
      lastName: last,
      email: cleanString(json['email']),
      phone: cleanString(
        json['phone'] ?? json['phoneNumber'] ?? json['phonenumber'],
      ),
      company: cleanString(json['company'] ?? json['companyName']),
      notes: cleanString(json['notes'] ?? json['note']),
      role: cleanString(json['role'] ?? json['designation']),
      department: cleanString(json['department']),
      location: cleanString(json['location']),
      photoUrl: cleanString(json['photoUrl'] ?? json['avatar']),
      applicationName: cleanString(
        json['applicationName'] ?? json['appName'] ?? json['application'],
      ),
      isFavorite: json['isFavorite'] == true,
      isBlocked: json['isBlocked'] == true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  /// Request body payload conforming to the documented backend POST /add and PUT /update schema:
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "email": "string",
  ///   "phone": "string",
  ///   "company": "string",
  ///   "notes": "string"
  /// }
  Map<String, dynamic> toApiBody() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'company': company.trim(),
      'notes': notes.trim(),
    };
  }

  /// Verified payload format enforced by the live Sequelize backend:
  /// {
  ///   "name": "string",
  ///   "email": "string",
  ///   "phonenumber": "string",
  ///   "role": "string" (optional)
  /// }
  Map<String, dynamic> toBackendBody() {
    return {
      'name': fullName,
      'email': email.trim(),
      'phonenumber': phone.trim(),
      if (role.trim().isNotEmpty) 'role': role.trim(),
    };
  }

  /// Full serialization for local persistence or testing.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'company': company,
      'notes': notes,
      'role': role,
      'department': department,
      'location': location,
      'photoUrl': photoUrl,
      'applicationName': applicationName,
      'isFavorite': isFavorite,
      'isBlocked': isBlocked,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ContactModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? role,
    String? department,
    String? location,
    String? photoUrl,
    String? applicationName,
    bool? isFavorite,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      role: role ?? this.role,
      department: department ?? this.department,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      applicationName: applicationName ?? this.applicationName,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          email == other.email &&
          phone == other.phone &&
          company == other.company &&
          notes == other.notes &&
          role == other.role &&
          applicationName == other.applicationName;

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    email,
    phone,
    company,
    notes,
    role,
    applicationName,
  );
}

/// Metadata describing paginated results from GET /get.
@immutable
class ContactPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const ContactPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 1,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory ContactPagination.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    final page = parseInt(
      json['page'] ?? json['currentPage'] ?? json['current_page'],
      1,
    );
    final limit = parseInt(
      json['limit'] ??
          json['pageSize'] ??
          json['page_size'] ??
          json['perPage'] ??
          json['per_page'],
      20,
    );
    final total = parseInt(
      json['total'] ??
          json['totalRecords'] ??
          json['total_records'] ??
          json['count'] ??
          json['totalCount'],
      0,
    );
    final calculatedPages = limit > 0 && total > 0 ? (total / limit).ceil() : 1;
    final totalPages = parseInt(
      json['totalPages'] ?? json['total_pages'],
      calculatedPages,
    );

    return ContactPagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'limit': limit,
    'total': total,
    'totalPages': totalPages,
  };
}

/// Container for contacts and accompanying pagination metadata.
@immutable
class PaginatedContactsResult {
  final List<ContactModel> contacts;
  final ContactPagination pagination;

  const PaginatedContactsResult({
    required this.contacts,
    required this.pagination,
  });
}
