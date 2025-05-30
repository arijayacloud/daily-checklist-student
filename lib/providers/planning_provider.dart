import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/models/planning_model.dart';
import '/models/user_model.dart';

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
            return PlanningModel.fromJson({'id': doc.id, ...data});
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
      for (int i = 0; i < activities.length; i++) {
        final activity = activities[i];
        if (activity['activityId'] == activityId &&
            (activity['scheduledDate'] as Timestamp).toDate().day ==
                scheduledDate.toDate().day) {
          activities[i]['completed'] = true;
          break;
        }
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
    }
  }

  List<PlanningModel> getWeeklyPlans() {
    return _plans.where((plan) => plan.type == 'weekly').toList();
  }

  List<PlannedActivity> getActivitiesForDate(DateTime date) {
    final List<PlannedActivity> result = [];

    for (final plan in _plans) {
      result.addAll(plan.getActivitiesForDate(date));
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
