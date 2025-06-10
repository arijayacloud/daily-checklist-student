// import 'package:cloud_firestore/cloud_firestore.dart';

// class AgeRange {
//   final int min;
//   final int max;

//   AgeRange({required this.min, required this.max});

//   factory AgeRange.fromJson(Map<String, dynamic> json) {
//     return AgeRange(min: json['min'] ?? 3, max: json['max'] ?? 6);
//   }

//   Map<String, dynamic> toJson() {
//     return {'min': min, 'max': max};
//   }

//   bool isInRange(int age) {
//     return age >= min && age <= max;
//   }
// }

// class CustomStep {
//   final String teacherId;
//   final List<String> steps;

//   CustomStep({required this.teacherId, required this.steps});

//   factory CustomStep.fromJson(Map<String, dynamic> json) {
//     return CustomStep(
//       teacherId: json['teacherId'] ?? '',
//       steps: List<String>.from(json['steps'] ?? []),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {'teacherId': teacherId, 'steps': steps};
//   }
// }

// class ActivityModel {
//   final String id;
//   final String title;
//   final String description;
//   final String environment; // 'Home', 'School', 'Both'
//   final String difficulty; // 'Easy', 'Medium', 'Hard'
//   final AgeRange ageRange;
//   final String? nextActivityId;
//   final List<CustomStep> customSteps;
//   final Timestamp createdAt;
//   final String createdBy;

//   ActivityModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.environment,
//     required this.difficulty,
//     required this.ageRange,
//     this.nextActivityId,
//     required this.customSteps,
//     required this.createdAt,
//     required this.createdBy,
//   });

//   factory ActivityModel.fromJson(Map<String, dynamic> json) {
//     // Handling createdAt which could be String or Timestamp
//     Timestamp createdAtTimestamp;
//     if (json['createdAt'] is Timestamp) {
//       createdAtTimestamp = json['createdAt'];
//     } else if (json['createdAt'] is String) {
//       // Convert String to DateTime then to Timestamp
//       try {
//         createdAtTimestamp = Timestamp.fromDate(
//           DateTime.parse(json['createdAt']),
//         );
//       } catch (e) {
//         createdAtTimestamp = Timestamp.now();
//       }
//     } else {
//       createdAtTimestamp = Timestamp.now();
//     }

//     return ActivityModel(
//       id: json['id'] ?? '',
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       environment: json['environment'] ?? 'Both',
//       difficulty: json['difficulty'] ?? 'Medium',
//       ageRange: AgeRange.fromJson(json['ageRange'] ?? {'min': 3, 'max': 6}),
//       nextActivityId: json['nextActivityId'],
//       customSteps:
//           (json['customSteps'] as List<dynamic>?)
//               ?.map((step) => CustomStep.fromJson(step))
//               .toList() ??
//           [],
//       createdAt: createdAtTimestamp,
//       createdBy: json['createdBy'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//       'environment': environment,
//       'difficulty': difficulty,
//       'ageRange': ageRange.toJson(),
//       'nextActivityId': nextActivityId,
//       'customSteps': customSteps.map((step) => step.toJson()).toList(),
//       'createdAt': createdAt,
//       'createdBy': createdBy,
//     };
//   }

//   bool isAppropriateForAge(int age) {
//     return ageRange.isInRange(age);
//   }

//   List<String> getStepsForTeacher(String teacherId) {
//     final teacherSteps = customSteps.firstWhere(
//       (step) => step.teacherId == teacherId,
//       orElse: () => CustomStep(teacherId: '', steps: []),
//     );

//     if (teacherSteps.steps.isNotEmpty) {
//       return teacherSteps.steps;
//     }

//     // If no steps for this teacher, return first available steps
//     if (customSteps.isNotEmpty) {
//       return customSteps.first.steps;
//     }

//     return [];
//   }
// }
