import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // URL dasar untuk DiceBear API
  final String _diceBearBaseUrl = 'https://api.dicebear.com/9.x/thumbs/svg';

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';

  // Constructor
  AuthProvider() {
    // Setup auth state listener
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

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
    try {
      _isLoading = true;
      notifyListeners();

      // Periksa apakah ada pengguna yang sudah login
      _user = _authService.currentUser;

      if (_user != null) {
        // Jika ada, muat data pengguna dari Firestore
        await _loadUserData();
        print('User sudah login: ${_userModel?.name} (${_userModel?.role})');
      } else {
        print('Tidak ada user yang login');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Error pada initializeAuth: $e');
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      UserCredential? result = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      _user = result?.user;

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

  // Logout
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
  }

  // Generate URL avatar dengan DiceBear API
  String _generateAvatarUrl(String seed) {
    // Bersihkan seed dari karakter khusus dan encode untuk URL
    String cleanSeed = Uri.encodeComponent(seed.trim());
    // Gunakan seed (biasanya nama) untuk konsistensi
    return '$_diceBearBaseUrl?seed=$cleanSeed';
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
