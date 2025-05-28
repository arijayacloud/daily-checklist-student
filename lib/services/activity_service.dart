import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'activities';

  // Dapatkan semua aktivitas yang dibuat oleh guru tertentu
  Stream<List<ActivityModel>> getActivitiesByTeacher(String teacherId) {
    return _firestore
        .collection(_collection)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return ActivityModel.fromMap(data);
          }).toList();
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

  // Cari aktivitas berdasarkan judul atau deskripsi
  Future<List<ActivityModel>> searchActivities(
    String teacherId,
    String query,
  ) async {
    try {
      // Firestore tidak mendukung full-text search, jadi kita mengambil semua
      // aktivitas dan melakukan filter di sisi klien
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('teacherId', isEqualTo: teacherId)
              .get();

      List<ActivityModel> activities =
          snapshot.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return ActivityModel.fromMap(data);
              })
              .where((activity) {
                String lowercaseQuery = query.toLowerCase();
                return activity.title.toLowerCase().contains(lowercaseQuery) ||
                    activity.description.toLowerCase().contains(lowercaseQuery);
              })
              .toList();

      return activities;
    } catch (e) {
      print('Error searching activities: $e');
      return [];
    }
  }

  // Filter aktivitas berdasarkan environment
  Future<List<ActivityModel>> filterActivitiesByEnvironment(
    String teacherId,
    String environment,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('teacherId', isEqualTo: teacherId)
              .where('environment', isEqualTo: environment)
              .get();

      List<ActivityModel> activities =
          snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return ActivityModel.fromMap(data);
          }).toList();

      return activities;
    } catch (e) {
      print('Error filtering activities: $e');
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
