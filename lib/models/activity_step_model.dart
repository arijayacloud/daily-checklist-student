import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityStepModel {
  final String id;
  final String activityId;
  final int stepNumber;
  final String title;
  final String description;
  final int estimatedTimeMinutes;

  ActivityStepModel({
    required this.id,
    required this.activityId,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.estimatedTimeMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'estimatedTimeMinutes': estimatedTimeMinutes,
    };
  }

  factory ActivityStepModel.fromMap(Map<String, dynamic> map) {
    return ActivityStepModel(
      id: map['id'] ?? '',
      activityId: map['activityId'] ?? '',
      stepNumber: map['stepNumber'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      estimatedTimeMinutes: map['estimatedTimeMinutes'] ?? 0,
    );
  }

  ActivityStepModel copyWith({
    String? title,
    String? description,
    int? stepNumber,
    int? estimatedTimeMinutes,
  }) {
    return ActivityStepModel(
      id: this.id,
      activityId: this.activityId,
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
    );
  }
}
