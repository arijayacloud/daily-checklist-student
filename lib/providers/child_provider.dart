import 'dart:async';
import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../services/child_service.dart';

class ChildProvider with ChangeNotifier {
  final ChildService _childService = ChildService();

  List<ChildModel> _children = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  bool _showAllChildren = false;

  // Getters
  List<ChildModel> get children {
    if (_searchQuery.isEmpty) {
      return _children;
    }

    final lowercaseQuery = _searchQuery.toLowerCase();
    return _children
        .where((child) => child.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get showAllChildren => _showAllChildren;

  // Stream subscription untuk anak-anak
  StreamSubscription<List<ChildModel>>? _childrenSubscription;

  // Load anak-anak untuk guru tertentu
  void loadChildrenForTeacher(
    String teacherId, {
    bool showAllChildren = false,
  }) {
    _isLoading = true;
    _errorMessage = '';
    _showAllChildren = true;
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _childrenSubscription?.cancel();

    // Subscribe ke stream anak-anak
    _childrenSubscription = _childService
        .getChildrenByTeacher(teacherId, getAllChildren: true)
        .listen(
          (children) {
            _children = children;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat data anak: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Toggle antara menampilkan semua anak atau hanya anak yang dikelola oleh guru tertentu
  void toggleShowAllChildren(String teacherId) {
    _showAllChildren = true;
    loadChildrenForTeacher(teacherId, showAllChildren: true);
  }

  // Load anak-anak untuk orangtua tertentu
  void loadChildrenForParent(String parentId) {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    // Batalkan subscription sebelumnya jika ada
    _childrenSubscription?.cancel();

    // Subscribe ke stream anak-anak
    _childrenSubscription = _childService
        .getChildrenByParent(parentId)
        .listen(
          (children) {
            _children = children;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Gagal memuat data anak: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Tambah anak baru
  Future<bool> addChild({
    required String name,
    required int age,
    required String parentId,
    required String teacherId,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _childService.addChild(
        name: name,
        age: age,
        parentId: parentId,
        teacherId: teacherId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan anak: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update data anak
  Future<bool> updateChild(ChildModel child) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _childService.updateChild(child);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate data anak: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hapus anak
  Future<bool> deleteChild(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _childService.deleteChild(id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus anak: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Dapatkan anak berdasarkan ID
  Future<ChildModel?> getChildById(String id) async {
    try {
      return await _childService.getChildById(id);
    } catch (e) {
      _errorMessage = 'Gagal mendapatkan data anak: $e';
      notifyListeners();
      return null;
    }
  }

  // Dispose
  @override
  void dispose() {
    _childrenSubscription?.cancel();
    super.dispose();
  }
}
