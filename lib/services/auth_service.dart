import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan user saat ini
  User? get currentUser => _auth.currentUser;

  // Login dengan email & password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Login error: $e');
      rethrow; // Melempar error untuk ditangani di UI
    }
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
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
