import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // URL dasar untuk DiceBear API
  final String _diceBearBaseUrl = 'https://api.dicebear.com/9.x/thumbs/svg';

  // Metode untuk membuat akun tanpa menggunakan Auth SDK secara langsung
  Future<Map<String, dynamic>> createUserWithoutAuthChange({
    required String name,
    required String email,
    required String role,
    required String creatorId,
  }) async {
    try {
      // 1. Periksa apakah email sudah digunakan dengan mengecek Firestore
      final emailCheck =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (emailCheck.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email ini sudah digunakan',
          'password': null,
        };
      }

      // 2. Generate password sementara (6 digit)
      final String tempPassword = _generatePassword();

      // 3. Generate avatar URL
      final String avatarUrl = _generateAvatarUrl(name);

      // 4. Buat entry di koleksi 'pending_users' untuk diproses nanti
      // Pendekatan ini menghindari pembuatan langsung melalui Firebase Auth
      final String pendingUserId =
          _firestore.collection('pending_users').doc().id;

      final Map<String, dynamic> userData = {
        'id': pendingUserId,
        'email': email,
        'name': name,
        'role': role,
        'createdBy': creatorId,
        'tempPassword': tempPassword,
        'avatarUrl': avatarUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': null,
      };

      // 5. Simpan data pengguna ke Firestore sebagai user tertunda
      await _firestore
          .collection('pending_users')
          .doc(pendingUserId)
          .set(userData);

      // 6. Juga simpan di koleksi 'users' dengan status 'pending_activation'
      // sehingga bisa langsung ditampilkan di UI meskipun belum diproses
      userData['status'] = 'pending_activation';
      await _firestore.collection('users').doc(pendingUserId).set(userData);

      // 7. Tambahkan dokumen ke batch_jobs untuk diproses
      await _firestore.collection('batch_jobs').add({
        'type': 'create_user_account',
        'userId': pendingUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 8. Kembalikan success dengan password
      return {
        'success': true,
        'message': 'Akun berhasil dibuat dan akan segera diaktifkan',
        'password': tempPassword,
        'userId': pendingUserId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'password': null,
      };
    }
  }

  // Metode untuk membuat akun guru tanpa mengubah status auth
  Future<Map<String, dynamic>> createTeacherAccount({
    required String name,
    required String email,
    String? creatorId,
  }) async {
    return createUserWithoutAuthChange(
      name: name,
      email: email,
      role: 'teacher',
      creatorId: creatorId ?? _auth.currentUser?.uid ?? '',
    );
  }

  // Metode untuk membuat akun orangtua tanpa mengubah status auth
  Future<Map<String, dynamic>> createParentAccount({
    required String name,
    required String email,
    required String teacherId,
  }) async {
    return createUserWithoutAuthChange(
      name: name,
      email: email,
      role: 'parent',
      creatorId: teacherId,
    );
  }

  // Metode untuk memuat daftar pengguna berdasarkan role
  Future<List<UserModel>> loadUsersByRole(String role) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: role)
              .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error loading $role users: $e');
      return [];
    }
  }

  // Metode untuk memuat semua pengguna yang dibuat oleh creator tertentu
  Future<List<UserModel>> loadUsersByCreator(String creatorId) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('createdBy', isEqualTo: creatorId)
              .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error loading users created by $creatorId: $e');
      return [];
    }
  }

  // Metode untuk menghapus pengguna
  Future<bool> deleteUser(String userId) async {
    try {
      // Tambahkan ke batch jobs untuk penghapusan account auth
      await _firestore.collection('batch_jobs').add({
        'type': 'delete_user_account',
        'userId': userId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Hapus dari Firestore
      await _firestore.collection('users').doc(userId).delete();

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Generate password sederhana
  String _generatePassword() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random.secure();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Generate URL avatar dengan DiceBear API
  String _generateAvatarUrl(String seed) {
    // Bersihkan seed dari karakter khusus dan encode untuk URL
    String cleanSeed = Uri.encodeComponent(seed.trim());
    // Gunakan seed (biasanya nama) untuk konsistensi
    return '$_diceBearBaseUrl?seed=$cleanSeed';
  }
}
