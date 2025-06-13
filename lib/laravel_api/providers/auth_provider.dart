import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_provider.dart';
import '/services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  AuthProvider(this._apiProvider) {
    _checkAuthStatus();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null || _apiProvider.isAuthenticated;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;
  
  String get userRole {
    final role = _user?.role;
    debugPrint('Getting user role: ${role ?? "null"} from user: ${_user?.email ?? "null"}');
    return role ?? 'parent'; 
  }
  
  String get userId => _user?.id ?? '';
  bool get isInitialized => _isInitialized;

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_apiProvider.isAuthenticated) {
        await _fetchUserData();
        // Double-check user data was correctly loaded
        if (_user != null) {
          debugPrint('Auth check complete - User: ${_user!.email}, Role: ${_user!.role}');
        } else {
          debugPrint('Auth check complete - No user data loaded but token exists');
        }
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final userData = await _apiProvider.getUserProfile();
      
      if (userData != null) {
        debugPrint('User data fetched: ${userData['email']}, Role: ${userData['role']}');
        _user = UserModel.fromJson(userData);
        notifyListeners();
      } else {
        if (_apiProvider.isAuthenticated && _user == null) {
          debugPrint('Token exists but user data not available, maintaining session');
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  // Force refresh user data
  Future<void> refreshUserData() async {
    await _fetchUserData();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = await _apiProvider.login(email, password);
      
      if (userData != null && userData['user'] != null) {
        _user = UserModel.fromJson(userData['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signOut() async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiProvider.logout();
    
    if (success) {
      _user = null;
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> createParentAccount(
    String email,
    String name,
    String password, {
    String phoneNumber = '',
    String address = '',
  }) async {
    if (_user == null || _user!.role != 'teacher') {
      _error = 'Hanya guru yang dapat membuat akun orang tua';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (name.isEmpty) {
        _error = 'Nama tidak boleh kosong';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userData = await _apiProvider.register(
        name: name,
        email: email,
        password: password,
        role: 'parent',
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        address: address.isNotEmpty ? address : null,
      );
      
      _isLoading = false;
      notifyListeners();
      return userData != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) {
      _error = 'Pengguna tidak login';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiProvider.changePassword(
        currentPassword,
        newPassword,
      );
      
      if (success && _user!.isTempPassword == true) {
        _user = _user!.copyWith(isTempPassword: false);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTeacherAccount(
    String email,
    String name,
    String password, {
    String phoneNumber = '',
    String address = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = await _apiProvider.register(
        name: name,
        email: email,
        password: password,
        role: 'teacher',
        phoneNumber: phoneNumber,
        address: address,
      );
      
      if (userData != null && userData['user'] != null) {
        _user = UserModel.fromJson(userData['user']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      _isLoading = false;
      if (data != null && data['token'] != null) {
        _apiProvider.setAuthToken(data['token']);
        // Fetch user data after registration
        await _fetchUserData();
        notifyListeners();
        return true;
      } else {
        _error = 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Login a user
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('auth/login', {
        'email': email,
        'password': password,
      });

      _isLoading = false;
      if (data != null && data['token'] != null) {
        // Save token
        _apiProvider.setAuthToken(data['token']);
        
        // Fetch user data after login
        await _fetchUserData();
        
        // Update FCM token with the auth token
        try {
          final fcmService = Provider.of<FCMService>(context, listen: false);
          await fcmService.updateTokenForUser(data['token']);
        } catch (e) {
          print('Error updating FCM token: $e');
        }
        
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout the user
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear FCM token before logging out
      try {
        final fcmService = Provider.of<FCMService>(context, listen: false);
        await fcmService.clearToken();
      } catch (e) {
        print('Error clearing FCM token: $e');
      }
      
      await _apiProvider.post('auth/logout', {});
      _user = null;
      _apiProvider.clearAuthToken();
      
      // Clear stored token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      _error = 'Failed to logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user has a temporary password
  bool get hasTempPassword => _user?.isTempPassword ?? false;

  // Update user's password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('auth/change-password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });

      _isLoading = false;
      if (data != null && data['success'] == true) {
        // Update user data to reflect password change
        if (_user != null) {
          _user = UserModel(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            role: _user!.role,
            isTempPassword: false, // Password is no longer temporary
          );
        }
        notifyListeners();
        return true;
      } else {
        _error = data?['message'] ?? 'Failed to update password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
} 