import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/follow_up_suggestion_model.dart';
import '../services/activity_service.dart';

class FollowUpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'follow_up_suggestions';
  final ActivityService _activityService = ActivityService();

  // Dapatkan semua saran follow-up untuk anak tertentu
  Stream<List<FollowUpSuggestionModel>> getFollowUpSuggestions(String childId) {
    return _firestore
        .collection(_collection)
        .where('childId', isEqualTo: childId)
        .where('accepted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return FollowUpSuggestionModel.fromMap(data);
          }).toList();
        });
  }

  // Buat saran follow-up baru
  Future<String> createFollowUpSuggestion({
    required String childId,
    required String completedActivityId,
    required String suggestedActivityId,
    required bool autoAssigned,
  }) async {
    try {
      final suggestion = FollowUpSuggestionModel(
        id: const Uuid().v4(),
        childId: childId,
        completedActivityId: completedActivityId,
        suggestedActivityId: suggestedActivityId,
        autoAssigned: autoAssigned,
        suggestedDate: DateTime.now(),
      );

      Map<String, dynamic> data = suggestion.toMap();
      data.remove('id');

      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      print('Error creating follow-up suggestion: $e');
      rethrow;
    }
  }

  // Periksa apakah ada follow-up activity saat checklist item ditandai selesai
  Future<void> checkForFollowUps(
    String childId,
    String completedActivityId,
  ) async {
    try {
      // Cek apakah aktivitas memiliki nextActivityId
      final activityWithFollowUp = await _activityService.getFollowUpActivity(
        completedActivityId,
      );

      if (activityWithFollowUp != null) {
        // Buat follow-up suggestion
        await createFollowUpSuggestion(
          childId: childId,
          completedActivityId: completedActivityId,
          suggestedActivityId: activityWithFollowUp.id,
          autoAssigned: true,
        );
      }
    } catch (e) {
      print('Error checking for follow-ups: $e');
      rethrow;
    }
  }

  // Terima follow-up suggestion dan tambahkan ke checklist
  Future<String?> acceptFollowUpSuggestion(
    String followUpId,
    String assignedChecklistItemId,
  ) async {
    try {
      // Dapatkan follow-up suggestion
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(followUpId).get();

      if (doc.exists) {
        // Update follow-up suggestion
        await _firestore.collection(_collection).doc(followUpId).update({
          'accepted': true,
          'assignedChecklistItemId': assignedChecklistItemId,
        });

        return assignedChecklistItemId;
      }

      return null;
    } catch (e) {
      print('Error accepting follow-up suggestion: $e');
      rethrow;
    }
  }

  // Tolak follow-up suggestion
  Future<void> rejectFollowUpSuggestion(String followUpId) async {
    try {
      await _firestore.collection(_collection).doc(followUpId).delete();
    } catch (e) {
      print('Error rejecting follow-up suggestion: $e');
      rethrow;
    }
  }
}
