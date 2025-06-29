import 'package:flutter/material.dart';
import '../models/planning_model.dart';
import '../providers/api_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class PlanningProvider with ChangeNotifier {
  final ApiProvider _apiProvider;
  final AuthProvider _authProvider;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;
  List<Planning> _plans = [];
  bool _initialized = false;
  String? _currentChildId; // Track current child ID for activity completion

  PlanningProvider(this._apiProvider, this._authProvider) {
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
        fetchPlans();
      });
    }
  }
  
  void _onAuthChanged() {
    final newUser = _authProvider.user;
    if (newUser != _user) {
      _user = newUser;
      if (newUser != null) {
        // Use a microtask to ensure this doesn't run during build
        Future.microtask(() {
          fetchPlans();
        });
      } else {
        _plans = [];
        notifyListeners();
      }
    }
  }
  
  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  List<Planning> get plans => _plans;
  bool get isLoading => _isLoading || _apiProvider.isLoading;
  String? get error => _error ?? _apiProvider.error;
  String? get currentChildId => _currentChildId;

  // Set current child ID for activity completion
  void setCurrentChildId(String childId) {
    _currentChildId = childId;
    notifyListeners();
  }

  // Fetch all plans (for teachers or parents)
  Future<void> fetchPlans({String? childId}) async {
    _isLoading = true;
    _error = null;
    
    // If childId is provided, update the current child ID for activity completion
    if (childId != null) {
      _currentChildId = childId;
    }
    
    notifyListeners();

    try {
      // Build the endpoint URL based on whether a child ID is specified
      String endpoint;
      
      // Check if user is superadmin
      if (_user != null && _user!.isSuperadmin) {
        // Superadmin can see all plans without filtering
        endpoint = 'plans';
        debugPrint('PlanningProvider: Fetching all plans for superadmin');
      } else if (childId != null) {
        // For specific child view (used by both teachers and parents)
        endpoint = 'plans?child_id=$childId';
        debugPrint('PlanningProvider: Fetching plans for specific child: $childId');
      } else {
        // Default case - filtered by user role (teacher sees their plans)
        endpoint = 'plans';
        debugPrint('PlanningProvider: Fetching plans for ${_user?.role ?? 'unknown role'}');
      }
      
      final data = await _apiProvider.get(endpoint);
      
      if (data != null) {
        // Check if data is a map with a 'data' property or directly a list
        List<dynamic> plansList;
        if (data is Map && data.containsKey('data')) {
          plansList = data['data'] as List;
        } else if (data is List) {
          plansList = data;
        } else {
          throw Exception('Unexpected data format');
        }
        
        _plans = plansList.map((item) => Planning.fromJson(item)).toList();
        debugPrint('PlanningProvider: Successfully loaded ${_plans.length} plans');
      } else {
        _error = 'Failed to load plans';
        debugPrint('PlanningProvider: Failed to load plans - null response');
      }
    } catch (e) {
      _error = 'Failed to load plans: $e';
      debugPrint('PlanningProvider: Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new plan
  Future<Planning?> createPlan({
    required DateTime startDate,
    String? childId,
    List<String>? childIds,
    required List<PlannedActivity> activities,
    required String type,
    String? teacherId, // Add optional teacherId parameter for superadmin
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert activities to the format expected by the API
      List<Map<String, dynamic>> activitiesData = activities.map((activity) {
        return {
          'activity_id': activity.activityId.toString(), // Ensure activity_id is sent as string
          'scheduled_date': activity.scheduledDate.toIso8601String().split('T')[0],
          'scheduled_time': activity.scheduledTime,
          'reminder': activity.reminder, // Send as boolean
        };
      }).toList();

      final Map<String, dynamic> planData = {
        'type': type,
        'start_date': startDate.toIso8601String().split('T')[0],
        'activities': activitiesData, // Add activities to the request
      };
      
      // Handle teacher selection for superadmin
      if (_user != null && _user!.isSuperadmin && teacherId != null) {
        planData['teacher_id'] = teacherId;
        debugPrint('PlanningProvider: Superadmin creating plan for teacher: $teacherId');
      }
      
      // Handle child selection - prioritize childIds if provided
      if (childIds != null && childIds.isNotEmpty) {
        planData['child_ids'] = childIds;
      } else if (childId != null && childId.isNotEmpty) {
        planData['child_id'] = childId;
      }

      final data = await _apiProvider.post('plans', planData);
      
      if (data != null) {
        final newPlan = Planning.fromJson(data);
        _plans.add(newPlan);
        notifyListeners();
        return newPlan;
      } else {
        _error = 'Failed to create plan';
        return null;
      }
    } catch (e) {
      _error = 'Failed to create plan: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing plan
  Future<Planning?> updatePlan({
    required int planId,
    String? type,
    DateTime? startDate,
    String? childId,
    List<String>? childIds,
    List<PlannedActivity>? activities,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> updateData = {};
      
      if (type != null) updateData['type'] = type;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      
      // Handle child selection updates
      if (childIds != null) {
        updateData['child_ids'] = childIds;
      } else if (childId != null) {
        updateData['child_id'] = childId;
      }
      
      if (activities != null) {
        updateData['activities'] = activities.map((activity) {
          Map<String, dynamic> activityData = {
            'activity_id': activity.activityId,
            'scheduled_date': activity.scheduledDate.toIso8601String().split('T')[0],
            'scheduled_time': activity.scheduledTime,
            'reminder': activity.reminder,
          };
          
          if (activity.id != null) {
            activityData['id'] = activity.id;
          }
          
          return activityData;
        }).toList();
      }

      final data = await _apiProvider.put('plans/$planId', updateData);
      
      if (data != null) {
        final updatedPlan = Planning.fromJson(data);
        
        // Update the plan in the local list
        final index = _plans.indexWhere((plan) => plan.id == planId);
        if (index != -1) {
          _plans[index] = updatedPlan;
        }
        
        notifyListeners();
        return updatedPlan;
      } else {
        _error = 'Failed to update plan';
        return null;
      }
    } catch (e) {
      _error = 'Failed to update plan: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a planned activity as completed or not completed for a specific child
  Future<bool> markActivityAsCompleted(int activityId, bool completed, {String? childId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the provided childId or fallback to currentChildId
      final String actualChildId = childId ?? _currentChildId ?? '';
      
      if (actualChildId.isEmpty) {
        _error = 'Child ID is required';
        return false;
      }
      
      final response = await _apiProvider.put(
        'planned-activities/$activityId/status',
        {
          'completed': completed,
          'child_id': actualChildId,
        },
      );
      
      if (response != null && response is Map<String, dynamic>) {
        // Use enhanced response with all_child_statuses and plan_progress data
        if (response.containsKey('data')) {
          final data = response['data'];
          
          // Find the activity in our local data
          for (int i = 0; i < _plans.length; i++) {
            final activityIndex = _plans[i].activities.indexWhere((a) => a.id == activityId);
            if (activityIndex != -1) {
              final plan = _plans[i];
              final activity = plan.activities[activityIndex];
              
              // Create a new activity with updated completion data
              Map<String, bool> completionByChild = Map.from(activity.completionByChild);
              
              // Update specific child completion status
              completionByChild[actualChildId] = completed;
              
              // Update from all_child_statuses if available
              if (data.containsKey('all_child_statuses') && data['all_child_statuses'] is Map) {
                final Map<String, dynamic> rawStatuses = Map<String, dynamic>.from(data['all_child_statuses']);
                
                rawStatuses.forEach((childId, status) {
                  completionByChild[childId] = status == true || status == 1;
                });
              }
              
              // Create a new activity with updated data
              final updatedActivity = PlannedActivity(
                id: activity.id,
                planId: activity.planId,
                activityId: activity.activityId,
                scheduledDate: activity.scheduledDate,
                scheduledTime: activity.scheduledTime,
                reminder: activity.reminder,
                // Use is_completed if available, otherwise infer from completionByChild
                completed: data.containsKey('is_completed') 
                    ? data['is_completed'] == true || data['is_completed'] == 1
                    : completionByChild.values.any((status) => status),
                completionByChild: completionByChild,
              );
              
              // Update the local activities list
              final newActivities = List<PlannedActivity>.from(_plans[i].activities);
              newActivities[activityIndex] = updatedActivity;
              
              // Update progress data if available
              Map<String, ChildProgress> progressByChild = Map.from(plan.progressByChild);
              ProgressData overallProgress = plan.overallProgress;
              
              if (data.containsKey('plan_progress')) {
                // Update child-specific progress
                if (data['plan_progress'].containsKey('by_child')) {
                  final Map<String, dynamic> childProgress = Map<String, dynamic>.from(data['plan_progress']['by_child']);
                  childProgress.forEach((childId, progressData) {
                    progressByChild[childId] = ChildProgress.fromJson(progressData);
                  });
                }
                
                // Update overall progress
                if (data['plan_progress'].containsKey('overall')) {
                  overallProgress = ProgressData.fromJson(data['plan_progress']['overall']);
                }
              }
              
              // Create a new plan with updated data
              _plans[i] = Planning(
                id: plan.id,
                type: plan.type,
                teacherId: plan.teacherId,
                childId: plan.childId,
                childIds: plan.childIds,
                startDate: plan.startDate,
                activities: newActivities,
                progressByChild: progressByChild,
                overallProgress: overallProgress,
              );
              
              break;
            }
          }
        } else {
          // If response doesn't have expected format, refresh plans
          await fetchPlans();
        }
        
        return true;
      } else {
        _error = 'Failed to update activity status';
        return false;
      }
    } catch (e) {
      _error = 'Failed to update activity status: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a planned activity as completed or not completed for all children in a plan
  Future<bool> markActivityAsCompletedForAllChildren(int activityId, bool completed) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Find the plan containing this activity
      int? planId;
      List<String> childIds = [];
      
      // Find the activity to get plan ID and child IDs
      for (final plan in _plans) {
        final activityIndex = plan.activities.indexWhere((a) => a.id == activityId);
        if (activityIndex != -1) {
          planId = plan.id;
          childIds = plan.childIds;
          break;
        }
      }
      
      if (planId == null) {
        _error = 'Activity not found';
        return false;
      }

      // If there are no specific children, there's no need to update anything
      if (childIds.isEmpty) {
        _error = 'No children found for this activity';
        return false;
      }

      // Update the completion status for each child
      bool overallSuccess = true;
      for (final childId in childIds) {
        final data = await _apiProvider.put(
          'planned-activities/$activityId/status',
          {
            'completed': completed,
            'child_id': childId,
          },
        );
        
        if (data == null) {
          overallSuccess = false;
        }
      }

      // Update local state if at least one child was updated successfully
      if (overallSuccess) {
        // Instead of updating local state manually, fetch fresh data
        await fetchPlans();
        return true;
      } else {
        _error = 'Failed to update activity status for some children';
        return false;
      }
    } catch (e) {
      _error = 'Failed to update activity status for all children: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a plan
  Future<bool> deletePlan(int planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiProvider.delete('plans/$planId');
      
      if (data != null) {
        _plans.removeWhere((plan) => plan.id == planId);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete plan';
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete plan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  List<Planning> getWeeklyPlans() {
    return _plans.where((plan) => plan.type == 'weekly').toList();
  }

  List<Planning> getDailyPlans() {
    return _plans.where((plan) => plan.type == 'daily').toList();
  }

  List<PlannedActivity> getActivitiesForDate(DateTime date) {
    List<PlannedActivity> result = [];
    
    for (final plan in _plans) {
      for (final activity in plan.activities) {
        final activityDate = activity.scheduledDate;
        if (activityDate.year == date.year && 
            activityDate.month == date.month && 
            activityDate.day == date.day) {
          result.add(activity);
        }
      }
    }
    
    // Sort activities by scheduled time
    result.sort((a, b) {
      if (a.scheduledTime == null && b.scheduledTime == null) return 0;
      if (a.scheduledTime == null) return 1; // null times go last
      if (b.scheduledTime == null) return -1;
      return a.scheduledTime!.compareTo(b.scheduledTime!);
    });
    
    return result;
  }

  Planning getPlanById(int id) {
    return _plans.firstWhere(
      (plan) => plan.id == id, 
      orElse: () => throw Exception('Plan not found')
    );
  }

  // Get completion count for a specific child and plan
  Map<String, int> getChildProgress(String childId, int planId) {
    // Find the plan
    final plan = _plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => Planning(
        id: 0, 
        type: 'daily',
        teacherId: '0',
        startDate: DateTime.now(),
        activities: [],
      ),
    );
    
    if (plan.id == 0) {
      return {'completed': 0, 'total': 0};
    }
    
    // Use the new progress data if available
    if (plan.progressByChild.containsKey(childId)) {
      final childProgress = plan.progressByChild[childId]!;
      return {
        'completed': childProgress.completed,
        'total': childProgress.total,
      };
    }
    
    // Fallback to manual calculation if progress data not available
    final int totalActivities = plan.activities.length;
    
    // Count completed activities specifically for this child
    int completedCount = 0;
    for (final activity in plan.activities) {
      if (activity.id == null) continue;
      
      // Check completion directly from the activity's completionByChild map
      if (activity.completionByChild.containsKey(childId) && 
          activity.completionByChild[childId] == true) {
        completedCount++;
      }
    }
    
    return {
      'completed': completedCount,
      'total': totalActivities,
    };
  }

  // Get activity completion status for a specific child
  bool getActivityCompletionStatus(int activityId, String childId) {
    // Find the activity in the plans
    bool isCompleted = false;
    
    for (final plan in _plans) {
      final activityIndex = plan.activities.indexWhere((a) => a.id == activityId);
      if (activityIndex != -1) {
        // Check if this activity has completion data for this specific child
        final activity = plan.activities[activityIndex];
        if (activity.completionByChild.containsKey(childId)) {
          // Use child-specific completion status
          isCompleted = activity.completionByChild[childId]!;
        } else {
          // Fall back to overall completion status if no child-specific data
          isCompleted = activity.completed;
        }
        break;
      }
    }
    
    return isCompleted;
  }

  // Explicitly fetch completion status for a plan (debugging purpose)
  Future<Map<String, dynamic>?> getExplicitCompletionStatus(int planId) async {
    try {
      final data = await _apiProvider.get('plans/$planId/completion-status');
      return data;
    } catch (e) {
      _error = 'Failed to get completion status: $e';
      return null;
    }
  }
  
  // Explicitly fetch plan details with full completion data
  Future<Planning?> fetchPlanWithCompletionData(int planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiProvider.get('plans/$planId');
      
      if (data != null) {
        // Process the plan with its completion data
        final plan = Planning.fromJson(data);
        
        // Update the plan in our local list
        int indexToUpdate = _plans.indexWhere((p) => p.id == planId);
        if (indexToUpdate >= 0) {
          _plans[indexToUpdate] = plan;
        } else {
          _plans.add(plan);
        }
        
        notifyListeners();
        return plan;
      }
      
      return null;
    } catch (e) {
      _error = 'Failed to fetch plan details: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Debug method to directly check completion status from server
  Future<Map<String, dynamic>?> debugCompletionStatus(int planId, int activityId, String childId) async {
    try {
      final data = await _apiProvider.get('debug/plans/$planId/activities/$activityId/children/$childId');
      return data;
    } catch (e) {
      _error = 'Debug error: $e';
      return null;
    }
  }
}
