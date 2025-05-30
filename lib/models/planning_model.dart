import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedActivity {
  final String activityId;
  final Timestamp scheduledDate;
  final String? scheduledTime; // Format: 'HH:MM'
  final bool reminder;
  final bool completed;

  PlannedActivity({
    required this.activityId,
    required this.scheduledDate,
    this.scheduledTime,
    this.reminder = true,
    this.completed = false,
  });

  factory PlannedActivity.fromJson(Map<String, dynamic> json) {
    return PlannedActivity(
      activityId: json['activityId'] ?? '',
      scheduledDate: json['scheduledDate'] ?? Timestamp.now(),
      scheduledTime: json['scheduledTime'],
      reminder: json['reminder'] ?? true,
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'reminder': reminder,
      'completed': completed,
    };
  }
}

class PlanningModel {
  final String id;
  final String teacherId;
  final String type; // 'weekly', 'daily'
  final Timestamp startDate;
  final String? childId; // null means for all children
  final List<PlannedActivity> activities;

  PlanningModel({
    required this.id,
    required this.teacherId,
    required this.type,
    required this.startDate,
    this.childId,
    required this.activities,
  });

  factory PlanningModel.fromJson(Map<String, dynamic> json) {
    return PlanningModel(
      id: json['id'] ?? '',
      teacherId: json['teacherId'] ?? '',
      type: json['type'] ?? 'weekly',
      startDate: json['startDate'] ?? Timestamp.now(),
      childId: json['childId'],
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((activity) => PlannedActivity.fromJson(activity))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'type': type,
      'startDate': startDate,
      'childId': childId,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }

  List<PlannedActivity> getActivitiesForDate(DateTime date) {
    final dateTimestamp = Timestamp.fromDate(
      DateTime(date.year, date.month, date.day),
    );

    return activities.where((activity) {
      final activityDate = activity.scheduledDate.toDate();
      return activityDate.year == date.year &&
          activityDate.month == date.month &&
          activityDate.day == date.day;
    }).toList();
  }
}
