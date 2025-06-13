import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/config.dart';

class ApiProvider with ChangeNotifier {
  // Base URL for API from config
  final String baseUrl = AppConfig.apiBaseUrl;

  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  ApiProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    // Just load the token without validation
    // We'll only validate when needed for an actual request
    if (_token != null) {
      debugPrint('Token found in storage, assuming authenticated');
      _isAuthenticated = true;
      notifyListeners();
    } else {
      debugPrint('No token found in storage');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    _isLoading = true;
    _error = null;
    
    // Only notify listeners outside of build phase
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders(),
      );

      // If token is invalid, API will return 401 Unauthorized
      if (response.statusCode == 401 && _token != null) {
        // Only clear the token if explicitly unauthorized
        await _clearToken();
        _error = 'Sesi berakhir. Silakan login kembali.';
        debugPrint('API Error: Unauthorized, token cleared');
      }

      return _handleResponse(response);
    } catch (e) {
      _handleError('Network error: $e');
      return null;
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    
    // Only notify listeners outside of build phase
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      // Handle unauthorized
      if (response.statusCode == 401 && _token != null) {
        await _clearToken();
        _error = 'Sesi berakhir. Silakan login kembali.';
        debugPrint('API Error: Unauthorized on POST, token cleared');
      }

      return _handleResponse(response);
    } catch (e) {
      _handleError('Network error: $e');
      return null;
    }
  }

  // Generic PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    
    // Only notify listeners outside of build phase
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      // Handle unauthorized
      if (response.statusCode == 401 && _token != null) {
        await _clearToken();
        _error = 'Sesi berakhir. Silakan login kembali.';
        debugPrint('API Error: Unauthorized on PUT, token cleared');
      }

      return _handleResponse(response);
    } catch (e) {
      _handleError('Network error: $e');
      return null;
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint) async {
    _isLoading = true;
    _error = null;
    
    // Only notify listeners outside of build phase
    Future.microtask(() {
      notifyListeners();
    });

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders(),
      );

      // Handle unauthorized
      if (response.statusCode == 401 && _token != null) {
        await _clearToken();
        _error = 'Sesi berakhir. Silakan login kembali.';
        debugPrint('API Error: Unauthorized on DELETE, token cleared');
      }

      return _handleResponse(response);
    } catch (e) {
      _handleError('Network error: $e');
      return null;
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    _isLoading = false;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        notifyListeners();
        return {};
      }
      
      final data = json.decode(response.body);
      notifyListeners();
      return data;
    } else {
      try {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error occurred';
        _handleError(errorMessage);
      } catch (e) {
        _handleError('Error: ${response.statusCode}');
      }
      return null;
    }
  }

  // Handle error
  void _handleError(String errorMessage) {
    _isLoading = false;
    _error = errorMessage;
    debugPrint('API Error: $_error');
    notifyListeners();
  }

  // Get headers for requests
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final data = await post('login', {
      'email': email,
      'password': password,
    });

    if (data != null && data['token'] != null) {
      await _saveToken(data['token']);
      return data;
    }
    
    return null;
  }

  // Register
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
  }) async {
    // Different endpoints for teacher and parent registration
    final endpoint = role == 'parent' ? 'register-parent' : 'register';
    
    final data = await post(endpoint, {
      'name': name,
      'email': email,
      'password': password,
      // Only include role for teacher registration
      if (role == 'teacher') 'role': role,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      if (address != null && address.isNotEmpty) 'address': address,
    });

    // For teacher registration, save token
    if (data != null && role == 'teacher' && data['token'] != null) {
      await _saveToken(data['token']);
    }
    
    return data;
  }

  // Logout
  Future<bool> logout() async {
    if (_token == null) return true;

    final data = await post('logout', {});
    
    if (data != null) {
      await _clearToken();
      return true;
    }
    
    return false;
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    return await get('user');
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final data = await post('change-password', {
      'new_password': newPassword,
    });
    
    return data != null;
  }

  // Set authentication token (for new login/registration flows)
  void setAuthToken(String token) {
    _token = token;
    _isAuthenticated = true;
    _saveTokenToSharedPreferences(token);
    notifyListeners();
  }
  
  // Clear authentication token (for logout)
  void clearAuthToken() {
    _token = null;
    _isAuthenticated = false;
    _removeTokenFromSharedPreferences();
    notifyListeners();
  }

  // Helper method to save token to SharedPreferences
  Future<void> _saveTokenToSharedPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      debugPrint('Error saving token to SharedPreferences: $e');
    }
  }
  
  // Helper method to remove token from SharedPreferences
  Future<void> _removeTokenFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error removing token from SharedPreferences: $e');
    }
  }
} 