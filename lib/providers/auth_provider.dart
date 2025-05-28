import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isTeacher => _userModel?.role == 'teacher';
  bool get isParent => _userModel?.role == 'parent';
  String get errorMessage => _errorMessage;

  // Inisialisasi status autentikasi
  Future<void> initializeAuth() async {
    _user = _auth.currentUser;
    if (_user != null) {
      await _loadUserData();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;

      if (_user != null) {
        await _loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getReadableErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      if (_user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(_user!.uid).get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          _userModel = UserModel.fromMap(data);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Register sebagai guru
  Future<bool> createTeacherAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;

      if (_user != null) {
        // Simpan data guru ke Firestore
        UserModel newUser = UserModel(
          id: _user!.uid,
          email: email,
          name: name,
          role: 'teacher',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(newUser.toMap());

        _userModel = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getReadableErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Buat akun orangtua (dilakukan oleh guru)
  Future<String?> createParentAccount({
    required String name,
    required String email,
    required String teacherId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Generate password sementara (6 digit)
      String tempPassword = _generatePassword();

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      User? newParentUser = result.user;

      if (newParentUser != null) {
        // Simpan data orangtua ke Firestore
        UserModel newParent = UserModel(
          id: newParentUser.uid,
          email: email,
          name: name,
          role: 'parent',
          createdBy: teacherId,
          tempPassword: tempPassword,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(newParentUser.uid)
            .set(newParent.toMap());

        _isLoading = false;
        notifyListeners();
        return tempPassword;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getReadableErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
  }

  // Generate password sederhana
  String _generatePassword() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
  }

  // Konversi error message ke bahasa yang lebih user-friendly
  String _getReadableErrorMessage(dynamic error) {
    String errorCode = '';

    if (error is FirebaseAuthException) {
      errorCode = error.code;
    }

    switch (errorCode) {
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan';
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email ini sudah digunakan';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'weak-password':
        return 'Password terlalu lemah';
      default:
        return 'Terjadi kesalahan: ${error.toString()}';
    }
  }
}
