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
    String password,
  ) async {
    if (_user == null || _user!.role != 'teacher') {
      throw 'Only teachers can create parent accounts';
    }

    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': 'parent',
        'createdBy': _user!.id,
        'isTempPassword': true,
      });
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
}
