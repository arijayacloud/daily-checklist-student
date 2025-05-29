import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String id;
  final String planId;
  final String activityId;
  final String childId;
  final DateTime time;
  final bool notificationSent;
  final DateTime? notificationTime;

  ReminderModel({
    required this.id,
    required this.planId,
    required this.activityId,
    required this.childId,
    required this.time,
    this.notificationSent = false,
    this.notificationTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'activityId': activityId,
      'childId': childId,
      'time': time.toIso8601String(),
      'notificationSent': notificationSent,
      'notificationTime': notificationTime?.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      planId: map['planId'] ?? '',
      activityId: map['activityId'] ?? '',
      childId: map['childId'] ?? '',
      time: DateTime.parse(map['time']),
      notificationSent: map['notificationSent'] ?? false,
      notificationTime:
          map['notificationTime'] != null
              ? DateTime.parse(map['notificationTime'])
              : null,
    );
  }

  ReminderModel copyWith({
    bool? notificationSent,
    DateTime? notificationTime,
    DateTime? time,
  }) {
    return ReminderModel(
      id: this.id,
      planId: this.planId,
      activityId: this.activityId,
      childId: this.childId,
      time: time ?? this.time,
      notificationSent: notificationSent ?? this.notificationSent,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}
