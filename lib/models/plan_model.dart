import 'package:cloud_firestore/cloud_firestore.dart';

class DailyActivities {
  final List<String> activityIds;

  DailyActivities({required this.activityIds});

  // Konversi dari Firestore ke DailyActivities
  factory DailyActivities.fromFirestore(List<dynamic> activityIdsList) {
    return DailyActivities(activityIds: List<String>.from(activityIdsList));
  }

  // Konversi dari DailyActivities ke List untuk Firestore
  List<String> toFirestore() {
    return activityIds;
  }
}

class PlanModel {
  final String id;
  final String teacherId;
  final DateTime weekStartDate; // Tanggal hari Senin
  final Map<String, DailyActivities>
  dailyActivities; // Map dengan key 'monday', 'tuesday', dsb.
  final DateTime createdAt;
  final DateTime? updatedAt;

  PlanModel({
    required this.id,
    required this.teacherId,
    required this.weekStartDate,
    required this.dailyActivities,
    required this.createdAt,
    this.updatedAt,
  });

  // Mendapatkan hari dalam seminggu
  static List<String> get daysOfWeek => [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  // Mendapatkan nama hari yang mudah dibaca
  static String getDayName(String day) {
    switch (day) {
      case 'monday':
        return 'Senin';
      case 'tuesday':
        return 'Selasa';
      case 'wednesday':
        return 'Rabu';
      case 'thursday':
        return 'Kamis';
      case 'friday':
        return 'Jumat';
      case 'saturday':
        return 'Sabtu';
      case 'sunday':
        return 'Minggu';
      default:
        return '';
    }
  }

  // Konversi dari Firestore ke PlanModel
  factory PlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Mengambil dailyActivities dari Firestore
    final Map<String, DailyActivities> activities = {};
    final dailyActivitiesData =
        data['dailyActivities'] as Map<String, dynamic>? ?? {};

    for (final day in daysOfWeek) {
      if (dailyActivitiesData.containsKey(day)) {
        activities[day] = DailyActivities.fromFirestore(
          dailyActivitiesData[day] as List<dynamic>,
        );
      } else {
        activities[day] = DailyActivities(activityIds: []);
      }
    }

    return PlanModel(
      id: doc.id,
      teacherId: data['teacherId'] ?? '',
      weekStartDate: (data['weekStartDate'] as Timestamp).toDate(),
      dailyActivities: activities,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  // Konversi dari PlanModel ke Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, List<String>> dailyActivitiesMap = {};

    for (final entry in dailyActivities.entries) {
      dailyActivitiesMap[entry.key] = entry.value.toFirestore();
    }

    return {
      'teacherId': teacherId,
      'weekStartDate': Timestamp.fromDate(weekStartDate),
      'dailyActivities': dailyActivitiesMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Buat salinan PlanModel dengan beberapa atribut yang diubah
  PlanModel copyWith({
    String? teacherId,
    DateTime? weekStartDate,
    Map<String, DailyActivities>? dailyActivities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanModel(
      id: this.id,
      teacherId: teacherId ?? this.teacherId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      dailyActivities: dailyActivities ?? this.dailyActivities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
