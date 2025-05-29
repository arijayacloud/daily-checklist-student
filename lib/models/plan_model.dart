import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanType { daily, weekly }

enum RecurrenceType { once, daily, weekly, monthly }

class PlanActivityModel {
  final String activityId;
  final DateTime scheduledTime;
  final int duration;
  final bool reminder;
  final bool completed;
  final DateTime? completedAt;

  PlanActivityModel({
    required this.activityId,
    required this.scheduledTime,
    required this.duration,
    this.reminder = true,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'duration': duration,
      'reminder': reminder,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PlanActivityModel.fromMap(Map<String, dynamic> map) {
    return PlanActivityModel(
      activityId: map['activityId'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime'] ?? map['time']),
      duration: map['duration'] ?? 0,
      reminder: map['reminder'] ?? true,
      completed: map['completed'] ?? false,
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
    );
  }

  PlanActivityModel copyWith({
    String? activityId,
    DateTime? scheduledTime,
    int? duration,
    bool? reminder,
    bool? completed,
    DateTime? completedAt,
  }) {
    return PlanActivityModel(
      activityId: activityId ?? this.activityId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      reminder: reminder ?? this.reminder,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class PlanModel {
  final String id;
  final String title;
  final String description;
  final String childId;
  final String createdBy;
  final DateTime createdAt;
  final String planType; // 'daily', 'weekly'
  final DateTime startDate;
  final DateTime endDate;
  final String recurrence; // 'once', 'daily', 'weekly', 'monthly'
  final List<int> recurrenceDays; // 1-7 untuk hari dalam seminggu
  final List<PlanActivityModel> activities;
  final bool notificationsEnabled;
  final bool isTemplate;
  final String? templateName;

  PlanModel({
    required this.id,
    required this.title,
    required this.description,
    required this.childId,
    required this.createdBy,
    required this.createdAt,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.recurrence,
    required this.recurrenceDays,
    required this.activities,
    this.notificationsEnabled = true,
    this.isTemplate = false,
    this.templateName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'childId': childId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'planType': planType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'recurrence': recurrence,
      'recurrenceDays': recurrenceDays,
      'activities': activities.map((activity) => activity.toMap()).toList(),
      'notificationsEnabled': notificationsEnabled,
      'isTemplate': isTemplate,
      'templateName': templateName,
    };
  }

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      childId: map['childId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      planType: map['planType'] ?? 'daily',
      startDate:
          map['startDate'] != null
              ? DateTime.parse(map['startDate'])
              : DateTime.now(),
      endDate:
          map['endDate'] != null
              ? DateTime.parse(map['endDate'])
              : DateTime.now().add(Duration(days: 7)),
      recurrence: map['recurrence'] ?? 'once',
      recurrenceDays: List<int>.from(map['recurrenceDays'] ?? []),
      activities:
          (map['activities'] as List<dynamic>?)
              ?.map((activityMap) => PlanActivityModel.fromMap(activityMap))
              .toList() ??
          [],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      isTemplate: map['isTemplate'] ?? false,
      templateName: map['templateName'],
    );
  }

  PlanModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? recurrence,
    List<int>? recurrenceDays,
    List<PlanActivityModel>? activities,
    bool? notificationsEnabled,
    bool? isTemplate,
    String? templateName,
  }) {
    return PlanModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      childId: this.childId,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      planType: this.planType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      recurrence: recurrence ?? this.recurrence,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      activities: activities ?? this.activities,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isTemplate: isTemplate ?? this.isTemplate,
      templateName: templateName ?? this.templateName,
    );
  }
}
