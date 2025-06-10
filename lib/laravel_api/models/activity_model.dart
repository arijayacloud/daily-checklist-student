// Model Activity untuk API Laravel
class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String environment; // 'Home', 'School', 'Both'
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final double minAge; // Changed from int to double to support half-year increments
  final double maxAge; // Changed from int to double to support half-year increments
  final int? duration; // Activity duration in minutes
  final String? nextActivityId;
  final List<ActivityStepModel> activitySteps;
  final String createdBy;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.environment,
    required this.difficulty,
    required this.minAge,
    required this.maxAge,
    this.duration,
    this.nextActivityId,
    required this.activitySteps,
    required this.createdBy,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    List<ActivityStepModel> steps = [];

    if (json['activity_steps'] != null) {
      steps = List<ActivityStepModel>.from(
        (json['activity_steps'] as List).map(
          (step) => ActivityStepModel.fromJson(step),
        ),
      );
    }

    return ActivityModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      environment: json['environment'] ?? 'Both',
      difficulty: json['difficulty'] ?? 'Medium',
      minAge: (json['min_age'] != null) ? double.tryParse(json['min_age'].toString()) ?? 3.0 : 3.0,
      maxAge: (json['max_age'] != null) ? double.tryParse(json['max_age'].toString()) ?? 6.0 : 6.0,
      duration: json['duration'] != null ? int.tryParse(json['duration'].toString()) : null,
      nextActivityId: json['next_activity_id']?.toString(),
      activitySteps: steps,
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'environment': environment,
      'difficulty': difficulty,
      'min_age': minAge,
      'max_age': maxAge,
      'duration': duration,
      'next_activity_id': nextActivityId,
      'activity_steps': activitySteps.map((step) => step.toJson()).toList(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool isAppropriateForAge(double age) {
    return age >= minAge && age <= maxAge;
  }

  List<String> getStepsForTeacher(String teacherId) {
    final teacherSteps = activitySteps.firstWhere(
      (step) => step.teacherId == teacherId,
      orElse: () => ActivityStepModel(
        id: '',
        activityId: id,
        teacherId: '',
        steps: [],
        photos: [],
      ),
    );

    if (teacherSteps.steps.isNotEmpty) {
      return teacherSteps.steps;
    }

    // If no steps for this teacher, return first available steps
    if (activitySteps.isNotEmpty) {
      return activitySteps.first.steps;
    }

    return [];
  }
  
  List<String> getPhotosForTeacher(String teacherId) {
    final teacherSteps = activitySteps.firstWhere(
      (step) => step.teacherId == teacherId,
      orElse: () => ActivityStepModel(
        id: '',
        activityId: id,
        teacherId: '',
        steps: [],
        photos: [],
      ),
    );

    if (teacherSteps.photos.isNotEmpty) {
      return teacherSteps.photos;
    }

    // If no photos for this teacher, return first available photos
    if (activitySteps.isNotEmpty) {
      return activitySteps.first.photos;
    }

    return [];
  }
}

class ActivityStepModel {
  final String id;
  final String activityId;
  final String teacherId;
  final List<String> steps;
  final List<String> photos; // URLs to instruction photos

  ActivityStepModel({
    required this.id,
    required this.activityId,
    required this.teacherId,
    required this.steps,
    this.photos = const [],
  });

  factory ActivityStepModel.fromJson(Map<String, dynamic> json) {
    List<String> stepsList = [];
    if (json['steps'] != null) {
      if (json['steps'] is List) {
        stepsList = List<String>.from(json['steps']);
      } else if (json['steps'] is Map) {
        // Handle case where steps is a JSON object
        final Map<String, dynamic> stepsMap = json['steps'];
        stepsList = stepsMap.values.map((v) => v.toString()).toList();
      }
    }
    
    List<String> photosList = [];
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        photosList = List<String>.from(json['photos']);
      } else if (json['photos'] is Map) {
        final Map<String, dynamic> photosMap = json['photos'];
        photosList = photosMap.values.map((v) => v.toString()).toList();
      }
    }

    return ActivityStepModel(
      id: json['id'].toString(),
      activityId: json['activity_id'].toString(),
      teacherId: json['teacher_id'].toString(),
      steps: stepsList,
      photos: photosList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'teacher_id': teacherId,
      'steps': steps,
      'photos': photos,
    };
  }
}
