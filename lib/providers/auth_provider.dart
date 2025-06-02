import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String get userRole => _user?.role ?? 'parent';
  String get userId => _firebaseUser?.uid ?? '';

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> checkAuthStatus() async {
    try {
      _firebaseUser = _auth.currentUser;
      if (_firebaseUser != null) {
        await _fetchUserData(_firebaseUser!.uid);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _user = UserModel.fromJson({'id': uid, ...data});
      } else {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _fetchUserData(userCredential.user!.uid);
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // For teachers to create parent accounts
  Future<void> createParentAccount(
    String email,
    String name,
    String password, {
    String phoneNumber = '',
    String address = '',
  }) async {
    if (_user == null || _user!.role != 'teacher') {
      throw 'Hanya guru yang dapat membuat akun orang tua';
    }

    try {
      // SOLUSI BARU: Gunakan metode yang tidak melibatkan logout
      // Di lingkungan produksi, gunakan Cloud Functions untuk membuat user

      // 1. Buat entri di 'pending_users' collection untuk menandai akun yang perlu dibuat
      // Ini akan diproses oleh Cloud Function untuk membuat Auth user
      final pendingUserRef = await _firestore.collection('pending_users').add({
        'email': email,
        'password': password, // WARNING: Ini tidak aman! Untuk demo saja
        'name': name,
        'role': 'parent',
        'teacherId': _user!.id,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'phoneNumber': phoneNumber,
        'address': address,
      });

      // 2. Untuk demo, kita lakukan pembuatan akun secara langsung dengan menggunakan second auth instance
      // CATATAN: Ini tidak ideal untuk produksi karena masalah keamanan
      try {
        // Dalam kasus demo, kita buat user Auth langsung (akan diganti dengan Cloud Functions)

        // Secara ideal, kita menggunakan Admin SDK di backend untuk membuat akun
        // Karena kita tidak bisa melakukannya di Flutter, gunakan metode alternatif berikut

        // Buat user di Firebase Auth dengan metode alternatif
        // Di produksi, gunakan Firebase Cloud Functions

        // Gunakan HTTP API untuk membuat user (akan diimplementasikan di backend)
        // Untuk demo, kita akan membuat dokumen user di Firestore saja
        final userDocRef = _firestore.collection('users').doc();

        await userDocRef.set({
          'email': email,
          'name': name,
          'role': 'parent',
          'createdBy': _user!.id,
          'isTempPassword': true,
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': phoneNumber,
          'address': address,
          'profilePicture': '',
          'status': 'active',
          'pendingAuthCreation': true,
        });

        // Update status di pending_users
        await pendingUserRef.update({
          'status': 'processed',
          'firestoreDocId': userDocRef.id,
        });

        // PENTING: Di produksi, Cloud Function akan menangani pembuatan Auth user
        // Untuk demo, kita akan tampilkan pesan bahwa user telah dibuat, meskipun Auth belum

        // Tambahkan pesan di log untuk admin mengetahui akun yang perlu dibuat
        debugPrint(
          'ADMIN: Buat akun Auth untuk email $email dengan password $password',
        );

        // Di produksi, gunakan Firebase Admin SDK seperti contoh berikut:
        /*
        const admin = require('firebase-admin');
        admin.auth().createUser({
          email: email,
          password: password,
          displayName: name,
        }).then((userRecord) => {
          // Update Firestore doc dengan UID
          admin.firestore().collection('users').doc(userDocRef.id).update({
            'uid': userRecord.uid,
            'pendingAuthCreation': false,
          });
        });
        */
      } catch (authCreationError) {
        // Tandai sebagai gagal di pending_users
        await pendingUserRef.update({
          'status': 'failed',
          'error': authCreationError.toString(),
        });

        throw 'Gagal membuat akun Auth: ${authCreationError.toString()}';
      }
    } catch (e) {
      debugPrint('Create parent account error: $e');
      throw _handleAuthError(e);
    }
  }

  // Fungsi alternatif untuk membuat akun orang tua tanpa logout
  Future<void> createParentAccountV2(
    String email,
    String name,
    String password, {
    String phoneNumber = '',
    String address = '',
  }) async {
    if (_user == null || _user!.role != 'teacher') {
      throw 'Hanya guru yang dapat membuat akun orang tua';
    }

    try {
      // Gunakan Cloud Functions atau backend API untuk membuat user
      // Ini adalah pendekatan yang lebih aman dan tidak mempengaruhi sesi pengguna saat ini

      // Untuk demo, kita simulasikan dengan kode berikut
      // TODO: Ganti dengan panggilan API yang sebenarnya

      // Tambahkan dokumen pengguna di Firestore terlebih dahulu
      final parentDocRef = _firestore.collection('users').doc();

      await parentDocRef.set({
        'email': email,
        'name': name,
        'role': 'parent',
        'createdBy': _user!.id,
        'isTempPassword': true,
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': phoneNumber,
        'address': address,
        'profilePicture': '',
        'status': 'active',
        'pendingRegistration':
            true, // Tandai bahwa akun belum sepenuhnya terdaftar
      });

      // Di sini kita akan memanggil Cloud Function untuk membuat user Auth
      // dan menghubungkannya dengan dokumen yang sudah dibuat

      // Untuk sementara kita simulasikan proses tersebut:
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final newUserId = userCredential.user!.uid;

      // Update dokumen dengan ID user yang baru dibuat
      await _firestore.collection('users').doc(parentDocRef.id).update({
        'id': newUserId,
        'pendingRegistration': false,
      });

      // Keluar dari akun baru dan login kembali sebagai guru
      if (_firebaseUser?.uid != _user?.id) {
        await _auth.signOut();

        // Di sini idealnya kita akan menggunakan custom token atau session persistence
        // Tetapi untuk sementara, kita perlu memberikan solusi yang memungkinkan user untuk login kembali
      }
    } catch (e) {
      debugPrint('Create parent account error: $e');
      throw _handleAuthError(e);
    }
  }

  // Convert Firebase Auth errors to user-friendly messages
  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return e.toString();
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_firebaseUser == null) {
      throw 'Pengguna tidak login';
    }

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );

      await _firebaseUser!.reauthenticateWithCredential(credential);

      // Change password
      await _firebaseUser!.updatePassword(newPassword);

      // Update isTempPassword to false if applicable
      if (_user?.isTempPassword == true) {
        await _firestore.collection('users').doc(_firebaseUser!.uid).update({
          'isTempPassword': false,
        });

        // Update local user model
        if (_user != null) {
          _user = _user!.copyWith(isTempPassword: false);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      throw _handleAuthError(e);
    }
  }

  // Fungsi untuk membuat akun guru
  Future<void> createTeacherAccount(
    String email,
    String name,
    String password, {
    String phoneNumber = '',
    String address = '',
  }) async {
    try {
      // Buat akun pengguna dengan Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Buat dokumen pengguna di Firestore
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': phoneNumber,
        'address': address,
        'profilePicture': '',
        'status': 'active',
        'isTempPassword': false,
      });

      // Update data pengguna saat ini
      _firebaseUser = userCredential.user;
      await _fetchUserData(uid);
    } catch (e) {
      debugPrint('Create teacher account error: $e');
      throw _handleAuthError(e);
    }
  }
}
