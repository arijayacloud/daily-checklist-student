import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String name;
  final int age;
  final String parentId;
  final String teacherId;
  final String avatarUrl;
  final DateTime createdAt;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.parentId,
    required this.teacherId,
    required this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'parentId': parentId,
      'teacherId': teacherId,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      parentId: map['parentId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
