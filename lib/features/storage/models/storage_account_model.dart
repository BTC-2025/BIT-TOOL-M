import 'package:flutter/material.dart';

/// User account data representation for the Storage Suite.
class StorageAccountModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final Color avatarColor;

  const StorageAccountModel({
    this.id = '',
    this.name = '',
    this.email = '',
    this.avatarUrl,
    this.avatarColor = const Color(0xFF6366F1),
  });

  String get avatarLetter => name.isNotEmpty ? name[0].toUpperCase() : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

  factory StorageAccountModel.fromJson(Map<String, dynamic> json) {
    return StorageAccountModel(
      id: json['id']?.toString() ?? 'user_1',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      avatarColor: const Color(0xFF6366F1),
    );
  }

  StorageAccountModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    Color? avatarColor,
  }) {
    return StorageAccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}
