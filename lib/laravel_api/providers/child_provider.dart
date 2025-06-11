import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../models/user_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class ChildProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  final AuthProvider _authProvider;
  UserModel? _user;
  List<ChildModel> _children = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;

  ChildProvider(this._apiProvider, this._authProvider) {
    // Initialize with current auth state
    _user = _authProvider.user;
    
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
    
    // Instead of fetching immediately, we'll use a post-frame callback
    // to ensure this doesn't happen during build
    if (_user != null && !_initialized) {
      _initialized = true;
      // Use a microtask to schedule this after the current build frame
      Future.microtask(() {
        fetchChildren();
      });
    }
  }
  
  void _onAuthChanged() {
    final newUser = _authProvider.user;
    if (newUser != _user) {
      update(newUser);
    }
  }
  
  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  void update(UserModel? user) {
    _user = user;
    if (user != null) {
      // Use a microtask to ensure this doesn't run during build
      Future.microtask(() {
        fetchChildren();
      });
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
      // Use different endpoints based on user role
      String endpoint = 'children';
      
      // For teachers, fetch children created by them
      // For parents, fetch children connected to them
      if (_user!.isTeacher) {
        endpoint = 'children?teacher_id=${_user!.id}';
      } else if (_user!.isParent) {
        endpoint = 'children?parent_id=${_user!.id}';
      }
      
      final data = await _apiProvider.get(endpoint);
      
      if (data != null) {
        _children = (data as List).map((item) => ChildModel.fromJson(item)).toList();
      } else {
        _children = [];
      }
    } catch (e) {
      debugPrint('Error fetching children: $e');
      _error = 'Failed to load children. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChildModel?> addChild({
    required String name,
    required int age,
    required String parentId,
    DateTime? dateOfBirth,
    String? avatarUrl,
  }) async {
    if (_user == null || !_user!.isTeacher) {
      _error = 'Only teachers can add children';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('children', {
        'name': name,
        'age': age,
        'parent_id': parentId,
        'avatar_url': avatarUrl,
        'teacher_id': _user!.id, // Explicitly set teacher_id to current user
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      });
      
      if (data != null) {
        final child = ChildModel.fromJson(data);
        _children.add(child);
        notifyListeners();
        return child;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error adding child: $e');
      _error = 'Failed to add child. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChild({
    required String id,
    required String name,
    required int age,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? parentId,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.put('children/$id', {
        'name': name,
        'age': age,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (parentId != null) 'parent_id': parentId,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      });
      
      if (data != null) {
        final index = _children.indexWhere((child) => child.id == id);
        if (index != -1) {
          _children[index] = ChildModel.fromJson(data);
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating child: $e');
      _error = 'Failed to update child. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChild(String id) async {
    if (_user == null || !_user!.isTeacher) {
      _error = 'Only teachers can delete children';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.delete('children/$id');
      
      if (data != null) {
        _children.removeWhere((child) => child.id == id);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting child: $e');
      _error = 'Failed to delete child. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  ChildModel? getChildById(String id) {
    try {
      return _children.firstWhere((child) => child.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<ChildModel?> fetchChildById(String id) async {
    if (_user == null) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.get('children/$id');
      
      if (data != null) {
        final child = ChildModel.fromJson(data);
        
        // Update the list if child already exists
        final index = _children.indexWhere((c) => c.id == id);
        if (index != -1) {
          _children[index] = child;
        } else {
          _children.add(child);
        }
        
        notifyListeners();
        return child;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching child by id: $e');
      _error = 'Failed to load child data. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
