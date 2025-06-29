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
    // Don't skip fetching even if we have teachers
    // This ensures we always have the latest data
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('UserProvider: Fetching teachers from API');
      
      // Use the new dedicated endpoint for teachers
      final response = await _apiProvider.get('teachers');
      
      if (response != null) {
        if (response is List) {
          debugPrint('UserProvider: Successfully received ${response.length} teachers');
          _teachers = response
              .map((teacherJson) => UserModel.fromJson(teacherJson))
              .toList();
          
          // Cache teachers by ID for quick access
          for (var teacher in _teachers) {
            _userCache[teacher.id] = teacher;
            _userNames[teacher.id] = teacher.name;
          }
        } else if (response is Map) {
          // Check for error messages or empty response
          if (response.containsKey('message')) {
            debugPrint('UserProvider: API message: ${response['message']}');
            
            // Handle "No query results" message gracefully
            if (response['message'].toString().contains('No query results')) {
              debugPrint('UserProvider: No teachers found in database');
              _teachers = []; // Set to empty list instead of throwing an error
            } else {
              // Other error messages
              _error = response['message'];
              debugPrint('UserProvider: Error message from API: $_error');
            }
          } else {
            // Empty or unexpected map response
            debugPrint('UserProvider: Received empty or unexpected map response');
            _teachers = [];
          }
        } else {
          // Unexpected response format
          debugPrint('UserProvider: Unexpected response format: ${response.runtimeType}');
          _teachers = []; 
        }
      } else {
        // Null response
        debugPrint('UserProvider: Received null response from API');
        _teachers = []; 
      }
    } catch (e) {
      debugPrint('UserProvider: Error fetching teachers: $e');
      _error = 'Failed to load teachers: $e';
      _teachers = []; 
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

      // Check if user is superadmin - always fetch all parents for superadmin
      bool isSuperadmin = _authProvider.user?.isSuperadmin ?? false;
      
      // Build endpoint based on role and filtering requirements
      String endpoint = 'users?role=parent';
      
      // For teachers: filter by created_by if requested and not superadmin
      if (filterByCreatedBy && _authProvider.isAuthenticated && !isSuperadmin) {
        endpoint += '&created_by=${_authProvider.userId}';
        debugPrint('UserProvider: Fetching parents created by teacher ${_authProvider.userId}');
      } else if (isSuperadmin) {
        // Superadmin sees all parents
        debugPrint('UserProvider: Fetching all parents for superadmin');
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
        debugPrint('UserProvider: Loaded ${_parents.length} parents');

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

  // Fetch all users - useful for superadmin user management
  Future<List<UserModel>> fetchAllUsers({String? role}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Build endpoint based on requested role filter
      String endpoint = 'users';
      if (role != null && role.isNotEmpty) {
        endpoint += '?role=$role';
      }
      
      final data = await _apiProvider.get(endpoint);
      List<UserModel> users = [];
      
      if (data != null) {
        // Handle both list and map response formats
        List<dynamic> usersList;
        if (data is Map && data.containsKey('data')) {
          usersList = data['data'] as List;
        } else if (data is List) {
          usersList = data;
        } else {
          _error = 'Unexpected data format from API';
          _isLoading = false;
          notifyListeners();
          return [];
        }
        
        users = usersList.map((item) => UserModel.fromJson(item)).toList();
        
        // Update cached teachers if role is teacher or if no role filter
        if (role == 'teacher' || role == null) {
          final teachers = users.where((user) => user.role == 'teacher').toList();
          _teachers = teachers;
          
          // Update cache
          for (var teacher in teachers) {
            _userCache[teacher.id] = teacher;
            _userNames[teacher.id] = teacher.name;
          }
        }
        
        debugPrint('UserProvider: Fetched ${users.length} users with role: ${role ?? "all"}');
      }
      
      _isLoading = false;
      notifyListeners();
      return users;
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _isLoading = false;
      _error = 'Failed to load users. Please try again.';
      notifyListeners();
      return [];
    }
  }
  
  // Create a new user - handles different endpoints for teacher and parent
  Future<UserModel?> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
    bool isTempPassword = true,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Prepare the common data payload
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        if (address != null && address.isNotEmpty) 'address': address,
      };
      
      // Add is_temp_password for parent accounts
      if (role == 'parent') {
        userData['is_temp_password'] = isTempPassword;
      }
      
      // Choose endpoint based on role
      String endpoint;
      if (role == 'teacher') {
        // Check if the current user is superadmin
        if (_authProvider.user?.isSuperadmin == true) {
          // Superadmins use the protected create-teacher endpoint
          endpoint = 'create-teacher';
          debugPrint('UserProvider: Creating teacher account using superadmin endpoint');
        } else {
          // Public endpoint for teacher registration
          endpoint = 'register';
          debugPrint('UserProvider: Creating teacher account using public endpoint');
        }
      } else if (role == 'parent') {
        // Protected endpoint for parent registration
        endpoint = 'register-parent';
        debugPrint('UserProvider: Creating parent account using protected endpoint');
      } else {
        // Generic endpoint for other roles (superadmin, etc.)
        endpoint = 'users';
        userData['role'] = role;
        userData['is_temp_password'] = isTempPassword;
        debugPrint('UserProvider: Creating ${role} account using generic endpoint');
      }
      
      final data = await _apiProvider.post(endpoint, userData);
      
      if (data != null) {
        // Extract user data from response which might be nested
        final userData = data is Map && data.containsKey('user') ? data['user'] : data;
        final user = UserModel.fromJson(userData);
        
        debugPrint('UserProvider: Successfully created ${user.role} account for ${user.name}');
        
        // Update local lists based on user role
        if (user.role == 'teacher') {
          _teachers.add(user);
        } else if (user.role == 'parent') {
          _parents.add(user);
        }
        
        // Update cache
        _userCache[user.id] = user;
        _userNames[user.id] = user.name;
        
        _isLoading = false;
        notifyListeners();
        return user;
      }
      
      _error = 'Failed to create user: Server returned null';
      debugPrint('UserProvider: Server returned null when creating user');
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('UserProvider: Error creating user: $e');
      _isLoading = false;
      _error = 'Failed to create user: $e';
      notifyListeners();
      return null;
    }
  }
}