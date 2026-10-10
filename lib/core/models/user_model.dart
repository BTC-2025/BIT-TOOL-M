import 'package:flutter/foundation.dart';

/// Model representing an organization associated with a user.
@immutable
class OrganizationModel {
  final int id;
  final String name;

  const OrganizationModel({required this.id, required this.name});

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = (rawId is num)
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final name = json['name']?.toString() ?? '';

    return OrganizationModel(id: id, name: name);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Strongly typed model representing the currently authenticated user.
@immutable
class UserModel {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? profilePictureUrl;
  final String? role;
  final String? accountType;
  final num? storageUsed;
  final num? storageLimit;
  final bool isPrimary;
  final String? phoneNumber;
  final String? recoveryEmail;
  final String? dob;
  final OrganizationModel? organization;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.profilePictureUrl,
    this.role,
    this.accountType,
    this.storageUsed,
    this.storageLimit,
    this.isPrimary = false,
    this.phoneNumber,
    this.recoveryEmail,
    this.dob,
    this.organization,
  });

  /// Constructs a [UserModel] safely from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = (rawId is num)
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawIsPrimary = json['isPrimary'];
    final isPrimary = rawIsPrimary is bool
        ? rawIsPrimary
        : (rawIsPrimary == 1 || rawIsPrimary?.toString() == 'true');

    OrganizationModel? org;
    if (json['organization'] is Map<String, dynamic>) {
      org = OrganizationModel.fromJson(
        json['organization'] as Map<String, dynamic>,
      );
    }

    final rawPic =
        json['profilePictureUrl'] ??
        json['profile_picture_url'] ??
        json['avatarUrl'] ??
        json['avatar_url'] ??
        json['avatar'] ??
        json['photo'] ??
        json['photoUrl'] ??
        json['picture'] ??
        json['image'];
    final profilePic =
        (rawPic != null &&
            rawPic.toString().trim().isNotEmpty &&
            rawPic.toString().trim() != 'null')
        ? rawPic.toString().trim()
        : null;

    return UserModel(
      id: id,
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      fullName: (json['fullName'] ?? json['name'])?.toString(),
      profilePictureUrl: profilePic,
      role: json['role']?.toString(),
      accountType: json['accountType']?.toString(),
      storageUsed: json['storageUsed'] is num
          ? (json['storageUsed'] as num)
          : num.tryParse(json['storageUsed']?.toString() ?? ''),
      storageLimit: json['storageLimit'] is num
          ? (json['storageLimit'] as num)
          : num.tryParse(json['storageLimit']?.toString() ?? ''),
      isPrimary: isPrimary,
      phoneNumber: json['phoneNumber']?.toString(),
      recoveryEmail: json['recoveryEmail']?.toString(),
      dob: json['dob']?.toString(),
      organization: org,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'accountType': accountType,
      'storageUsed': storageUsed,
      'storageLimit': storageLimit,
      'isPrimary': isPrimary,
      'phoneNumber': phoneNumber,
      'recoveryEmail': recoveryEmail,
      'dob': dob,
      'organization': organization?.toJson(),
    };
  }

  /// Returns a clean display name.
  /// Prefers `fullName`, then `firstName + lastName`, then email prefix, never empty or 'null'.
  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    final parts = [firstName, lastName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    if (email.isNotEmpty && email.contains('@')) {
      final nameFromEmail = email.split('@').first.trim();
      if (nameFromEmail.isNotEmpty) {
        return nameFromEmail;
      }
    }
    return email.isNotEmpty ? email : 'User';
  }

  /// Fallback initials (1-2 characters uppercase).
  String get initials {
    final f = firstName?.trim();
    final l = lastName?.trim();
    if (f != null && f.isNotEmpty && l != null && l.isNotEmpty) {
      return '${f[0]}${l[0]}'.toUpperCase();
    }

    final name = displayName.trim();
    if (name.isNotEmpty) {
      final tokens = name
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (tokens.length >= 2) {
        return '${tokens[0][0]}${tokens[1][0]}'.toUpperCase();
      }
      return tokens[0][0].toUpperCase();
    }
    return 'U';
  }

  /// Whether profilePictureUrl is non-null and valid.
  bool get hasValidProfilePicture {
    if (profilePictureUrl == null) return false;
    final url = profilePictureUrl!.trim();
    if (url.isEmpty ||
        url.toLowerCase() == 'null' ||
        url.toLowerCase() == 'undefined') {
      return false;
    }
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('data:') ||
        url.startsWith('base64,') ||
        url.startsWith('blob:') ||
        url.startsWith('assets/') ||
        url.startsWith('/') ||
        url.contains('.');
  }

  /// Returns the fully qualified URL for network images, or raw data URL for base64 images.
  String? get resolvedProfilePictureUrl {
    if (!hasValidProfilePicture) return null;
    final url = profilePictureUrl!.trim();
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('data:') ||
        url.startsWith('base64,') ||
        url.startsWith('blob:') ||
        url.startsWith('assets/')) {
      return url;
    }
    if (url.startsWith('/')) {
      return 'https://api.bnxmail.com$url';
    }
    return 'https://api.bnxmail.com/$url';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          profilePictureUrl == other.profilePictureUrl &&
          role == other.role &&
          accountType == other.accountType &&
          storageUsed == other.storageUsed &&
          storageLimit == other.storageLimit &&
          isPrimary == other.isPrimary &&
          organization == other.organization;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    fullName,
    profilePictureUrl,
    role,
    accountType,
    storageUsed,
    storageLimit,
    isPrimary,
    organization,
  );
}
