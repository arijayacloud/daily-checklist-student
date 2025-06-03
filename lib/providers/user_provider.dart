import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _teachers = [];
  List<UserModel> _parents = [];
  bool _isLoading = false;
  Map<String, String> _userNames =
      {}; // Cache untuk nama pengguna berdasarkan ID

  List<UserModel> get teachers => _teachers;
  List<UserModel> get parents => _parents;
  bool get isLoading => _isLoading;

  // Mengambil data guru dari Firestore
  Future<void> fetchTeachers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .get();

      _teachers =
          snapshot.docs
              .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();

      // Simpan nama guru ke cache
      for (var teacher in _teachers) {
        _userNames[teacher.id] = teacher.name;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil data orang tua dari Firestore
  Future<void> fetchParents() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'parent')
              .get();

      _parents =
          snapshot.docs
              .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
              .toList();

      // Simpan nama orang tua ke cache
      for (var parent in _parents) {
        _userNames[parent.id] = parent.name;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching parents: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil data pengguna berdasarkan ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final user = UserModel.fromJson({'id': userId, ...data});

        // Simpan nama ke cache
        _userNames[userId] = user.name;

        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user by id: $e');
      return null;
    }
  }

  // Mendapatkan nama guru berdasarkan ID
  String? getTeacherNameById(String teacherId) {
    // Cek apakah nama sudah ada di cache
    if (_userNames.containsKey(teacherId)) {
      return _userNames[teacherId];
    }

    // Cari di list guru
    final teacher = _teachers.firstWhere(
      (teacher) => teacher.id == teacherId,
      orElse: () => UserModel(id: '', email: '', name: '', role: 'teacher'),
    );

    if (teacher.id.isNotEmpty) {
      _userNames[teacherId] = teacher.name;
      return teacher.name;
    }

    // Jika tidak ditemukan, ambil data dari Firestore dan simpan ke cache
    getUserById(teacherId).then((user) {
      if (user != null) {
        _userNames[teacherId] = user.name;
        notifyListeners();
      }
    });

    return null;
  }

  // Mendapatkan nama orang tua berdasarkan ID
  String? getParentNameById(String parentId) {
    // Cek apakah nama sudah ada di cache
    if (_userNames.containsKey(parentId)) {
      return _userNames[parentId];
    }

    // Cari di list orang tua
    final parent = _parents.firstWhere(
      (parent) => parent.id == parentId,
      orElse: () => UserModel(id: '', email: '', name: '', role: 'parent'),
    );

    if (parent.id.isNotEmpty) {
      _userNames[parentId] = parent.name;
      return parent.name;
    }

    // Jika tidak ditemukan, ambil data dari Firestore dan simpan ke cache
    getUserById(parentId).then((user) {
      if (user != null) {
        _userNames[parentId] = user.name;
        notifyListeners();
      }
    });

    return null;
  }
}
