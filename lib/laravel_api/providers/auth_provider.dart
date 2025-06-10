import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'api_provider.dart';

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
} 