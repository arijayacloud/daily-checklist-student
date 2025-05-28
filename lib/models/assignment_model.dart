import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { todo, inProgress, done }

class AssignmentModel {
  final String id;
  final String childId;
  final String activityId;
  final String status; // 'todo', 'in_progress', 'done'
  final String teacherId;
  final DateTime assignedDate;
  final DateTime? completedDate;
  final int? duration; // dalam menit
  final int? rating; // 1-5 bintang
  final String? notes;

  AssignmentModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.status,
    required this.teacherId,
    required this.assignedDate,
    this.completedDate,
    this.duration,
    this.rating,
    this.notes,
  });

  // Konversi dari Map (Firestore) ke AssignmentModel
  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] ?? '',
      childId: map['childId'] ?? '',
      activityId: map['activityId'] ?? '',
      status: map['status'] ?? 'todo',
      teacherId: map['teacherId'] ?? '',
      assignedDate: DateTime.parse(map['assignedDate']),
      completedDate:
          map['completedDate'] != null
              ? DateTime.parse(map['completedDate'])
              : null,
      duration: map['duration'],
      rating: map['rating'],
      notes: map['notes'],
    );
  }

  // Konversi dari AssignmentModel ke Map (untuk Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'activityId': activityId,
      'status': status,
      'teacherId': teacherId,
      'assignedDate': assignedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'duration': duration,
      'rating': rating,
      'notes': notes,
    };
  }

  // Buat salinan AssignmentModel dengan beberapa atribut yang diubah
  AssignmentModel copyWith({
    String? status,
    DateTime? completedDate,
    int? duration,
    int? rating,
    String? notes,
  }) {
    return AssignmentModel(
      id: this.id,
      childId: this.childId,
      activityId: this.activityId,
      status: status ?? this.status,
      teacherId: this.teacherId,
      assignedDate: this.assignedDate,
      completedDate: completedDate ?? this.completedDate,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }
}
