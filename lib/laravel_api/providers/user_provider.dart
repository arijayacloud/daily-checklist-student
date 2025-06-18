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
  Map<String, UserModel> _userCache = {};

  List<UserModel> get teachers => _teachers;
  List<UserModel> get parents => _parents;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;

  UserProvider(this._apiProvider, this._authProvider);

  // Mengambil data guru dari API
  Future<void> fetchTeachers() async {
    if (_teachers.isNotEmpty) {
      // If we already have teachers, don't fetch again
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiProvider.get('users/teachers');
      if (response != null) {
        if (response is List) {
          _teachers = response
              .map((teacherJson) => UserModel.fromJson(teacherJson))
              .toList();
          
          // Cache teachers by ID for quick access
          for (var teacher in _teachers) {
            _userCache[teacher.id] = teacher;
            _userNames[teacher.id] = teacher.name;
          }
        } else if (response is Map && response.containsKey('message') && 
                  response['message'].toString().contains('No query results')) {
          // Handle "No query results for model" error gracefully
          debugPrint('No teachers found in database - using empty list');
          _teachers = []; // Set to empty list instead of throwing an error
        } else {
          debugPrint('Unexpected response format when fetching teachers: $response');
          _teachers = []; // Default to empty list on unexpected format
        }
      } else {
        _teachers = []; // Default to empty list if response is null
      }
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      _error = e.toString();
      _teachers = []; // Ensure we have an empty list even on error
    } finally {
      _isLoading = false;
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
  Future<UserModel?> getUserById(String id) async {
    // Check cache first
    if (_userCache.containsKey(id)) {
      return _userCache[id];
    }
    
    try {
      final response = await _apiProvider.get('users/$id');
      if (response != null) {
        final user = UserModel.fromJson(response);
        _userCache[id] = user; // Add to cache
        notifyListeners();
        return user;
      }
    } catch (e) {
      debugPrint('Error fetching user $id: $e');
    }
    
    return null;
  }

  // Mendapatkan nama guru berdasarkan ID
  String? getTeacherNameById(String? id) {
    if (id == null || id.isEmpty) return "Tidak ada guru";
    
    // Check cache first
    if (_userCache.containsKey(id)) {
      return _userCache[id]!.name;
    }
    
    // Check teachers list
    final teacher = _teachers.firstWhere(
      (t) => t.id == id,
      orElse: () => UserModel(
        id: '', 
        name: '', 
        email: '', 
        role: '',
      ),
    );
    
    if (teacher.id.isNotEmpty) {
      return teacher.name;
    }
    
    // If not found, fetch it (but return a default name for now)
    getUserById(id); // Don't await - will update cache in background
    return "Guru";
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