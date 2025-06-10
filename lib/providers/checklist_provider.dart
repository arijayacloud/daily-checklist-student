// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import '/models/checklist_item_model.dart';
// import '/models/user_model.dart';

// class ChecklistProvider with ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _uuid = const Uuid();

//   UserModel? _user;
//   Map<String, List<ChecklistItemModel>> _checklistItems =
//       {}; // Map of childId -> list of items
//   bool _isLoading = false;
//   String? _error;

//   Map<String, List<ChecklistItemModel>> get checklistItems => _checklistItems;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   void update(UserModel? user) {
//     _user = user;
//     if (user != null) {
//       _checklistItems = {};
//     } else {
//       _checklistItems = {};
//     }
//     notifyListeners();
//   }

//   Future<void> fetchChecklistItems(String childId) async {
//     if (_user == null) return;

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final snapshot =
//           await _firestore
//               .collection('checklist_items')
//               .where('childId', isEqualTo: childId)
//               .orderBy('assignedDate', descending: true)
//               .get();

//       final items =
//           snapshot.docs.map((doc) {
//             final data = doc.data();
//             return ChecklistItemModel.fromJson({'id': doc.id, ...data});
//           }).toList();

//       _checklistItems[childId] = items;
//     } catch (e) {
//       debugPrint('Error fetching checklist items: $e');
//       _error = 'Failed to load checklist items. Please try again.';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> assignActivity({
//     required String childId,
//     required String activityId,
//     required List<String> customStepsUsed,
//     Timestamp? dueDate,
//   }) async {
//     if (_user == null || !_user!.isTeacher) {
//       throw 'Only teachers can assign activities';
//     }

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final itemId = _uuid.v4();

//       await _firestore.collection('checklist_items').doc(itemId).set({
//         'childId': childId,
//         'activityId': activityId,
//         'assignedDate': FieldValue.serverTimestamp(),
//         'dueDate': dueDate,
//         'status': 'pending',
//         'homeObservation': {'completed': false},
//         'schoolObservation': {'completed': false},
//         'customStepsUsed': customStepsUsed,
//       });

//       await fetchChecklistItems(childId);
//     } catch (e) {
//       debugPrint('Error assigning activity: $e');
//       _error = 'Failed to assign activity. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> bulkAssignActivity({
//     required List<String> childIds,
//     required String activityId,
//     required List<String> customStepsUsed,
//     Timestamp? dueDate,
//   }) async {
//     if (_user == null || !_user!.isTeacher) {
//       throw 'Only teachers can assign activities';
//     }

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final batch = _firestore.batch();

//       for (final childId in childIds) {
//         final itemId = _uuid.v4();
//         final docRef = _firestore.collection('checklist_items').doc(itemId);

//         batch.set(docRef, {
//           'childId': childId,
//           'activityId': activityId,
//           'assignedDate': FieldValue.serverTimestamp(),
//           'dueDate': dueDate,
//           'status': 'pending',
//           'homeObservation': {'completed': false},
//           'schoolObservation': {'completed': false},
//           'customStepsUsed': customStepsUsed,
//         });
//       }

//       await batch.commit();

//       // Refresh checklist items for each child
//       for (final childId in childIds) {
//         await fetchChecklistItems(childId);
//       }
//     } catch (e) {
//       debugPrint('Error bulk assigning activity: $e');
//       _error = 'Failed to assign activities. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> updateChecklistItemStatus({
//     required String itemId,
//     required String status,
//   }) async {
//     if (_user == null) return;

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       await _firestore.collection('checklist_items').doc(itemId).update({
//         'status': status,
//       });

//       // Refresh the checklist items
//       final itemDoc =
//           await _firestore.collection('checklist_items').doc(itemId).get();
//       if (itemDoc.exists) {
//         final data = itemDoc.data() as Map<String, dynamic>;
//         final childId = data['childId'] as String;
//         await fetchChecklistItems(childId);
//       }
//     } catch (e) {
//       debugPrint('Error updating checklist item status: $e');
//       _error = 'Failed to update status. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> addHomeObservation({
//     required String itemId,
//     required int duration,
//     required int engagement,
//     required String notes,
//   }) async {
//     if (_user == null) return;

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       await _firestore.collection('checklist_items').doc(itemId).update({
//         'homeObservation': {
//           'completed': true,
//           'completedAt': FieldValue.serverTimestamp(),
//           'duration': duration,
//           'engagement': engagement,
//           'notes': notes,
//         },
//         'status': 'completed',
//       });

//       // Refresh the checklist items
//       final itemDoc =
//           await _firestore.collection('checklist_items').doc(itemId).get();
//       if (itemDoc.exists) {
//         final data = itemDoc.data() as Map<String, dynamic>;
//         final childId = data['childId'] as String;
//         await fetchChecklistItems(childId);

//         // Check for follow-up activity
//         final activityId = data['activityId'] as String;
//         await _checkForFollowUps(childId, activityId);
//       }
//     } catch (e) {
//       debugPrint('Error adding home observation: $e');
//       _error = 'Failed to add observation. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> addSchoolObservation({
//     required String itemId,
//     required int duration,
//     required int engagement,
//     required String notes,
//     required String learningOutcomes,
//   }) async {
//     if (_user == null || !_user!.isTeacher) {
//       throw 'Only teachers can add school observations';
//     }

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       await _firestore.collection('checklist_items').doc(itemId).update({
//         'schoolObservation': {
//           'completed': true,
//           'completedAt': FieldValue.serverTimestamp(),
//           'duration': duration,
//           'engagement': engagement,
//           'notes': notes,
//           'learningOutcomes': learningOutcomes,
//         },
//         'status': 'completed',
//       });

//       // Refresh the checklist items
//       final itemDoc =
//           await _firestore.collection('checklist_items').doc(itemId).get();
//       if (itemDoc.exists) {
//         final data = itemDoc.data() as Map<String, dynamic>;
//         final childId = data['childId'] as String;
//         await fetchChecklistItems(childId);

//         // Check for follow-up activity
//         final activityId = data['activityId'] as String;
//         await _checkForFollowUps(childId, activityId);
//       }
//     } catch (e) {
//       debugPrint('Error adding school observation: $e');
//       _error = 'Failed to add observation. Please try again.';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _checkForFollowUps(
//     String childId,
//     String completedActivityId,
//   ) async {
//     try {
//       // Get the completed activity
//       final activityDoc =
//           await _firestore
//               .collection('activities')
//               .doc(completedActivityId)
//               .get();

//       if (!activityDoc.exists) return;

//       final data = activityDoc.data() as Map<String, dynamic>;
//       final nextActivityId = data['nextActivityId'] as String?;

//       if (nextActivityId != null) {
//         // Create a follow-up suggestion
//         await _firestore.collection('follow_up_suggestions').add({
//           'childId': childId,
//           'completedActivityId': completedActivityId,
//           'suggestedActivityId': nextActivityId,
//           'autoAssigned': false,
//           'assignedDate': FieldValue.serverTimestamp(),
//         });
//       }
//     } catch (e) {
//       debugPrint('Error checking for follow-ups: $e');
//     }
//   }

//   List<ChecklistItemModel> getChecklistItemsForChild(String childId) {
//     return _checklistItems[childId] ?? [];
//   }

//   List<ChecklistItemModel> getPendingChecklistItems(String childId) {
//     return getChecklistItemsForChild(
//       childId,
//     ).where((item) => !item.isCompleted).toList();
//   }

//   List<ChecklistItemModel> getCompletedChecklistItems(String childId) {
//     return getChecklistItemsForChild(
//       childId,
//     ).where((item) => item.isCompleted).toList();
//   }

//   ChecklistItemModel? getChecklistItemById(String childId, String itemId) {
//     try {
//       return getChecklistItemsForChild(
//         childId,
//       ).firstWhere((item) => item.id == itemId);
//     } catch (e) {
//       return null;
//     }
//   }
// }
