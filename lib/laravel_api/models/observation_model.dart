// Model Observation untuk API Laravel
import 'package:daily_checklist_student/laravel_api/models/child_model.dart';
import 'package:daily_checklist_student/laravel_api/models/planning_model.dart';

class ObservationModel {
  final String id;
  final String planId;
  final String childId;
  final DateTime observationDate;
  final String? observationResult;
  final Map<String, bool> conclusions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChildModel? child;
  final Planning? plan;

  ObservationModel({
    required this.id,
    required this.planId,
    required this.childId,
    required this.observationDate,
    this.observationResult,
    required this.conclusions,
    required this.createdAt,
    required this.updatedAt,
    this.child,
    this.plan,
  });

  factory ObservationModel.fromJson(Map<String, dynamic> json) {
    // Parse conclusions map
    Map<String, bool> conclusionsMap = {};
    if (json['conclusions'] != null) {
      final Map<String, dynamic> rawConclusions = Map<String, dynamic>.from(json['conclusions']);
      rawConclusions.forEach((key, value) {
        conclusionsMap[key] = value == true || value == 1;
      });
    }

    return ObservationModel(
      id: json['id'].toString(),
      planId: json['plan_id'].toString(),
      childId: json['child_id'].toString(),
      observationDate: json['observation_date'] != null
          ? DateTime.parse(json['observation_date'])
          : DateTime.now(),
      observationResult: json['observation_result'],
      conclusions: conclusionsMap,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      child: json['child'] != null ? ChildModel.fromJson(json['child']) : null,
      plan: json['plan'] != null ? Planning.fromJson(json['plan']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'child_id': childId,
      'observation_date': observationDate.toIso8601String().split('T')[0],
      'observation_result': observationResult,
      'conclusions': conclusions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (child != null) 'child': child!.toJson(),
      if (plan != null) 'plan': plan!.toJson(),
    };
  }

  ObservationModel copyWith({
    String? id,
    String? planId,
    String? childId,
    DateTime? observationDate,
    String? observationResult,
    Map<String, bool>? conclusions,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChildModel? child,
    Planning? plan,
  }) {
    return ObservationModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      childId: childId ?? this.childId,
      observationDate: observationDate ?? this.observationDate,
      observationResult: observationResult ?? this.observationResult,
      conclusions: conclusions ?? this.conclusions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      child: child ?? this.child,
      plan: plan ?? this.plan,
    );
  }

  // Helper methods for conclusions
  bool get presentasiUlang => conclusions['presentasi_ulang'] ?? false;
  bool get extension => conclusions['extension'] ?? false;
  bool get bahasa => conclusions['bahasa'] ?? false;
  bool get presentasiLangsung => conclusions['presentasi_langsung'] ?? false;

  // Helper method to check if all conclusions are true
  bool get allConclusionsTrue => conclusions.values.every((value) => value == true);

  // Helper method to get completion percentage
  double get completionPercentage {
    if (conclusions.isEmpty) return 0.0;
    final completedCount = conclusions.values.where((value) => value).length;
    return (completedCount / conclusions.length) * 100;
  }
}