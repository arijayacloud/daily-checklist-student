import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mendapatkan user saat ini
  User? get currentUser => _auth.currentUser;

  // Login dengan email dan password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Mendapatkan data user dari Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Metode untuk memproses pengguna tertunda (idealnya dilakukan oleh Cloud Functions)
  // Metode ini mensimulasikan bagaimana Cloud Functions akan memproses
  Future<void> processPendingUsers() async {
    try {
      // Dalam aplikasi sebenarnya, Cloud Functions akan menjalankan ini secara otomatis
      // Fungsi ini hanya untuk demonstrasi

      // Ambil semua pengguna tertunda
      final pendingUsers =
          await _firestore
              .collection('pending_users')
              .where('status', isEqualTo: 'pending')
              .get();

      // Tidak ada pengguna tertunda
      if (pendingUsers.docs.isEmpty) return;

      // Proses setiap pengguna
      for (var doc in pendingUsers.docs) {
        final data = doc.data();
        final email = data['email'] as String?;
        final password = data['tempPassword'] as String?;

        if (email == null || password == null) continue;

        try {
          // 1. Buat akun di Firebase Auth
          // Idealnya Cloud Functions akan menggunakan Admin SDK, bukan client SDK
          final UserCredential result = await _auth
              .createUserWithEmailAndPassword(email: email, password: password);

          if (result.user != null) {
            // 2. Perbarui ID pengguna di Firestore
            final updatedData = {...data};
            updatedData['id'] = result.user!.uid;
            updatedData['status'] = 'active';
            updatedData['processedAt'] = FieldValue.serverTimestamp();

            // 3. Perbarui dokumen di koleksi users
            await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .set(updatedData);

            // 4. Tandai sebagai selesai di pending_users
            await _firestore.collection('pending_users').doc(doc.id).update({
              'status': 'completed',
              'processedAt': FieldValue.serverTimestamp(),
              'authUserId': result.user!.uid,
            });

            // 5. Perbarui status batch_job
            final batchJobs =
                await _firestore
                    .collection('batch_jobs')
                    .where('userId', isEqualTo: doc.id)
                    .where('type', isEqualTo: 'create_user_account')
                    .get();

            for (var job in batchJobs.docs) {
              await _firestore.collection('batch_jobs').doc(job.id).update({
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        } catch (e) {
          print('Error creating user $email: $e');

          // Tandai error di pending_users
          await _firestore.collection('pending_users').doc(doc.id).update({
            'status': 'error',
            'error': e.toString(),
            'processedAt': FieldValue.serverTimestamp(),
          });

          // Perbarui status batch_job
          final batchJobs =
              await _firestore
                  .collection('batch_jobs')
                  .where('userId', isEqualTo: doc.id)
                  .where('type', isEqualTo: 'create_user_account')
                  .get();

          for (var job in batchJobs.docs) {
            await _firestore.collection('batch_jobs').doc(job.id).update({
              'status': 'error',
              'error': e.toString(),
              'completedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('Error processing pending users: $e');
    } finally {
      // Pastikan untuk logout jika menggunakan user lain
      await _auth.signOut();
    }
  }

  // Membuat akun parent (oleh guru)
  Future<String> createParentAccount({
    required String name,
    required String email,
    required String teacherId,
  }) async {
    try {
      // Generate password sementara
      String tempPassword = _generatePassword();

      // Buat user di Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      // Simpan data user di Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'id': result.user!.uid,
        'email': email,
        'name': name,
        'role': 'parent',
        'createdBy': teacherId,
        'tempPassword': tempPassword, // Hanya untuk sekali tampil ke guru
        'createdAt': DateTime.now().toIso8601String(),
      });

      return tempPassword;
    } catch (e) {
      print('Create account error: $e');
      rethrow;
    }
  }

  // Membuat akun guru (self-registration)
  Future<UserCredential> createTeacherAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Buat user di Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data user di Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'id': result.user!.uid,
        'email': email,
        'name': name,
        'role': 'teacher',
        'createdAt': DateTime.now().toIso8601String(),
      });

      return result;
    } catch (e) {
      print('Create teacher account error: $e');
      rethrow;
    }
  }

  // Generate password sederhana untuk akun parent
  String _generatePassword() {
    // Generate 6-digit password dari timestamp
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
  }

  // Cek role user dari Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['role'];
      }
      return null;
    } catch (e) {
      print('Get user role error: $e');
      return null;
    }
  }
}
