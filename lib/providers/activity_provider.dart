// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import '../models/activity_model.dart';
// import '../models/user_model.dart';

// class ActivityProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _uuid = const Uuid();

//   UserModel? _user;
//   List<ActivityModel> _activities = [];
//   bool _isLoading = false;
//   String? _error;

//   List<ActivityModel> get activities => _activities;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   void update(UserModel? user) {
//     _user = user;
//     if (user != null) {
//       fetchActivities();
//     } else {
//       _activities = [];
//       notifyListeners();
//     }
//   }

//   Future<void> fetchActivities() async {
//     if (_user == null) return;

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       QuerySnapshot snapshot;

//       // Both teachers and parents can see all activities
//       snapshot =
//           await _firestore
//               .collection('activities')
//               .orderBy('createdAt', descending: true)
//               .get();

//       _activities =
//           snapshot.docs.map((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return ActivityModel.fromJson({'id': doc.id, ...data});
//           }).toList();

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error fetching activities: $e');
//       _error = 'Failed to load activities. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> addActivity({
//     required String title,
//     required String description,
//     required String environment,
//     required String difficulty,
//     required int minAge,
//     required int maxAge,
//     String? nextActivityId,
//     required List<String> steps,
//   }) async {
//     if (_user == null || !_user!.isTeacher) {
//       throw 'Only teachers can add activities';
//     }

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final activityId = _uuid.v4();

//       await _firestore.collection('activities').doc(activityId).set({
//         'title': title,
//         'description': description,
//         'environment': environment,
//         'difficulty': difficulty,
//         'ageRange': {'min': minAge, 'max': maxAge},
//         'nextActivityId': nextActivityId,
//         'customSteps': [
//           {'teacherId': _user!.id, 'steps': steps},
//         ],
//         'createdAt': FieldValue.serverTimestamp(),
//         'createdBy': _user!.id,
//       });

//       await fetchActivities();
//     } catch (e) {
//       debugPrint('Error adding activity: $e');
//       _error = 'Failed to add activity. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateActivity({
//     required String id,
//     required String title,
//     required String description,
//     required String environment,
//     required String difficulty,
//     required int minAge,
//     required int maxAge,
//     String? nextActivityId,
//   }) async {
//     if (_user == null || !_user!.isTeacher) {
//       throw 'Only teachers can update activities';
//     }

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       await _firestore.collection('activities').doc(id).update({
//         'title': title,
//         'description': description,
//         'environment': environment,
//         'difficulty': difficulty,
//         'ageRange': {'min': minAge, 'max': maxAge},
//         'nextActivityId': nextActivityId,
//       });

//       await fetchActivities();
//     } catch (e) {
//       debugPrint('Error updating activity: $e');
//       _error = 'Failed to update activity. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> addCustomSteps({
//     required String activityId,
//     required List<String> steps,
//   }) async {
//     if (_user == null || !_user!.isTeacher) {
//       throw 'Only teachers can add custom steps';
//     }

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       // Get the activity document
//       final activityDoc =
//           await _firestore.collection('activities').doc(activityId).get();

//       if (!activityDoc.exists) {
//         throw 'Activity not found';
//       }

//       final data = activityDoc.data() as Map<String, dynamic>;
//       final List<dynamic> customSteps = data['customSteps'] ?? [];

//       // Check if teacher already has custom steps
//       final teacherStepIndex = customSteps.indexWhere(
//         (step) => step['teacherId'] == _user!.id,
//       );

//       if (teacherStepIndex >= 0) {
//         // Update existing steps
//         customSteps[teacherStepIndex]['steps'] = steps;
//       } else {
//         // Add new steps
//         customSteps.add({'teacherId': _user!.id, 'steps': steps});
//       }

//       await _firestore.collection('activities').doc(activityId).update({
//         'customSteps': customSteps,
//       });

//       await fetchActivities();
//     } catch (e) {
//       debugPrint('Error adding custom steps: $e');
//       _error = 'Failed to add custom steps. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   List<ActivityModel> getActivitiesForAge(int childAge) {
//     return _activities
//         .where((activity) => activity.isAppropriateForAge(childAge))
//         .toList();
//   }

//   ActivityModel? getActivityById(String activityId) {
//     try {
//       return _activities.firstWhere((activity) => activity.id == activityId);
//     } catch (e) {
//       debugPrint('Activity with id $activityId not found: $e');
//       return null;
//     }
//   }
// }
