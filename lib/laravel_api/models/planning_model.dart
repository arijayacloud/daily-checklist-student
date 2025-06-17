// Model Planning untuk API Laravel
class Planning {
  final int id;
  final String type;
  final String teacherId;
  final String? childId;
  final List<String> childIds;
  final DateTime startDate;
  final List<PlannedActivity> activities;
  final Map<String, ChildProgress> progressByChild;
  final ProgressData overallProgress;

  Planning({
    required this.id,
    required this.type,
    required this.teacherId,
    this.childId,
    List<String>? childIds,
    required this.startDate,
    required this.activities,
    Map<String, ChildProgress>? progressByChild,
    ProgressData? overallProgress,
  }) : childIds = childIds ?? [],
       progressByChild = progressByChild ?? {},
       overallProgress = overallProgress ?? ProgressData(completed: 0, total: 0, percentage: 0);

  factory Planning.fromJson(Map<String, dynamic> json) {
    // Extract child IDs
    List<String> childIds = [];
    if (json['children'] != null) {
      final Set<String> uniqueIds = {};
      for (var child in json['children'] as List) {
        uniqueIds.add(child['id'].toString());
      }
      childIds = uniqueIds.toList();
    }
    
    // Parse progress by child if available
    Map<String, ChildProgress> progressByChild = {};
    if (json.containsKey('progress_by_child') && json['progress_by_child'] != null) {
      try {
        final Map<String, dynamic> rawProgress = Map<String, dynamic>.from(json['progress_by_child']);
        rawProgress.forEach((childId, data) {
          progressByChild[childId] = ChildProgress.fromJson(data);
        });
      } catch (e) {
        print('Error parsing progress_by_child: $e');
      }
    }
    
    // Parse overall progress if available
    ProgressData overallProgress = ProgressData(completed: 0, total: 0, percentage: 0);
    if (json.containsKey('overall_progress') && json['overall_progress'] != null) {
      try {
        overallProgress = ProgressData.fromJson(json['overall_progress']);
      } catch (e) {
        print('Error parsing overall_progress: $e');
      }
    }
    
    // Parse completion map if available - NOTE: examine several possible formats
    Map<String, Map<String, bool>> completionMap = {};
    
    // Format 1: completion_map in the main JSON
    if (json.containsKey('completion_map') && json['completion_map'] != null) {
      try {
        final rawCompletionMap = json['completion_map'];
        if (rawCompletionMap is Map) {
          rawCompletionMap.forEach((activityId, childData) {
            final activityIdStr = activityId.toString();
            completionMap[activityIdStr] = {};
            
            if (childData is Map) {
              childData.forEach((childId, completed) {
                completionMap[activityIdStr]![childId.toString()] = 
                    completed == 1 || completed == true;
              });
            }
          });
        }
      } catch (e) {
        print('Error parsing completion_map: $e');
      }
    }
    
    // Format 2: Try to parse from raw_completion_data if available
    if (json.containsKey('raw_completion_data') && json['raw_completion_data'] != null) {
      try {
        final rawData = json['raw_completion_data'] as List;
        
        for (var record in rawData) {
          final activityId = record['planned_activity_id'].toString();
          final childId = record['child_id'].toString();
          final completed = record['completed'] == 1 || record['completed'] == true;
          
          if (!completionMap.containsKey(activityId)) {
            completionMap[activityId] = {};
          }
          
          completionMap[activityId]![childId] = completed;
        }
      } catch (e) {
        print('Error parsing raw_completion_data: $e');
      }
    }
    
    // Parse planned activities with completion data
    List<PlannedActivity> plannedActivities = [];
    if (json['planned_activities'] != null) {
      plannedActivities = (json['planned_activities'] as List).map((x) {
        final activityId = x['id'].toString();
        Map<String, bool> childCompletions = {};
        
        // Apply completion data if available from our parsed map
        if (completionMap.containsKey(activityId)) {
          childCompletions = completionMap[activityId]!;
        }
        
        // Check if the activity has child_completion_map directly in it
        if (x.containsKey('child_completion_map') && x['child_completion_map'] != null) {
          final directCompletions = x['child_completion_map'];
          if (directCompletions is Map) {
            directCompletions.forEach((childId, completed) {
              childCompletions[childId.toString()] = completed == 1 || completed == true;
            });
          }
        }
        
        // Also check for legacy child_completion
        if (x.containsKey('child_completion') && x['child_completion'] != null) {
          final directCompletions = x['child_completion'];
          if (directCompletions is Map) {
            directCompletions.forEach((childId, completed) {
              childCompletions[childId.toString()] = completed == 1 || completed == true;
            });
          }
        }
        
        // Create a copy of x with the completion data
        final activityWithCompletions = Map<String, dynamic>.from(x);
        activityWithCompletions['completion_by_child'] = childCompletions;
        
        return PlannedActivity.fromJson(activityWithCompletions);
      }).toList();
    }
    
    return Planning(
      id: json['id'] != null ? int.parse(json['id'].toString()) : 0,
      type: json['type'] ?? 'weekly',
      teacherId: json['teacher_id']?.toString() ?? '',
      childId: json['child_id']?.toString(),
      childIds: childIds,
      startDate: DateTime.parse(json['start_date']),
      activities: plannedActivities,
      progressByChild: progressByChild,
      overallProgress: overallProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'type': type,
      'teacher_id': teacherId,
      'child_id': childId,
      'child_ids': childIds,
      'start_date': startDate.toIso8601String().split('T')[0],
      'activities': activities.map((x) => x.toJson()).toList(),
      'progress_by_child': progressByChild.map((key, value) => MapEntry(key, value.toJson())),
      'overall_progress': overallProgress.toJson(),
    };
  }
}

class PlannedActivity {
  final int? id;
  final int planId;
  final int activityId;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final bool reminder;
  final bool completed;
  final String? environment;
  final Map<String, bool> completionByChild;

  PlannedActivity({
    this.id,
    required this.planId,
    required this.activityId,
    required this.scheduledDate,
    this.scheduledTime,
    this.reminder = true,
    this.completed = false,
    this.environment,
    Map<String, bool>? completionByChild,
  }) : completionByChild = completionByChild ?? {};

  factory PlannedActivity.fromJson(Map<String, dynamic> json) {
    // Check if we're receiving a nested structure with pivot data or direct completed status
    bool isCompleted = false;
    
    // First check if direct 'is_completed' property exists (new API format)
    if (json.containsKey('is_completed')) {
      isCompleted = json['is_completed'] == 1 || json['is_completed'] == true;
    }
    // Then check if direct 'completed' property exists
    else if (json.containsKey('completed')) {
      isCompleted = json['completed'] == 1 || json['completed'] == true;
    } 
    // Otherwise check in pivot data if it exists
    else if (json.containsKey('pivot') && json['pivot'] != null) {
      final pivot = json['pivot'];
      if (pivot.containsKey('completed')) {
        isCompleted = pivot['completed'] == 1 || pivot['completed'] == true;
      }
    }

    // Parse the completion_by_child or child_completion map if available
    Map<String, bool> completionByChild = {};
    
    // First check for completion_by_child (our newer format)
    if (json.containsKey('completion_by_child') && json['completion_by_child'] != null) {
      final Map<String, dynamic> rawCompletions = Map<String, dynamic>.from(json['completion_by_child']);
      rawCompletions.forEach((childId, value) {
        completionByChild[childId] = value == 1 || value == true;
      });
    }
    // Then check for child_completion_map (new API response)
    else if (json.containsKey('child_completion_map') && json['child_completion_map'] != null) {
      final Map<String, dynamic> rawCompletions = Map<String, dynamic>.from(json['child_completion_map']);
      rawCompletions.forEach((childId, value) {
        completionByChild[childId] = value == 1 || value == true;
      });
    }
    // Also check for child_completion (alternative format)
    else if (json.containsKey('child_completion') && json['child_completion'] != null) {
      final Map<String, dynamic> rawCompletions = Map<String, dynamic>.from(json['child_completion']);
      rawCompletions.forEach((childId, value) {
        completionByChild[childId] = value == 1 || value == true;
      });
    }
    
    // Try to extract environment information
    String? environment;
    // Direct environment property
    if (json.containsKey('environment')) {
      environment = json['environment'];
    } 
    // Check if environment is available via related activity
    else if (json.containsKey('activity') && json['activity'] != null) {
      environment = json['activity']['environment'];
    }

    return PlannedActivity(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      planId: json['plan_id'] != null ? int.parse(json['plan_id'].toString()) : 0,
      activityId: json['activity_id'] != null ? int.parse(json['activity_id'].toString()) : 0,
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      reminder: json['reminder'] == null ? true : json['reminder'] == 1 || json['reminder'] == true,
      completed: isCompleted,
      environment: environment,
      completionByChild: completionByChild,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'activity_id': activityId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'scheduled_time': scheduledTime,
      'reminder': reminder,
      'completed': completed,
      'environment': environment,
      'completion_by_child': completionByChild,
    };
  }
  
  // Helper method to check if an activity is completed by a specific child
  bool isCompletedByChild(String childId) {
    return completionByChild.containsKey(childId) ? completionByChild[childId]! : false;
  }
}

// New class to handle child progress data
class ChildProgress {
  final String childId;
  final String? name;
  final int completed;
  final int total;
  final double percentage;
  
  ChildProgress({
    required this.childId,
    this.name,
    required this.completed,
    required this.total,
    required this.percentage,
  });
  
  factory ChildProgress.fromJson(Map<String, dynamic> json) {
    return ChildProgress(
      childId: json['child_id'].toString(),
      name: json['name'],
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'name': name,
      'completed': completed,
      'total': total,
      'percentage': percentage,
    };
  }
}

// New class to handle overall progress data
class ProgressData {
  final int completed;
  final int total;
  final double percentage;
  
  ProgressData({
    required this.completed,
    required this.total,
    required this.percentage,
  });
  
  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'total': total,
      'percentage': percentage,
    };
  }
}
