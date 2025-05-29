import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String name;
  final int age;
  final String parentId;
  final String teacherId;
  final String avatarUrl;
  final DateTime createdAt;
  final String? notes;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.parentId,
    required this.teacherId,
    required this.avatarUrl,
    required this.createdAt,
    this.notes,
  });

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildModel(
      id: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 5,
      parentId: data['parentId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt:
          data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(
                data['createdAt'] ?? DateTime.now().toIso8601String(),
              ),
      notes: data['notes'],
    );
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 5,
      parentId: map['parentId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      createdAt:
          map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(
                map['createdAt'] ?? DateTime.now().toIso8601String(),
              ),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'parentId': parentId,
      'teacherId': teacherId,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  ChildModel copyWith({
    String? id,
    String? name,
    int? age,
    String? parentId,
    String? teacherId,
    String? avatarUrl,
    DateTime? createdAt,
    String? notes,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      parentId: parentId ?? this.parentId,
      teacherId: teacherId ?? this.teacherId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
