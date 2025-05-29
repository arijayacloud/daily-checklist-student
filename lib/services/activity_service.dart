import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'activities';

  // Dapatkan semua aktivitas dengan filter
  Stream<List<ActivityModel>> getActivitiesByTeacher(
    String teacherId, {
    bool getAllActivities = false,
  }) {
    var query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true);

    if (!getAllActivities) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return ActivityModel.fromMap(data);
      }).toList();
    });
  }

  // Dapatkan aktivitas berdasarkan rentang usia anak
  Stream<List<ActivityModel>> getActivitiesByAgeRange(int childAge) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data();
                data['id'] = doc.id;
                return ActivityModel.fromMap(data);
              })
              .where((activity) {
                return activity.ageRange.min <= childAge &&
                    activity.ageRange.max >= childAge;
              })
              .toList();
        });
  }

  // Dapatkan aktivitas berdasarkan ID
  Future<ActivityModel?> getActivityById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(id).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ActivityModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Error getting activity: $e');
      rethrow;
    }
  }

  // Dapatkan aktivitas lanjutan (follow-up)
  Future<ActivityModel?> getFollowUpActivity(String activityId) async {
    try {
      // Dapatkan activity saat ini
      ActivityModel? currentActivity = await getActivityById(activityId);

      if (currentActivity != null && currentActivity.nextActivityId != null) {
        // Dapatkan activity lanjutan
        return await getActivityById(currentActivity.nextActivityId!);
      }

      return null;
    } catch (e) {
      print('Error getting follow-up activity: $e');
      rethrow;
    }
  }

  // Cari aktivitas berdasarkan judul atau deskripsi
  Future<List<ActivityModel>> searchActivities(
    String teacherId,
    String query, {
    int? minAge,
    int? maxAge,
    String? environment,
    String? difficulty,
  }) async {
    try {
      // Firestore tidak mendukung full-text search, jadi kita mengambil semua
      // aktivitas dan melakukan filter di sisi klien
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      List<ActivityModel> activities =
          snapshot.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return ActivityModel.fromMap(data);
              })
              .where((activity) {
                // Filter berdasarkan teacherId jika bukan melihat semua
                if (teacherId.isNotEmpty && activity.teacherId != teacherId) {
                  return false;
                }

                // Filter berdasarkan teks pencarian
                String lowercaseQuery = query.toLowerCase();
                bool matchesQuery =
                    activity.title.toLowerCase().contains(lowercaseQuery) ||
                    activity.description.toLowerCase().contains(lowercaseQuery);

                // Filter berdasarkan rentang usia
                bool matchesAge = true;
                if (minAge != null) {
                  matchesAge = matchesAge && activity.ageRange.min >= minAge;
                }
                if (maxAge != null) {
                  matchesAge = matchesAge && activity.ageRange.max <= maxAge;
                }

                // Filter berdasarkan environment
                bool matchesEnvironment = true;
                if (environment != null && environment.isNotEmpty) {
                  matchesEnvironment = activity.environment == environment;
                }

                // Filter berdasarkan difficulty
                bool matchesDifficulty = true;
                if (difficulty != null && difficulty.isNotEmpty) {
                  matchesDifficulty = activity.difficulty == difficulty;
                }

                return matchesQuery &&
                    matchesAge &&
                    matchesEnvironment &&
                    matchesDifficulty;
              })
              .toList();

      return activities;
    } catch (e) {
      print('Error searching activities: $e');
      return [];
    }
  }

  // Tambah aktivitas baru
  Future<String> addActivity(ActivityModel activity) async {
    try {
      // Hapus ID karena Firestore akan generate ID baru
      Map<String, dynamic> data = activity.toMap();
      data.remove('id');

      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      print('Error adding activity: $e');
      rethrow;
    }
  }

  // Update aktivitas
  Future<void> updateActivity(ActivityModel activity) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(activity.id)
          .update(activity.toMap());
    } catch (e) {
      print('Error updating activity: $e');
      rethrow;
    }
  }

  // Tambah custom steps ke aktivitas
  Future<void> addCustomSteps(
    String activityId,
    String teacherId,
    List<String> steps,
  ) async {
    try {
      // Dapatkan aktivitas yang ada
      ActivityModel? activity = await getActivityById(activityId);

      if (activity != null) {
        // Cari apakah sudah ada custom steps untuk guru ini
        int existingIndex = activity.customSteps.indexWhere(
          (step) => step.teacherId == teacherId,
        );

        List<CustomStep> updatedSteps = List.from(activity.customSteps);

        if (existingIndex >= 0) {
          // Update steps yang sudah ada
          updatedSteps[existingIndex] = CustomStep(
            teacherId: teacherId,
            steps: steps,
          );
        } else {
          // Tambahkan steps baru
          updatedSteps.add(CustomStep(teacherId: teacherId, steps: steps));
        }

        // Update aktivitas
        ActivityModel updatedActivity = activity.copyWith(
          customSteps: updatedSteps,
        );

        await updateActivity(updatedActivity);
      }
    } catch (e) {
      print('Error adding custom steps: $e');
      rethrow;
    }
  }

  // Hapus aktivitas
  Future<void> deleteActivity(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }
}
