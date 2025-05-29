import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'assignments';

  // Dapatkan semua tugas untuk anak tertentu
  Stream<List<AssignmentModel>> getAssignmentsByChild(String childId) {
    return _firestore
        .collection(_collection)
        .where('childId', isEqualTo: childId)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return AssignmentModel.fromMap(data);
          }).toList();
        });
  }

  // Dapatkan semua tugas tanpa filter teacherId
  Stream<List<AssignmentModel>> getAssignmentsByTeacher(
    String teacherId, {
    bool getAllAssignments = false,
  }) {
    // Hapus filter teacherId dan selalu tampilkan semua tugas
    return _firestore
        .collection(_collection)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return AssignmentModel.fromMap(data);
          }).toList();
        });
  }

  // Dapatkan semua tugas untuk aktivitas tertentu
  Stream<List<AssignmentModel>> getAssignmentsByActivity(String activityId) {
    return _firestore
        .collection(_collection)
        .where('activityId', isEqualTo: activityId)
        .orderBy('assignedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return AssignmentModel.fromMap(data);
          }).toList();
        });
  }

  // Dapatkan tugas berdasarkan ID
  Future<AssignmentModel?> getAssignmentById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(id).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AssignmentModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Error getting assignment: $e');
      rethrow;
    }
  }

  // Filter tugas berdasarkan status
  Future<List<AssignmentModel>> getAssignmentsByStatus(
    String teacherId,
    String status,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('status', isEqualTo: status)
              .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AssignmentModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error filtering assignments: $e');
      return [];
    }
  }

  // Tambah tugas baru (single)
  Future<String> addAssignment({
    required String childId,
    required String activityId,
    required String teacherId,
  }) async {
    try {
      Map<String, dynamic> data = {
        'childId': childId,
        'activityId': activityId,
        'teacherId':
            '', // Mengosongkan teacherId agar semua guru bisa melihat tugas
        'status': 'todo',
        'assignedDate': DateTime.now().toIso8601String(),
      };

      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      print('Error adding assignment: $e');
      rethrow;
    }
  }

  // Tambah tugas secara massal (bulk assignment)
  Future<List<String>> bulkAssignActivity({
    required List<String> childIds,
    required String activityId,
    required String teacherId,
  }) async {
    try {
      List<String> assignmentIds = [];

      // Batch write untuk efisiensi
      WriteBatch batch = _firestore.batch();

      for (String childId in childIds) {
        String assignmentId = const Uuid().v4();
        DocumentReference docRef = _firestore
            .collection(_collection)
            .doc(assignmentId);

        batch.set(docRef, {
          'childId': childId,
          'activityId': activityId,
          'teacherId':
              '', // Mengosongkan teacherId agar semua guru bisa melihat tugas
          'status': 'todo',
          'assignedDate': DateTime.now().toIso8601String(),
        });

        assignmentIds.add(assignmentId);
      }

      await batch.commit();
      return assignmentIds;
    } catch (e) {
      print('Error bulk assigning: $e');
      rethrow;
    }
  }

  // Update status tugas
  Future<void> updateAssignmentStatus({
    required String id,
    required String status,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> data = {'status': status};

      // Tambahkan completedDate jika status done
      if (status == 'done') {
        data['completedDate'] = DateTime.now().toIso8601String();
      }

      // Tambahkan notes jika ada
      if (notes != null) {
        data['notes'] = notes;
      }

      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      print('Error updating assignment status: $e');
      rethrow;
    }
  }

  // Hapus tugas
  Future<void> deleteAssignment(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting assignment: $e');
      rethrow;
    }
  }
}
