import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpSuggestionModel {
  final String id;
  final String childId;
  final String completedActivityId;
  final String suggestedActivityId;
  final bool autoAssigned;
  final DateTime suggestedDate;
  final bool accepted;
  final String? assignedChecklistItemId;

  FollowUpSuggestionModel({
    required this.id,
    required this.childId,
    required this.completedActivityId,
    required this.suggestedActivityId,
    required this.autoAssigned,
    required this.suggestedDate,
    this.accepted = false,
    this.assignedChecklistItemId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'completedActivityId': completedActivityId,
      'suggestedActivityId': suggestedActivityId,
      'autoAssigned': autoAssigned,
      'suggestedDate': suggestedDate.toIso8601String(),
      'accepted': accepted,
      'assignedChecklistItemId': assignedChecklistItemId,
    };
  }

  factory FollowUpSuggestionModel.fromMap(Map<String, dynamic> map) {
    return FollowUpSuggestionModel(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      completedActivityId: map['completedActivityId'] ?? '',
      suggestedActivityId: map['suggestedActivityId'] ?? '',
      autoAssigned: map['autoAssigned'] ?? false,
      suggestedDate:
          map['suggestedDate'] != null
              ? DateTime.parse(map['suggestedDate'])
              : DateTime.now(),
      accepted: map['accepted'] ?? false,
      assignedChecklistItemId: map['assignedChecklistItemId'],
    );
  }

  FollowUpSuggestionModel copyWith({
    String? id,
    String? childId,
    String? completedActivityId,
    String? suggestedActivityId,
    bool? autoAssigned,
    DateTime? suggestedDate,
    bool? accepted,
    String? assignedChecklistItemId,
  }) {
    return FollowUpSuggestionModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      completedActivityId: completedActivityId ?? this.completedActivityId,
      suggestedActivityId: suggestedActivityId ?? this.suggestedActivityId,
      autoAssigned: autoAssigned ?? this.autoAssigned,
      suggestedDate: suggestedDate ?? this.suggestedDate,
      accepted: accepted ?? this.accepted,
      assignedChecklistItemId:
          assignedChecklistItemId ?? this.assignedChecklistItemId,
    );
  }
}
