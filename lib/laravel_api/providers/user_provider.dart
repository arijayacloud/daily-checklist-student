import 'package:http/http.dart' as http;
import 'dart:convert';
import '/laravel_api/models/user_model.dart';
import 'package:flutter/material.dart';
import '/laravel_api/providers/api_provider.dart';
import '/laravel_api/providers/auth_provider.dart';

class UserProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  final AuthProvider _authProvider;
  
  List<UserModel> _teachers = [];
  List<UserModel> _parents = [];
  bool _isLoading = false;
  String? _error;
  Map<String, String> _userNames = {}; // Cache untuk nama pengguna berdasarkan ID

  List<UserModel> get teachers => _teachers;
  List<UserModel> get parents => _parents;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;

  UserProvider(this._apiProvider, this._authProvider);

  // Mengambil data guru dari API
  Future<void> fetchTeachers() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    try {
      _isLoading = true;
      // Notify listeners outside of the build phase
      Future.microtask(() => notifyListeners());

      final data = await _apiProvider.get('users?role=teacher');
      
      if (data != null) {
        // Handle both list and map response formats
        List<dynamic> usersList;
        if (data is Map && data.containsKey('data')) {
          usersList = data['data'] as List;
        } else if (data is List) {
          usersList = data;
        } else {
          _error = 'Unexpected data format from API';
          _teachers = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        _teachers = usersList.map((item) => UserModel.fromJson(item)).toList();

        // Simpan nama guru ke cache
        for (var teacher in _teachers) {
          _userNames[teacher.id] = teacher.name;
        }
      } else {
        _teachers = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      _isLoading = false;
      _error = 'Failed to load teachers. Please try again.';
      notifyListeners();
    }
  }

  // Mengambil data orang tua dari API
  Future<void> fetchParents({bool filterByCreatedBy = false}) async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    try {
      _isLoading = true;
      // Notify listeners outside of the build phase
      Future.microtask(() => notifyListeners());

      // If we need to filter by created_by, add the auth user's ID as a query param
      String endpoint = 'users?role=parent';
      if (filterByCreatedBy && _authProvider.isAuthenticated) {
        endpoint += '&created_by=${_authProvider.userId}';
      }

      final data = await _apiProvider.get(endpoint);
      
      if (data != null) {
        // Handle both list and map response formats
        List<dynamic> usersList;
        if (data is Map && data.containsKey('data')) {
          usersList = data['data'] as List;
        } else if (data is List) {
          usersList = data;
        } else {
          _error = 'Unexpected data format from API';
          _parents = [];
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        _parents = usersList.map((item) => UserModel.fromJson(item)).toList();

        // Simpan nama orang tua ke cache
        for (var parent in _parents) {
          _userNames[parent.id] = parent.name;
        }
      } else {
        _parents = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching parents: $e');
      _isLoading = false;
      _error = 'Failed to load parents. Please try again.';
      notifyListeners();
    }
  }

  // Mengambil data pengguna berdasarkan ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final data = await _apiProvider.get('users/$userId');
      
      if (data != null) {
        final user = UserModel.fromJson(data);
        
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

    // Jika tidak ditemukan, ambil data dari API dan simpan ke cache
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

    // Jika tidak ditemukan, ambil data dari API dan simpan ke cache
    getUserById(parentId).then((user) {
      if (user != null) {
        _userNames[parentId] = user.name;
        notifyListeners();
      }
    });

    return null;
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    required String id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? profilePicture,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final data = await _apiProvider.put('users/$id', {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (address != null) 'address': address,
        if (profilePicture != null) 'profile_picture': profilePicture,
      });
      
      if (data != null) {
        // Update cache
        if (name != null) {
          _userNames[id] = name;
        }
        
                 // If this is the current user, update their data
         if (_authProvider.userId == id && name != null) {
           // We can't directly refresh the auth user data
           // The changes will be reflected on next login
         }
        
        // Update lists if needed
        if (_teachers.any((t) => t.id == id)) {
          final index = _teachers.indexWhere((t) => t.id == id);
          if (index != -1) {
            _teachers[index] = UserModel.fromJson(data);
          }
        }
        
        if (_parents.any((p) => p.id == id)) {
          final index = _parents.indexWhere((p) => p.id == id);
          if (index != -1) {
            _parents[index] = UserModel.fromJson(data);
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      _error = 'Failed to update profile. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}