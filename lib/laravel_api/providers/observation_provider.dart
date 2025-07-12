import 'package:flutter/material.dart';
import '../models/observation_model.dart';
import '../models/user_model.dart';
import '../models/child_model.dart';
import '../models/planning_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class ObservationProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  final AuthProvider _authProvider;
  UserModel? _user;
  List<ObservationModel> _observations = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  List<ObservationModel> get observations => _observations;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;

  ObservationProvider(this._apiProvider, this._authProvider) {
    // Initialize with current auth state
    _user = _authProvider.user;
    
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
    
    // Initialize if user is already logged in
    if (_user != null && !_initialized) {
      _initialized = true;
      // Use a microtask to schedule this after the current build frame
      Future.microtask(() {
        // Don't fetch all observations on init - wait for specific plan requests
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
    if (user == null) {
      _observations = [];
      notifyListeners();
    }
  }

  // Fetch observations for a specific plan
  Future<void> fetchObservationsForPlan(String planId) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.get('plans/$planId/observations');
      
      if (data != null) {
        // Handle the response structure: { plan: {...}, observations: [...] }
        List<dynamic> observationsList = [];
        
        if (data is Map && data.containsKey('observations')) {
          observationsList = data['observations'] as List;
        } else if (data is List) {
          observationsList = data;
        } else {
          throw Exception('Unexpected data format');
        }
        
        _observations = observationsList
            .map((item) => ObservationModel.fromJson(item))
            .toList();
            
        debugPrint('ObservationProvider: Loaded ${_observations.length} observations for plan $planId');
      } else {
        _observations = [];
      }
    } catch (e) {
      debugPrint('Error fetching observations: $e');
      _error = 'Failed to load observations. Please try again.';
      _observations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new observation
  Future<ObservationModel?> createObservation({
    required String planId,
    required String childId,
    required DateTime observationDate,
    String? observationResult,
    required Map<String, bool> conclusions,
  }) async {
    // Only teachers and superadmins can create observations
    if (_user == null || (!_user!.isTeacher && !_user!.isSuperadmin)) {
      _error = 'Hanya guru dan administrator yang dapat membuat observasi';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('plans/$planId/observations', {
        'child_id': childId,
        'observation_date': observationDate.toIso8601String().split('T')[0],
        'observation_result': observationResult,
        'conclusions': conclusions,
      });
      
      if (data != null) {
        final observation = ObservationModel.fromJson(data);
        _observations.add(observation);
        notifyListeners();
        return observation;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating observation: $e');
      _error = 'Failed to create observation. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a single observation
  Future<ObservationModel?> getObservation(String planId, String observationId) async {
    if (_user == null) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.get('plans/$planId/observations/$observationId');
      
      if (data != null) {
        final observation = ObservationModel.fromJson(data);
        return observation;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching observation: $e');
      _error = 'Failed to load observation. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an observation
  Future<ObservationModel?> updateObservation({
    required String planId,
    required String observationId,
    DateTime? observationDate,
    String? observationResult,
    Map<String, bool>? conclusions,
  }) async {
    // Only teachers and superadmins can update observations
    if (_user == null || (!_user!.isTeacher && !_user!.isSuperadmin)) {
      _error = 'Hanya guru dan administrator yang dapat mengupdate observasi';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> updateData = {};
      
      if (observationDate != null) {
        updateData['observation_date'] = observationDate.toIso8601String().split('T')[0];
      }
      if (observationResult != null) {
        updateData['observation_result'] = observationResult;
      }
      if (conclusions != null) {
        updateData['conclusions'] = conclusions;
      }

      final data = await _apiProvider.put('plans/$planId/observations/$observationId', updateData);
      
      if (data != null) {
        final updatedObservation = ObservationModel.fromJson(data);
        
        // Update the observation in the local list
        final index = _observations.indexWhere((obs) => obs.id == observationId);
        if (index != -1) {
          _observations[index] = updatedObservation;
        }
        
        notifyListeners();
        return updatedObservation;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error updating observation: $e');
      _error = 'Failed to update observation. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an observation
  Future<bool> deleteObservation(String planId, String observationId) async {
    // Only teachers and superadmins can delete observations
    if (_user == null || (!_user!.isTeacher && !_user!.isSuperadmin)) {
      _error = 'Hanya guru dan administrator yang dapat menghapus observasi';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.delete('plans/$planId/observations/$observationId');
      
      if (data != null) {
        _observations.removeWhere((obs) => obs.id == observationId);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting observation: $e');
      _error = 'Failed to delete observation. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get observations for a specific child in a plan
  Future<void> fetchChildObservations(String planId, String childId) async {
    if (_user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.get('plans/$planId/children/$childId/observations');
      
      if (data != null) {
        // Handle the response structure: { plan: {...}, child: {...}, observations: [...] }
        List<dynamic> observationsList = [];
        
        if (data is Map && data.containsKey('observations')) {
          observationsList = data['observations'] as List;
        } else if (data is List) {
          observationsList = data;
        } else {
          throw Exception('Unexpected data format');
        }
        
        _observations = observationsList
            .map((item) => ObservationModel.fromJson(item))
            .toList();
            
        debugPrint('ObservationProvider: Loaded ${_observations.length} observations for child $childId in plan $planId');
      } else {
        _observations = [];
      }
    } catch (e) {
      debugPrint('Error fetching child observations: $e');
      _error = 'Failed to load child observations. Please try again.';
      _observations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  List<ObservationModel> getObservationsForChild(String childId) {
    return _observations.where((obs) => obs.childId == childId).toList();
  }

  List<ObservationModel> getObservationsForDate(DateTime date) {
    return _observations.where((obs) => 
      obs.observationDate.year == date.year &&
      obs.observationDate.month == date.month &&
      obs.observationDate.day == date.day
    ).toList();
  }

  ObservationModel? getObservationById(String id) {
    try {
      return _observations.firstWhere((obs) => obs.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear observations (useful when switching between plans)
  void clearObservations() {
    _observations = [];
    notifyListeners();
  }

  // Get statistics
  Map<String, dynamic> getObservationStats() {
    if (_observations.isEmpty) {
      return {
        'total': 0,
        'completed': 0,
        'average_completion': 0.0,
      };
    }

    int totalObservations = _observations.length;
    int completedObservations = _observations.where((obs) => obs.allConclusionsTrue).length;
    double averageCompletion = _observations.fold(0.0, (sum, obs) => sum + obs.completionPercentage) / totalObservations;

    return {
      'total': totalObservations,
      'completed': completedObservations,
      'average_completion': averageCompletion,
    };
  }
}