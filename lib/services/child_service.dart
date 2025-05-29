import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

class ChildService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'children';

  // URL dasar untuk DiceBear API
  final String _diceBearBaseUrl = 'https://api.dicebear.com/9.x/thumbs/svg';

  // Dapatkan semua anak tanpa filter teacherId
  Stream<List<ChildModel>> getChildrenByTeacher(
    String teacherId, {
    bool getAllChildren = false,
  }) {
    // Hapus filter teacherId dan selalu tampilkan semua anak
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return ChildModel.fromMap(data);
      }).toList();
    });
  }

  // Dapatkan semua anak untuk orangtua tertentu
  Stream<List<ChildModel>> getChildrenByParent(String parentId) {
    return _firestore
        .collection(_collection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return ChildModel.fromMap(data);
          }).toList();
        });
  }

  // Dapatkan anak berdasarkan ID
  Future<ChildModel?> getChildById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(id).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ChildModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('Error getting child: $e');
      rethrow;
    }
  }

  // Cari anak berdasarkan nama
  Future<List<ChildModel>> searchChildren(
    String teacherId,
    String query,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collection)
              .where('teacherId', isEqualTo: teacherId)
              .get();

      List<ChildModel> children =
          snapshot.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return ChildModel.fromMap(data);
              })
              .where((child) {
                String lowercaseQuery = query.toLowerCase();
                return child.name.toLowerCase().contains(lowercaseQuery);
              })
              .toList();

      return children;
    } catch (e) {
      print('Error searching children: $e');
      return [];
    }
  }

  // Generate URL avatar dengan DiceBear API
  String generateAvatarUrl(String seed) {
    // Bersihkan seed dari karakter khusus dan encode untuk URL
    String cleanSeed = Uri.encodeComponent(seed.trim());
    // Gunakan seed (biasanya nama anak) untuk konsistensi
    return '$_diceBearBaseUrl?seed=$cleanSeed';
  }

  // Tambah anak baru
  Future<String> addChild({
    required String name,
    required int age,
    required String parentId,
    required String teacherId,
    String? notes,
  }) async {
    try {
      // Generate avatar URL
      String avatarUrl = generateAvatarUrl(name);

      // Data untuk Firestore
      Map<String, dynamic> data = {
        'name': name,
        'age': age,
        'parentId': parentId,
        'teacherId': teacherId,
        'avatarUrl': avatarUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'notes': notes,
      };

      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(data);
      return docRef.id;
    } catch (e) {
      print('Error adding child: $e');
      rethrow;
    }
  }

  // Update data anak
  Future<void> updateChild(ChildModel child) async {
    try {
      await _firestore.collection(_collection).doc(child.id).update({
        ...child.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating child: $e');
      rethrow;
    }
  }

  // Hapus anak
  Future<void> deleteChild(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting child: $e');
      rethrow;
    }
  }
}
