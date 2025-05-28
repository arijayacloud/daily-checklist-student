import 'package:cloud_firestore/cloud_firestore.dart';

class CompletionLogModel {
  final String id;
  final String checklistItemId;
  final String environment; // 'home' atau 'school'
  final String completedBy;
  final DateTime timestamp;
  final String? notes;
  final String? photoUrl;

  CompletionLogModel({
    required this.id,
    required this.checklistItemId,
    required this.environment,
    required this.completedBy,
    required this.timestamp,
    this.notes,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'checklistItemId': checklistItemId,
      'environment': environment,
      'completedBy': completedBy,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'photoUrl': photoUrl,
    };
  }

  factory CompletionLogModel.fromMap(Map<String, dynamic> map) {
    return CompletionLogModel(
      id: map['id'] ?? '',
      checklistItemId: map['checklistItemId'] ?? '',
      environment: map['environment'] ?? '',
      completedBy: map['completedBy'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
      photoUrl: map['photoUrl'],
    );
  }
}
