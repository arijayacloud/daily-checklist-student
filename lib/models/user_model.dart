import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { teacher, parent }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'teacher' atau 'parent'
  final String? createdBy;
  final String? tempPassword;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdBy,
    this.tempPassword,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'createdBy': createdBy,
      'tempPassword': tempPassword,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      createdBy: map['createdBy'],
      tempPassword: map['tempPassword'],
      avatarUrl: map['avatarUrl'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
