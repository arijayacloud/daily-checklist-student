import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/user_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class ActivityProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  final AuthProvider _authProvider;
  UserModel? _user;
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;

  ActivityProvider(this._apiProvider, this._authProvider) {
    // Initialize with current auth state
    _user = _authProvider.user;
    
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
    
    // Fetch activities if user is already logged in, but defer it outside of build phase
    if (_user != null) {
      // Use microtask to schedule this after the current build frame
      Future.microtask(() {
        fetchActivities();
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
      fetchActivities();
    } else {
      _activities = [];
      notifyListeners();
    }
  }

  Future<void> fetchActivities() async {
    if (_user == null) {
      debugPrint('ActivityProvider: No user available, skipping fetch');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ActivityProvider: Fetching activities, user role: ${_user!.role}, id: ${_user!.id}');
      
      // Using activities endpoint - ideally the backend should filter by teacher
      final data = await _apiProvider.get('activities');
      
      if (data != null) {
        debugPrint('ActivityProvider: Received ${(data as List).length} activities');
        
        // Parse the activities
        List<ActivityModel> fetchedActivities = data.map((item) => ActivityModel.fromJson(item)).toList();
        
        if (_user!.isTeacher) {
          // For teachers, filter activities to show only those created by this teacher
          _activities = fetchedActivities.where((activity) => 
            activity.createdBy == _user!.id
          ).toList();
          
          debugPrint('ActivityProvider: Filtered to ${_activities.length} activities for teacher ${_user!.id}');
        } else if (_user!.isParent) {
          // For parents, show all activities to see what's assigned to their children
          _activities = fetchedActivities;
          debugPrint('ActivityProvider: Using all ${_activities.length} activities for parent ${_user!.id}');
        } else {
          // For other users
          _activities = fetchedActivities;
        }
        
        // Log IDs for debugging
        debugPrint('ActivityProvider: Activity IDs loaded: ${_activities.map((a) => a.id).join(", ")}');
      } else {
        debugPrint('ActivityProvider: No activities data received');
        _activities = [];
        _error = 'Failed to load activities. Empty response.';
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      _error = 'Failed to load activities. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ActivityModel?> addActivity({
    required String title,
    required String description,
    required String environment,
    required String difficulty,
    required double minAge,
    required double maxAge,
    int? duration,
    String? nextActivityId,
    required List<String> steps,
    List<String> photos = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('activities', {
        'title': title,
        'description': description,
        'environment': environment,
        'difficulty': difficulty,
        'min_age': minAge,
        'max_age': maxAge,
        'duration': duration,
        'next_activity_id': nextActivityId,
        'steps': steps,
        'photos': photos,
      });
      
      if (data != null) {
        final activity = ActivityModel.fromJson(data);
        _activities.add(activity);
        _isLoading = false;
        notifyListeners();
        return activity;
      }
      
      _isLoading = false;
      _error = 'Failed to add activity. Empty response.';
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      _error = 'Failed to add activity. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateActivity({
    required String id,
    required String title,
    required String description,
    required String environment,
    required String difficulty,
    required double minAge,
    required double maxAge,
    int? duration,
    String? nextActivityId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.put('activities/$id', {
        'title': title,
        'description': description,
        'environment': environment,
        'difficulty': difficulty,
        'min_age': minAge,
        'max_age': maxAge,
        'duration': duration,
        'next_activity_id': nextActivityId,
      });
      
      if (data != null) {
        final index = _activities.indexWhere((activity) => activity.id == id);
        if (index != -1) {
          _activities[index] = ActivityModel.fromJson(data);
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating activity: $e');
      _error = 'Failed to update activity. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCustomSteps({
    required String activityId,
    required List<String> steps,
    List<String> photos = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.post('activities/$activityId/steps', {
        'steps': steps,
        'photos': photos,
      });
      
      if (data != null) {
        final index = _activities.indexWhere((activity) => activity.id == activityId);
        if (index != -1) {
          _activities[index] = ActivityModel.fromJson(data);
          notifyListeners();
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error adding custom steps: $e');
      _error = 'Failed to add custom steps. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<ActivityModel> getActivitiesForAge(int childAge) {
    return _activities
        .where((activity) => activity.isAppropriateForAge(childAge.toDouble()))
        .toList();
  }

  ActivityModel? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      debugPrint('Activity with id $id not found: $e');
      return null;
    }
  }
}

