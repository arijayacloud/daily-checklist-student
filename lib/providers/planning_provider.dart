import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/models/planning_model.dart';
import '/models/user_model.dart';
import '/providers/checklist_provider.dart';

class PlanningProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  UserModel? _user;
  List<PlanningModel> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<PlanningModel> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void update(UserModel? user) {
    _user = user;
    if (user != null && user.isTeacher) {
      fetchPlans();
    } else if (user != null && !user.isTeacher) {
      // Jika user adalah orangtua, ambil perencanaan untuk anaknya
      fetchPlansForParent(user.id);
    } else {
      _plans = [];
      notifyListeners();
    }
  }

  Future<void> fetchPlans() async {
    if (_user == null || !_user!.isTeacher) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('plans')
              .where('teacherId', isEqualTo: _user!.id)
              // Temporarily remove complex ordering to avoid index requirement
              // .orderBy('startDate', descending: true)
              .get();

      _plans =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final String planId = doc.id;

            // Memastikan planId disimpan dalam setiap aktivitas
            final List<dynamic> rawActivities = data['activities'] ?? [];
            final List<Map<String, dynamic>> processedActivities =
                rawActivities.map((activity) {
                  final Map<String, dynamic> processedActivity =
                      Map<String, dynamic>.from(activity);
                  processedActivity['planId'] = planId;
                  return processedActivity;
                }).toList();

            // Membuat objek dengan aktivitas yang sudah berisi planId
            return PlanningModel.fromJson({
              'id': planId,
              'teacherId': data['teacherId'] ?? '',
              'type': data['type'] ?? 'weekly',
              'startDate': data['startDate'] ?? Timestamp.now(),
              'childId': data['childId'],
              'activities': processedActivities,
            });
          }).toList();

      // Sort locally instead
      _plans.sort((a, b) => b.startDate.compareTo(a.startDate));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching plans: $e');
      _error = 'Failed to load plans. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode baru untuk mengambil perencanaan untuk orangtua berdasarkan childId
  Future<void> fetchPlansForParent(String childId) async {
    if (_user == null || childId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mengambil perencanaan yang spesifik untuk anak ini
      final specificPlansSnapshot =
          await _firestore
              .collection('plans')
              .where('childId', isEqualTo: childId)
              .get();

      // Mengambil perencanaan umum (untuk semua anak)
      final generalPlansSnapshot =
          await _firestore
              .collection('plans')
              .where('childId', isNull: true)
              .get();

      // Gabungkan hasil kedua query
      final allDocs = [
        ...specificPlansSnapshot.docs,
        ...generalPlansSnapshot.docs,
      ];

      _plans =
          allDocs.map((doc) {
            final data = doc.data();
            final String planId = doc.id;

            // Memastikan planId disimpan dalam setiap aktivitas
            final List<dynamic> rawActivities = data['activities'] ?? [];
            final List<Map<String, dynamic>> processedActivities =
                rawActivities.map((activity) {
                  final Map<String, dynamic> processedActivity =
                      Map<String, dynamic>.from(activity);
                  processedActivity['planId'] = planId;
                  return processedActivity;
                }).toList();

            // Membuat objek dengan aktivitas yang sudah berisi planId
            return PlanningModel.fromJson({
              'id': planId,
              'teacherId': data['teacherId'] ?? '',
              'type': data['type'] ?? 'weekly',
              'startDate': data['startDate'] ?? Timestamp.now(),
              'childId': data['childId'],
              'activities': processedActivities,
            });
          }).toList();

      // Urutkan berdasarkan tanggal terbaru
      _plans.sort((a, b) => b.startDate.compareTo(a.startDate));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching plans for parent: $e');
      _error = 'Gagal memuat rencana aktivitas. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWeeklyPlan({
    required DateTime startDate,
    String? childId,
    required List<PlannedActivity> activities,
  }) async {
    if (_user == null || !_user!.isTeacher) {
      throw 'Only teachers can create plans';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final planId = _uuid.v4();

      await _firestore.collection('plans').doc(planId).set({
        'teacherId': _user!.id,
        'type': 'weekly',
        'startDate': Timestamp.fromDate(startDate),
        'childId': childId,
        'activities': activities.map((activity) => activity.toJson()).toList(),
      });

      // Tambahkan notifikasi jika ada childId
      if (childId != null) {
        await _createNotificationForParent(
          childId: childId,
          planId: planId,
          startDate: startDate,
          activitiesCount: activities.length,
        );
      }

      await fetchPlans();
    } catch (e) {
      debugPrint('Error creating weekly plan: $e');
      _error = 'Failed to create plan. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk membuat notifikasi untuk orangtua
  Future<void> _createNotificationForParent({
    required String childId,
    required String planId,
    required DateTime startDate,
    required int activitiesCount,
  }) async {
    try {
      // Dapatkan informasi anak
      final childDoc =
          await _firestore.collection('children').doc(childId).get();
      if (!childDoc.exists) return;

      final childData = childDoc.data();
      final String parentId = childData?['parentId'] ?? '';
      final String childName = childData?['name'] ?? 'Anak';

      if (parentId.isEmpty) return;

      // Buat notifikasi
      await _firestore.collection('notifications').add({
        'userId': parentId,
        'title': 'Perencanaan Aktivitas Baru',
        'message':
            'Guru telah membuat perencanaan baru untuk ${childName} dengan ${activitiesCount} aktivitas mulai ${_formatDate(startDate)}',
        'type': 'new_plan',
        'relatedId': planId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      debugPrint('Notification created for parent $parentId');
    } catch (e) {
      debugPrint('Error creating notification: $e');
      // Tidak perlu throw error agar proses utama tetap berjalan
    }
  }

  // Format tanggal untuk notifikasi
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> updatePlan({
    required String planId,
    required List<PlannedActivity> activities,
  }) async {
    if (_user == null || !_user!.isTeacher) {
      throw 'Only teachers can update plans';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('plans').doc(planId).update({
        'activities': activities.map((activity) => activity.toJson()).toList(),
      });

      await fetchPlans();
    } catch (e) {
      debugPrint('Error updating plan: $e');
      _error = 'Failed to update plan. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markActivityAsCompleted({
    required String planId,
    required String activityId,
    required Timestamp scheduledDate,
  }) async {
    if (_user == null) return;

    // Validasi planId tidak kosong
    if (planId.isEmpty) {
      throw 'Plan ID tidak valid';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the current plan
      final planDoc = await _firestore.collection('plans').doc(planId).get();
      if (!planDoc.exists) throw 'Plan not found';

      final data = planDoc.data() as Map<String, dynamic>;
      final List<dynamic> activities = data['activities'] ?? [];

      // Find the activity and mark it as completed
      bool activityFound = false;
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        if (activity['activityId'] == activityId &&
            (activity['scheduledDate'] as Timestamp).toDate().day ==
                scheduledDate.toDate().day) {
          activities[i]['completed'] = true;
          activityFound = true;
          break;
        }
      }

      if (!activityFound) {
        throw 'Aktivitas tidak ditemukan dalam plan';
      }

      await _firestore.collection('plans').doc(planId).update({
        'activities': activities,
      });

      // Tambahkan notifikasi aktivitas selesai jika pengguna adalah parent
      if (!_user!.isTeacher) {
        await _createCompletionNotification(
          planId: planId,
          activityId: activityId,
        );
      }

      // Bungkus dalam blok try-catch terpisah untuk mencegah infinite loading
      try {
        await fetchPlans();
      } catch (fetchError) {
        debugPrint(
          'Error pada fetchPlans setelah markActivityAsCompleted: $fetchError',
        );
        // Reset loading state jika fetchPlans gagal
        _isLoading = false;
        notifyListeners();
      }

      // Pastikan loading state diatur ke false
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking activity as completed: $e');
      _error = 'Failed to update activity. Please try again.';
      _isLoading = false;
      notifyListeners();
      rethrow; // Rethrow untuk ditangkap oleh UI
    }
  }

  // Metode untuk membuat notifikasi ketika aktivitas selesai
  Future<void> _createCompletionNotification({
    required String planId,
    required String activityId,
  }) async {
    try {
      final plan = getPlanById(planId);
      if (plan == null) return;

      // Cari aktivitas dalam plan
      PlannedActivity? plannedActivity;
      for (final activity in plan.activities) {
        if (activity.activityId == activityId) {
          plannedActivity = activity;
          break;
        }
      }
      if (plannedActivity == null) return;

      // Dapatkan informasi aktivitas
      final activityDoc =
          await _firestore.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) return;

      final activityData = activityDoc.data();
      final String activityTitle = activityData?['title'] ?? 'Aktivitas';

      // Cari guru yang membuat perencanaan
      final teacherId = plan.teacherId;

      // Buat notifikasi untuk guru
      await _firestore.collection('notifications').add({
        'userId': teacherId,
        'title': 'Aktivitas Telah Diselesaikan',
        'message':
            'Aktivitas "$activityTitle" telah diselesaikan oleh ${_user?.name ?? "Orangtua"}',
        'type': 'activity_completed',
        'relatedId': activityId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      debugPrint('Completion notification created for teacher $teacherId');
    } catch (e) {
      debugPrint('Error creating completion notification: $e');
      // Tidak perlu throw error agar proses utama tetap berjalan
    }
  }

  // Metode untuk membuat notifikasi pengingat aktivitas yang dijadwalkan
  Future<void> createActivityReminderNotification({
    required String childId,
    required DateTime date,
  }) async {
    if (_user == null) return;

    try {
      // Ambil aktivitas untuk tanggal yang ditentukan
      final activitiesForDate = getActivitiesForDate(date);

      if (activitiesForDate.isEmpty) return;

      // Buat daftar ID aktivitas
      final List<String> activityIds = [];
      for (final activity in activitiesForDate) {
        activityIds.add(activity.activityId);
      }

      // Ambil informasi aktivitas
      final activitiesSnapshot =
          await _firestore
              .collection('activities')
              .where(
                FieldPath.documentId,
                whereIn: activityIds.take(10).toList(),
              ) // Batasi 10 aktivitas
              .get();

      final List<String> activityTitles = [];
      for (final doc in activitiesSnapshot.docs) {
        activityTitles.add(doc.data()['title'] ?? 'Aktivitas');
      }

      // Format pesan notifikasi
      final String message =
          activityTitles.length > 3
              ? 'Ada ${activityTitles.length} aktivitas terjadwal untuk tanggal ${_formatDate(date)}: ${activityTitles.take(3).join(', ')} dan lainnya.'
              : 'Ada ${activityTitles.length} aktivitas terjadwal untuk tanggal ${_formatDate(date)}: ${activityTitles.join(', ')}.';

      // Buat notifikasi pengingat
      await _firestore.collection('notifications').add({
        'userId': _user!.id,
        'title': 'Pengingat Aktivitas',
        'message': message,
        'type': 'reminder',
        'relatedId': '',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });

      debugPrint(
        'Activity reminder notification created for user ${_user!.id}',
      );
    } catch (e) {
      debugPrint('Error creating activity reminder notification: $e');
    }
  }

  Future<void> createChecklistFromActivity({
    required String activityId,
    required String childId,
    required ChecklistProvider checklistProvider,
  }) async {
    if (_user == null || !_user!.isTeacher) {
      throw 'Only teachers can create checklist items';
    }

    try {
      await checklistProvider.assignActivity(
        childId: childId,
        activityId: activityId,
        customStepsUsed: [],
        dueDate: null,
      );
    } catch (e) {
      debugPrint('Error creating checklist from activity: $e');
      rethrow;
    }
  }

  List<PlanningModel> getWeeklyPlans() {
    return _plans.where((plan) => plan.type == 'weekly').toList();
  }

  List<PlannedActivity> getActivitiesForDate(DateTime date) {
    final List<PlannedActivity> result = [];

    // Normalize date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);
    debugPrint('Getting activities for date: ${normalizedDate.toString()}');

    for (final plan in _plans) {
      // Dapatkan aktivitas dengan planId
      final activitiesWithPlanId = plan.getActivitiesForDate(normalizedDate);
      result.addAll(activitiesWithPlanId);
    }

    debugPrint(
      'Found ${result.length} activities for date ${normalizedDate.toString()}',
    );
    return result;
  }

  PlanningModel? getPlanById(String id) {
    try {
      return _plans.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }

  // Fungsi untuk mendapatkan informasi pengguna yang telah menyelesaikan aktivitas
  Future<List<Map<String, dynamic>>> getCompletionUsers(
    String activityId,
    String planId,
    Timestamp scheduledDate,
  ) async {
    final List<Map<String, dynamic>> result = [];

    try {
      // Cari plan untuk mendapatkan childId (jika spesifik untuk anak tertentu)
      final plan = getPlanById(planId);

      // Query untuk mencari siapa saja yang sudah menyelesaikan aktivitas
      Query query;

      if (plan?.childId != null) {
        // Jika plan untuk anak tertentu
        query = _firestore
            .collection('children')
            .where('id', isEqualTo: plan!.childId);
      } else {
        // Jika plan untuk semua anak
        query = _firestore.collection('children');
      }

      final childrenSnapshot = await query.get();

      for (final childDoc in childrenSnapshot.docs) {
        final childData = childDoc.data() as Map<String, dynamic>;
        final String childId = childDoc.id;
        final String childName = childData['name'] ?? 'Anak';

        // Cek status aktivitas untuk anak ini
        // Cek di checklist_items untuk aktivitas yang sesuai
        final checklistQuery =
            await _firestore
                .collection('checklist_items')
                .where('childId', isEqualTo: childId)
                .where('activityId', isEqualTo: activityId)
                .get();

        bool completedAtHome = false;
        bool completedAtSchool = false;
        Timestamp? completedAt;

        for (final checklistDoc in checklistQuery.docs) {
          final checklistData = checklistDoc.data();

          // Periksa homeObservation
          if (checklistData['homeObservation'] != null &&
              checklistData['homeObservation']['completed'] == true) {
            completedAtHome = true;
            completedAt = checklistData['homeObservation']['completedAt'];
          }

          // Periksa schoolObservation
          if (checklistData['schoolObservation'] != null &&
              checklistData['schoolObservation']['completed'] == true) {
            completedAtSchool = true;
            if (completedAt == null ||
                (checklistData['schoolObservation']['completedAt'] != null &&
                    checklistData['schoolObservation']['completedAt']
                        .toDate()
                        .isAfter(completedAt.toDate()))) {
              completedAt = checklistData['schoolObservation']['completedAt'];
            }
          }
        }

        // Cek juga di data perencanaan
        if (plan != null) {
          for (final activity in plan.activities) {
            if (activity.activityId == activityId &&
                activity.scheduledDate.toDate().day ==
                    scheduledDate.toDate().day) {
              if (activity.completed) {
                // Jika aktivitas ditandai selesai di perencanaan
                // Dan belum ada info completedAt
                if (completedAt == null) {
                  completedAt = Timestamp.now();
                }
                completedAtHome = true;
              }
            }
          }
        }

        // Jika aktivitas selesai (baik di rumah maupun sekolah), tambahkan ke daftar
        if (completedAtHome || completedAtSchool) {
          // Dapatkan informasi orangtua
          String parentName = "Orangtua";
          if (childData['parentId'] != null) {
            final parentDoc =
                await _firestore
                    .collection('users')
                    .doc(childData['parentId'])
                    .get();
            if (parentDoc.exists) {
              parentName = parentDoc.data()?['name'] ?? "Orangtua";
            }
          }

          result.add({
            'childId': childId,
            'childName': childName,
            'parentName': parentName,
            'completedAtHome': completedAtHome,
            'completedAtSchool': completedAtSchool,
            'completedAt': completedAt,
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error getting completion users: $e');
      return [];
    }
  }
}
