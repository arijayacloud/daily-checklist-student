// Model Planning untuk API Laravel
class Planning {
  final int id;
  final String type;
  final String teacherId;
  final String? childId;
  final DateTime startDate;
  final List<PlannedActivity> activities;

  Planning({
    required this.id,
    required this.type,
    required this.teacherId,
    this.childId,
    required this.startDate,
    required this.activities,
  });

  factory Planning.fromJson(Map<String, dynamic> json) {
    return Planning(
      id: json['id'],
      type: json['type'] ?? 'weekly',
      teacherId: json['teacher_id'] ?? '',
      childId: json['child_id'],
      startDate: DateTime.parse(json['start_date']),
      activities: json['planned_activities'] != null
          ? List<PlannedActivity>.from(
              json['planned_activities'].map((x) => PlannedActivity.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'teacher_id': teacherId,
      'child_id': childId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'activities': activities.map((x) => x.toJson()).toList(),
    };
  }
}

class PlannedActivity {
  final int? id;
  final int planId;
  final int activityId;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final bool reminder;
  final bool completed;

  PlannedActivity({
    this.id,
    required this.planId,
    required this.activityId,
    required this.scheduledDate,
    this.scheduledTime,
    this.reminder = true,
    this.completed = false,
  });

  factory PlannedActivity.fromJson(Map<String, dynamic> json) {
    return PlannedActivity(
      id: json['id'],
      planId: json['plan_id'],
      activityId: json['activity_id'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      reminder: json['reminder'] ?? true,
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'activity_id': activityId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'reminder': reminder,
      'completed': completed,
    };
  }
}
