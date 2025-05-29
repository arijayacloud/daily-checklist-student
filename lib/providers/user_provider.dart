import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  List<UserModel> _parents = [];
  List<UserModel> _teachers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<UserModel> get parents => _parents;
  List<UserModel> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Membuat akun guru baru menggunakan UserService
  Future<Map<String, dynamic>> createTeacherAccount({
    required String name,
    required String email,
    String? creatorId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _userService.createTeacherAccount(
        name: name,
        email: email,
        creatorId: creatorId,
      );

      // Jika berhasil, refresh data guru
      if (result['success']) {
        await loadTeachers();
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'password': null,
      };
    }
  }

  // Membuat akun orangtua baru menggunakan UserService
  Future<Map<String, dynamic>> createParentAccount({
    required String name,
    required String email,
    required String teacherId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _userService.createParentAccount(
        name: name,
        email: email,
        teacherId: teacherId,
      );

      // Jika berhasil, refresh data orangtua
      if (result['success']) {
        await loadParents(teacherId);
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
        'password': null,
      };
    }
  }

  Future<void> loadParents(String teacherId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Gunakan service untuk memuat orangtua
      _parents = await _userService.loadUsersByRole('parent');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTeachers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Gunakan service untuk memuat guru
      _teachers = await _userService.loadUsersByRole('teacher');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String userId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Gunakan service untuk menghapus pengguna
      final success = await _userService.deleteUser(userId);

      if (success) {
        // Refresh the lists
        _parents.removeWhere((user) => user.id == userId);
        _teachers.removeWhere((user) => user.id == userId);
      } else {
        _errorMessage = 'Gagal menghapus pengguna';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAllUsers(String teacherId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Muat data orangtua dan guru menggunakan service
      _parents = await _userService.loadUsersByRole('parent');
      _teachers = await _userService.loadUsersByRole('teacher');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
