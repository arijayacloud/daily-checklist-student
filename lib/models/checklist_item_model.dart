import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationModel {
  final bool completed;
  final Timestamp? completedAt;
  final int? duration; // in minutes
  final int? engagement; // 1-5 stars
  final String? notes;
  final String? learningOutcomes; // only for school observations

  ObservationModel({
    required this.completed,
    this.completedAt,
    this.duration,
    this.engagement,
    this.notes,
    this.learningOutcomes,
  });

  factory ObservationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ObservationModel(completed: false);
    }

    return ObservationModel(
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'],
      duration: json['duration'],
      engagement: json['engagement'],
      notes: json['notes'],
      learningOutcomes: json['learningOutcomes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'completedAt': completedAt,
      'duration': duration,
      'engagement': engagement,
      'notes': notes,
      'learningOutcomes': learningOutcomes,
    };
  }
}

class ChecklistItemModel {
  final String id;
  final String childId;
  final String activityId;
  final Timestamp assignedDate;
  final Timestamp? dueDate;
  final String status; // 'pending', 'in-progress', 'completed'
  final ObservationModel homeObservation;
  final ObservationModel schoolObservation;
  final List<String> customStepsUsed; // Which teacher's steps were used

  ChecklistItemModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.assignedDate,
    this.dueDate,
    required this.status,
    required this.homeObservation,
    required this.schoolObservation,
    required this.customStepsUsed,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      activityId: json['activityId'] ?? '',
      assignedDate: json['assignedDate'] ?? Timestamp.now(),
      dueDate: json['dueDate'],
      status: json['status'] ?? 'pending',
      homeObservation: ObservationModel.fromJson(json['homeObservation']),
      schoolObservation: ObservationModel.fromJson(json['schoolObservation']),
      customStepsUsed: List<String>.from(json['customStepsUsed'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'activityId': activityId,
      'assignedDate': assignedDate,
      'dueDate': dueDate,
      'status': status,
      'homeObservation': homeObservation.toJson(),
      'schoolObservation': schoolObservation.toJson(),
      'customStepsUsed': customStepsUsed,
    };
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == 'completed') return false;
    return dueDate!.toDate().isBefore(DateTime.now());
  }

  bool get isCompleted {
    return status == 'completed' ||
        homeObservation.completed ||
        schoolObservation.completed;
  }

  bool get isInProgress {
    return status == 'in-progress';
  }

  String get statusIcon {
    if (isCompleted) return '✓';
    if (isOverdue) return '⚠️';
    if (isInProgress) return '🔄';
    return '⏱️';
  }
}
