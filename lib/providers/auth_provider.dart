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
      throw 'Only teachers can create parent accounts';
    }

    try {
      // Buat instance Firebase Auth kedua untuk operasi create user
      final secondaryAuth = FirebaseAuth.instance;

      // Simpan data user yang sedang aktif
      final currentUser = _firebaseUser;
      final currentUserData = _user;

      try {
        // Create Firebase Auth user dengan instance terpisah
        await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Dapatkan UID dari user yang baru dibuat
        final parentUserRecord =
            await _firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        String parentUserId = '';

        if (parentUserRecord.docs.isEmpty) {
          // Dapatkan UID secara manual dari autentikasi
          final checkUser = await secondaryAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          parentUserId = checkUser.user!.uid;

          // Sign out dari instance kedua
          await secondaryAuth.signOut();
        } else {
          parentUserId = parentUserRecord.docs.first.id;
        }

        // Create user document
        await _firestore.collection('users').doc(parentUserId).set({
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
        });

        // Pastikan user guru tetap yang aktif
        if (_firebaseUser?.uid != currentUser?.uid) {
          // Jika sesi terganti, kembalikan ke user guru
          await _auth.signInWithEmailAndPassword(
            email: currentUser!.email!,
            password:
                '', // Ini tidak akan digunakan karena kita sudah memiliki token refresh
          );

          // Update data user
          _firebaseUser = currentUser;
          _user = currentUserData;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error saat pembuatan akun: $e');
        throw _handleAuthError(e);
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
