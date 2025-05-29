import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityEnvironment { home, school, both }

enum DifficultyLevel { easy, medium, hard }

class AgeRange {
  final int min;
  final int max;

  AgeRange({required this.min, required this.max});

  Map<String, dynamic> toMap() {
    return {'min': min, 'max': max};
  }

  factory AgeRange.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return AgeRange(min: 3, max: 6);
    }
    return AgeRange(min: map['min'] ?? 3, max: map['max'] ?? 6);
  }
}

class CustomStep {
  final String teacherId;
  final List<String> steps;

  CustomStep({required this.teacherId, required this.steps});

  Map<String, dynamic> toMap() {
    return {'teacherId': teacherId, 'steps': steps};
  }

  factory CustomStep.fromMap(Map<String, dynamic> map) {
    return CustomStep(
      teacherId: map['teacherId'] ?? '',
      steps: List<String>.from(map['steps'] ?? []),
    );
  }
}

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String environment; // 'home', 'school', 'both'
  final String difficulty;
  final String teacherId;
  final DateTime createdAt;
  final AgeRange ageRange;
  final String? nextActivityId;
  final List<CustomStep> customSteps;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.environment,
    required this.difficulty,
    required this.teacherId,
    required this.createdAt,
    required this.ageRange,
    this.nextActivityId,
    required this.customSteps,
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
      'ageRange': ageRange.toMap(),
      'nextActivityId': nextActivityId,
      'customSteps': customSteps.map((step) => step.toMap()).toList(),
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
      ageRange: AgeRange.fromMap(map['ageRange']),
      nextActivityId: map['nextActivityId'],
      customSteps:
          map['customSteps'] != null
              ? List<CustomStep>.from(
                map['customSteps']?.map((x) => CustomStep.fromMap(x)) ?? [],
              )
              : [],
    );
  }

  ActivityModel copyWith({
    String? title,
    String? description,
    String? environment,
    String? difficulty,
    AgeRange? ageRange,
    String? nextActivityId,
    List<CustomStep>? customSteps,
  }) {
    return ActivityModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      environment: environment ?? this.environment,
      difficulty: difficulty ?? this.difficulty,
      teacherId: this.teacherId,
      createdAt: this.createdAt,
      ageRange: ageRange ?? this.ageRange,
      nextActivityId: nextActivityId ?? this.nextActivityId,
      customSteps: customSteps ?? this.customSteps,
    );
  }
}
