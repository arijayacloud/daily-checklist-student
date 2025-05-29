import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _parents = [];
  List<UserModel> _teachers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<UserModel> get parents => _parents;
  List<UserModel> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadParents(String teacherId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'parent')
              .where('createdBy', isEqualTo: teacherId)
              .get();

      _parents =
          querySnapshot.docs
              .map(
                (doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

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
      final QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'teacher')
              .get();

      _teachers =
          querySnapshot.docs
              .map(
                (doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

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
      await _firestore.collection('users').doc(userId).delete();

      // Refresh the lists
      _parents.removeWhere((user) => user.id == userId);
      _teachers.removeWhere((user) => user.id == userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
