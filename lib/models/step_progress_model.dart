import 'package:cloud_firestore/cloud_firestore.dart';

class StepProgressModel {
  final String id;
  final String checklistItemId;
  final String stepId;
  final bool completed;
  final DateTime? completedAt;
  final String? completedBy;
  final String environment; // 'home' atau 'school'

  StepProgressModel({
    required this.id,
    required this.checklistItemId,
    required this.stepId,
    required this.completed,
    this.completedAt,
    this.completedBy,
    required this.environment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'checklistItemId': checklistItemId,
      'stepId': stepId,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'environment': environment,
    };
  }

  factory StepProgressModel.fromMap(Map<String, dynamic> map) {
    return StepProgressModel(
      id: map['id'] ?? '',
      checklistItemId: map['checklistItemId'] ?? '',
      stepId: map['stepId'] ?? '',
      completed: map['completed'] ?? false,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
      completedBy: map['completedBy'],
      environment: map['environment'] ?? 'home',
    );
  }

  StepProgressModel copyWith({
    bool? completed,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return StepProgressModel(
      id: this.id,
      checklistItemId: this.checklistItemId,
      stepId: this.stepId,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      environment: this.environment,
    );
  }
}
