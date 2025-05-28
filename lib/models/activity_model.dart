import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityEnvironment { home, school, both }

enum DifficultyLevel { easy, medium, hard }

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String environment; // 'home', 'school', 'both'
  final String difficulty;
  final String teacherId;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.environment,
    required this.difficulty,
    required this.teacherId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'environment': environment,
      'difficulty': difficulty,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      environment: map['environment'] ?? 'both',
      difficulty: map['difficulty'] ?? 'easy',
      teacherId: map['teacherId'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
    );
  }

  ActivityModel copyWith({
    String? title,
    String? description,
    String? environment,
    String? difficulty,
  }) {
    return ActivityModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      environment: environment ?? this.environment,
      difficulty: difficulty ?? this.difficulty,
      teacherId: this.teacherId,
      createdAt: this.createdAt,
    );
  }
}
