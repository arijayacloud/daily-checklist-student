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
    if (user != null) {
      fetchPlans();
    } else {
      _plans = [];
      notifyListeners();
    }
  }

  Future<void> fetchPlans() async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_user!.isTeacher) {
        // Jika guru, ambil semua rencana yang dibuat oleh guru tersebut
        final snapshot =
            await _firestore
                .collection('plans')
                .where('teacherId', isEqualTo: _user!.id)
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
      } else {
        // Jika orangtua, ambil rencana yang childId-nya adalah id orangtua atau null (untuk semua)
        final snapshot =
            await _firestore
                .collection('plans')
                .where('childId', whereIn: [_user!.id, null])
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
      }

      // Sort locally
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

      await fetchPlans();
    } catch (e) {
      debugPrint('Error creating weekly plan: $e');
      _error = 'Failed to create plan. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
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

      await fetchPlans();
    } catch (e) {
      debugPrint('Error marking activity as completed: $e');
      _error = 'Failed to update activity. Please try again.';
      _isLoading = false;
      notifyListeners();
      rethrow; // Rethrow untuk ditangkap oleh UI
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

    for (final plan in _plans) {
      // Dapatkan aktivitas dengan planId
      final activitiesWithPlanId = plan.getActivitiesForDate(date);
      result.addAll(activitiesWithPlanId);
    }

    return result;
  }

  PlanningModel? getPlanById(String id) {
    try {
      return _plans.firstWhere((plan) => plan.id == id);
    } catch (e) {
      return null;
    }
  }
}
