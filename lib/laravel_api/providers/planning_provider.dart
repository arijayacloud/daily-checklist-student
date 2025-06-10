import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/planning_model.dart';
import '../providers/api_provider.dart';

class PlanningProvider with ChangeNotifier {
  final ApiProvider apiProvider;
  String? _error;
  bool _isLoading = false;
  List<Planning> _plans = [];

  PlanningProvider({required this.apiProvider});

  List<Planning> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all plans (for teachers or parents)
  Future<void> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiProvider.get('plans');
      
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
      } else {
        _error = 'Failed to load plans';
      }
    } catch (e) {
      _error = 'Failed to load plans: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch plans specifically for a child
  Future<void> fetchPlansForParent(String childId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiProvider.get('plans?child_id=$childId');
      
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
      } else {
        _error = 'Failed to load plans for child';
      }
    } catch (e) {
      _error = 'Failed to load plans for child: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new plan
  Future<Planning?> createPlan({
    required String type,
    required DateTime startDate,
    String? childId,
    required List<PlannedActivity> activities,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert activities to the format expected by the API
      List<Map<String, dynamic>> activitiesData = activities.map((activity) {
        return {
          'activity_id': activity.activityId,
          'scheduled_date': activity.scheduledDate.toIso8601String().split('T')[0],
          'scheduled_time': activity.scheduledTime,
          'reminder': activity.reminder,
        };
      }).toList();

      final Map<String, dynamic> planData = {
        'type': type,
        'start_date': startDate.toIso8601String().split('T')[0],
        'child_id': childId,
        'activities': activitiesData,
      };

      final data = await apiProvider.post('plans', planData);
      
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
    List<PlannedActivity>? activities,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> updateData = {};
      
      if (type != null) updateData['type'] = type;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String().split('T')[0];
      if (childId != null) updateData['child_id'] = childId;
      
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

      final data = await apiProvider.put('plans/$planId', updateData);
      
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

  // Mark a planned activity as completed or not completed
  Future<bool> markActivityAsCompleted(int activityId, bool completed) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiProvider.put(
        'planned-activities/$activityId/status',
        {'completed': completed},
      );
      
      if (data != null) {
        // Update the activity status in the local data
        for (int i = 0; i < _plans.length; i++) {
          final activityIndex = _plans[i].activities.indexWhere((a) => a.id == activityId);
          if (activityIndex != -1) {
            // Create a new activity with updated status
            final updatedActivity = PlannedActivity(
              id: _plans[i].activities[activityIndex].id,
              planId: _plans[i].activities[activityIndex].planId,
              activityId: _plans[i].activities[activityIndex].activityId,
              scheduledDate: _plans[i].activities[activityIndex].scheduledDate,
              scheduledTime: _plans[i].activities[activityIndex].scheduledTime,
              reminder: _plans[i].activities[activityIndex].reminder,
              completed: completed,
            );
            
            // Create a new list of activities
            final newActivities = List<PlannedActivity>.from(_plans[i].activities);
            newActivities[activityIndex] = updatedActivity;
            
            // Create a new plan with updated activities
            _plans[i] = Planning(
              id: _plans[i].id,
              type: _plans[i].type,
              teacherId: _plans[i].teacherId,
              childId: _plans[i].childId,
              startDate: _plans[i].startDate,
              activities: newActivities,
            );
            
            break;
          }
        }
        
        notifyListeners();
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

  // Delete a plan
  Future<bool> deletePlan(int planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiProvider.delete('/plans/$planId');
      
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
    
    return result;
  }

  Planning getPlanById(int id) {
    return _plans.firstWhere(
      (plan) => plan.id == id, 
      orElse: () => throw Exception('Plan not found')
    );
  }
}
