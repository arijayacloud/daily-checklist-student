import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/models/child_model.dart';
import '/models/user_model.dart';

class ChildProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  UserModel? _user;
  List<ChildModel> _children = [];
  bool _isLoading = false;
  String? _error;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void update(UserModel? user) {
    _user = user;
    if (user != null) {
      fetchChildren();
    } else {
      _children = [];
      notifyListeners();
    }
  }

  Future<void> fetchChildren() async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot;

      if (_user!.isTeacher) {
        // Teachers see all children assigned to them
        snapshot =
            await _firestore
                .collection('children')
                .where('teacherId', isEqualTo: _user!.id)
                .get();
      } else {
        // Parents see only their children
        snapshot =
            await _firestore
                .collection('children')
                .where('parentId', isEqualTo: _user!.id)
                .get();
      }

      _children =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ChildModel.fromJson({'id': doc.id, ...data});
          }).toList();
    } catch (e) {
      debugPrint('Error fetching children: $e');
      _error = 'Failed to load children. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChild({
    required String name,
    required int age,
    required String parentId,
    String? avatarUrl,
  }) async {
    if (_user == null || !_user!.isTeacher) {
      throw 'Only teachers can add children';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final childId = _uuid.v4();

      await _firestore.collection('children').doc(childId).set({
        'name': name,
        'age': age,
        'parentId': parentId,
        'teacherId': _user!.id,
        'avatarUrl': avatarUrl,
      });

      await fetchChildren();
    } catch (e) {
      debugPrint('Error adding child: $e');
      _error = 'Failed to add child. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateChild({
    required String id,
    required String name,
    required int age,
    String? avatarUrl,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('children').doc(id).update({
        'name': name,
        'age': age,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });

      await fetchChildren();
    } catch (e) {
      debugPrint('Error updating child: $e');
      _error = 'Failed to update child. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  ChildModel? getChildById(String id) {
    try {
      return _children.firstWhere((child) => child.id == id);
    } catch (e) {
      return null;
    }
  }
}
