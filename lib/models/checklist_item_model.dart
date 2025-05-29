import 'package:cloud_firestore/cloud_firestore.dart';

enum ChecklistStatus { pending, partial, complete }

class CompletionStatus {
  final bool completed;
  final DateTime? completedAt;
  final String? notes;
  final String? completedBy;
  final String? photoUrl;
  final int? engagement; // Tingkat keterlibatan 1-5
  final int? duration; // Durasi dalam menit
  final String? processNotes; // Catatan proses
  final String? learningOutcomes; // Hasil pembelajaran (khusus guru)

  CompletionStatus({
    this.completed = false,
    this.completedAt,
    this.notes,
    this.completedBy,
    this.photoUrl,
    this.engagement,
    this.duration,
    this.processNotes,
    this.learningOutcomes,
  });

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'completedBy': completedBy,
      'photoUrl': photoUrl,
      'engagement': engagement,
      'duration': duration,
      'processNotes': processNotes,
      'learningOutcomes': learningOutcomes,
    };
  }

  factory CompletionStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CompletionStatus();

    return CompletionStatus(
      completed: map['completed'] ?? false,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
      notes: map['notes'],
      completedBy: map['completedBy'],
      photoUrl: map['photoUrl'],
      engagement: map['engagement'],
      duration: map['duration'],
      processNotes: map['processNotes'],
      learningOutcomes: map['learningOutcomes'],
    );
  }

  CompletionStatus copyWith({
    bool? completed,
    DateTime? completedAt,
    String? notes,
    String? completedBy,
    String? photoUrl,
    int? engagement,
    int? duration,
    String? processNotes,
    String? learningOutcomes,
  }) {
    return CompletionStatus(
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      completedBy: completedBy ?? this.completedBy,
      photoUrl: photoUrl ?? this.photoUrl,
      engagement: engagement ?? this.engagement,
      duration: duration ?? this.duration,
      processNotes: processNotes ?? this.processNotes,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
    );
  }
}

class ChecklistItemModel {
  final String id;
  final String childId;
  final String activityId;
  final DateTime assignedDate;
  final DateTime dueDate;
  final CompletionStatus homeStatus;
  final CompletionStatus schoolStatus;
  final String overallStatus; // 'pending', 'partial', 'complete'
  final List<String> customStepsUsed; // ID guru yang langkahnya digunakan

  ChecklistItemModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.assignedDate,
    required this.dueDate,
    required this.homeStatus,
    required this.schoolStatus,
    required this.overallStatus,
    this.customStepsUsed = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'activityId': activityId,
      'assignedDate': assignedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'homeStatus': homeStatus.toMap(),
      'schoolStatus': schoolStatus.toMap(),
      'overallStatus': overallStatus,
      'customStepsUsed': customStepsUsed,
    };
  }

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      activityId: map['activityId'] ?? '',
      assignedDate: DateTime.parse(map['assignedDate']),
      dueDate: DateTime.parse(map['dueDate']),
      homeStatus: CompletionStatus.fromMap(map['homeStatus']),
      schoolStatus: CompletionStatus.fromMap(map['schoolStatus']),
      overallStatus: map['overallStatus'] ?? 'pending',
      customStepsUsed:
          map['customStepsUsed'] != null
              ? List<String>.from(map['customStepsUsed'])
              : [],
    );
  }

  ChecklistItemModel copyWith({
    CompletionStatus? homeStatus,
    CompletionStatus? schoolStatus,
    String? overallStatus,
    List<String>? customStepsUsed,
  }) {
    return ChecklistItemModel(
      id: this.id,
      childId: this.childId,
      activityId: this.activityId,
      assignedDate: this.assignedDate,
      dueDate: this.dueDate,
      homeStatus: homeStatus ?? this.homeStatus,
      schoolStatus: schoolStatus ?? this.schoolStatus,
      overallStatus: overallStatus ?? this.overallStatus,
      customStepsUsed: customStepsUsed ?? this.customStepsUsed,
    );
  }

  // Helper method untuk menentukan status keseluruhan
  static String calculateOverallStatus(
    CompletionStatus homeStatus,
    CompletionStatus schoolStatus,
    String environment,
  ) {
    if (environment == 'both') {
      if (homeStatus.completed && schoolStatus.completed) {
        return 'complete';
      } else if (homeStatus.completed || schoolStatus.completed) {
        return 'partial';
      }
      return 'pending';
    } else if (environment == 'home') {
      return homeStatus.completed ? 'complete' : 'pending';
    } else {
      // environment == 'school'
      return schoolStatus.completed ? 'complete' : 'pending';
    }
  }
}
