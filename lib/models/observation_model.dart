import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationModel {
  final String id;
  final String childId;
  final String activityId;
  final int duration; // Durasi dalam menit
  final int rating; // Rating 1-5
  final String notes;
  final DateTime observationDate;
  final String teacherId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ObservationModel({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.duration,
    required this.rating,
    required this.notes,
    required this.observationDate,
    required this.teacherId,
    required this.createdAt,
    this.updatedAt,
  });

  // Konversi dari Firestore ke ObservationModel
  factory ObservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ObservationModel(
      id: doc.id,
      childId: data['childId'] ?? '',
      activityId: data['activityId'] ?? '',
      duration: data['duration'] ?? 0,
      rating: data['rating'] ?? 0,
      notes: data['notes'] ?? '',
      observationDate: (data['observationDate'] as Timestamp).toDate(),
      teacherId: data['teacherId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Konversi dari ObservationModel ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'activityId': activityId,
      'duration': duration,
      'rating': rating,
      'notes': notes,
      'observationDate': Timestamp.fromDate(observationDate),
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Buat salinan ObservationModel dengan beberapa atribut yang diubah
  ObservationModel copyWith({
    String? childId,
    String? activityId,
    int? duration,
    int? rating,
    String? notes,
    DateTime? observationDate,
    String? teacherId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObservationModel(
      id: this.id,
      childId: childId ?? this.childId,
      activityId: activityId ?? this.activityId,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      observationDate: observationDate ?? this.observationDate,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
