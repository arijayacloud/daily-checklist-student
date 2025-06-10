import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/config.dart';
import '/laravel_api/models/checklist_item_model.dart';
import '/laravel_api/services/api_service.dart';
import '/laravel_api/providers/api_provider.dart';

class ChecklistProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ApiProvider apiProvider;
  
  List<ChecklistItemModel> _items = [];
  bool _isLoading = false;
  String? _error;
  
  List<ChecklistItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  ChecklistProvider(this.apiProvider);
  
  Future<void> fetchChecklistItems(String childId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/checklist-items?child_id=$childId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        _items = data.map((item) => ChecklistItemModel.fromJson(item)).toList();
      } else {
        _error = 'Failed to load checklist items';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addChecklistItem({
    required String childId,
    required String title,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.post('/checklist-items', {
        'child_id': childId,
        'title': title,
        'description': description,
        'completed': false,
      });
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        final newItem = ChecklistItemModel.fromJson(data);
        _items.add(newItem);
      } else {
        _error = 'Failed to add checklist item';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateChecklistItem({
    required String id,
    required String title,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.put('/checklist-items/$id', {
        'title': title,
        'description': description,
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final updatedItem = ChecklistItemModel.fromJson(data);
        
        final index = _items.indexWhere((item) => item.id == id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      } else {
        _error = 'Failed to update checklist item';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> toggleItemCompletion(String id, bool completed) async {
    try {
      final response = await _apiService.put('/checklist-items/$id/toggle', {
        'completed': completed,
      });
      
      if (response.statusCode == 200) {
        final index = _items.indexWhere((item) => item.id == id);
        if (index != -1) {
          _items[index] = _items[index].copyWith(completed: completed);
          notifyListeners();
        }
      } else {
        _error = 'Failed to toggle checklist item completion';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> deleteChecklistItem(String id) async {
    try {
      final response = await _apiService.delete('/checklist-items/$id');
      
      if (response.statusCode == 200) {
        _items.removeWhere((item) => item.id == id);
        notifyListeners();
      } else {
        _error = 'Failed to delete checklist item';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Added methods for observation form
  Future<void> addSchoolObservation({
    required String itemId,
    required int duration,
    required int engagement,
    required String notes,
    required String learningOutcomes,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await apiProvider.post('checklist-items/$itemId/observations', {
        'environment': 'School',
        'duration_minutes': duration,
        'engagement_level': engagement,
        'notes': notes,
        'learning_outcomes': learningOutcomes,
      });
      
      if (response != null) {
        // Refresh the checklist items to reflect the new observation
        final index = _items.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          // Mark as completed or update other properties if needed
          final updatedItem = _items[index].copyWith(completed: true);
          _items[index] = updatedItem;
        }
      } else {
        _error = 'Failed to add school observation';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHomeObservation({
    required String itemId,
    required int duration,
    required int engagement,
    required String notes,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await apiProvider.post('checklist-items/$itemId/observations', {
        'environment': 'Home',
        'duration_minutes': duration,
        'engagement_level': engagement,
        'notes': notes,
      });
      
      if (response != null) {
        // Refresh the checklist items to reflect the new observation
        final index = _items.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          // Mark as completed or update other properties if needed
          final updatedItem = _items[index].copyWith(completed: true);
          _items[index] = updatedItem;
        }
      } else {
        _error = 'Failed to add home observation';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<ChecklistItemModel>> getChecklistItemsForChild(String childId) async {
    await fetchChecklistItems(childId);
    return _items;
  }
  
  Future<bool> assignActivity({
    required String childId, 
    required String activityId,
    required DateTime scheduledDate,
    String? scheduledTime,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await apiProvider.post('checklist-items', {
        'child_id': childId,
        'activity_id': activityId,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        'scheduled_time': scheduledTime,
      });
      
      _isLoading = false;
      notifyListeners();
      return response != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
