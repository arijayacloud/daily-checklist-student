class ChecklistModel {
  final String id;
  final String childId;
  final String activityId;
  final DateTime assignedDate;
  final DateTime? dueDate;
  final String status; // 'pending', 'in-progress', 'completed'
  final List<String> customStepsUsed;
  final HomeObservationModel? homeObservation;
  final SchoolObservationModel? schoolObservation;

  ChecklistModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.assignedDate,
    this.dueDate,
    required this.status,
    required this.customStepsUsed,
    this.homeObservation,
    this.schoolObservation,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    List<String> steps = [];

    if (json['custom_steps_used'] != null) {
      if (json['custom_steps_used'] is List) {
        steps = List<String>.from(json['custom_steps_used']);
      } else if (json['custom_steps_used'] is Map) {
        final Map<String, dynamic> stepsMap = json['custom_steps_used'];
        steps = stepsMap.values.map((v) => v.toString()).toList();
      }
    }

    return ChecklistModel(
      id: json['id'].toString(),
      childId: json['child_id'].toString(),
      activityId: json['activity_id'].toString(),
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'])
          : DateTime.now(),
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      status: json['status'] ?? 'pending',
      customStepsUsed: steps,
      homeObservation: json['home_observation'] != null
          ? HomeObservationModel.fromJson(json['home_observation'])
          : null,
      schoolObservation: json['school_observation'] != null
          ? SchoolObservationModel.fromJson(json['school_observation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'activity_id': activityId,
      'assigned_date': assignedDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'status': status,
      'custom_steps_used': customStepsUsed,
      if (homeObservation != null)
        'home_observation': homeObservation!.toJson(),
      if (schoolObservation != null)
        'school_observation': schoolObservation!.toJson(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in-progress';

  bool get isHomeObservationCompleted => homeObservation?.completed ?? false;
  bool get isSchoolObservationCompleted =>
      schoolObservation?.completed ?? false;
}

class HomeObservationModel {
  final String id;
  final String checklistId;
  final bool completed;
  final DateTime? completedAt;
  final int? duration; // in minutes
  final int? engagement; // 1-5
  final String? notes;

  HomeObservationModel({
    required this.id,
    required this.checklistId,
    required this.completed,
    this.completedAt,
    this.duration,
    this.engagement,
    this.notes,
  });

  factory HomeObservationModel.fromJson(Map<String, dynamic> json) {
    return HomeObservationModel(
      id: json['id'].toString(),
      checklistId: json['checklist_id'].toString(),
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      duration: json['duration'],
      engagement: json['engagement'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'duration': duration,
      'engagement': engagement,
      'notes': notes,
    };
  }
}

class SchoolObservationModel {
  final String id;
  final String checklistId;
  final bool completed;
  final DateTime? completedAt;
  final int? duration; // in minutes
  final int? engagement; // 1-5
  final String? notes;
  final String? learningOutcomes;

  SchoolObservationModel({
    required this.id,
    required this.checklistId,
    required this.completed,
    this.completedAt,
    this.duration,
    this.engagement,
    this.notes,
    this.learningOutcomes,
  });

  factory SchoolObservationModel.fromJson(Map<String, dynamic> json) {
    return SchoolObservationModel(
      id: json['id'].toString(),
      checklistId: json['checklist_id'].toString(),
      completed: json['completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      duration: json['duration'],
      engagement: json['engagement'],
      notes: json['notes'],
      learningOutcomes: json['learning_outcomes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklist_id': checklistId,
      'completed': completed,
      'completed_at': completedAt?.toIso8601String(),
      'duration': duration,
      'engagement': engagement,
      'notes': notes,
      'learning_outcomes': learningOutcomes,
    };
  }
} 