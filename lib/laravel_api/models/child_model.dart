// Model Child untuk API Laravel
class ChildModel {
  final String id;
  final String name;
  final int age;  // Kept for backward compatibility
  final DateTime? dateOfBirth; // New field for date of birth
  final String parentId;
  final String teacherId;
  final String? avatarUrl;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    this.dateOfBirth,
    required this.parentId,
    required this.teacherId,
    this.avatarUrl,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    // Parse date of birth if it exists
    DateTime? dob;
    if (json['date_of_birth'] != null) {
      try {
        dob = DateTime.parse(json['date_of_birth']);
      } catch (e) {
        print('Error parsing date of birth: $e');
      }
    }
    
    return ChildModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      dateOfBirth: dob,
      parentId: json['parent_id'].toString(),
      teacherId: json['teacher_id'].toString(),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'parent_id': parentId,
      'teacher_id': teacherId,
      'avatar_url': avatarUrl,
    };
  }

  // Calculate child's age based on date of birth
  int getCalculatedAge() {
    if (dateOfBirth == null) {
      return age; // Return stored age if no DOB
    }
    
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth!.year;
    
    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculatedAge--;
    }
    
    return calculatedAge;
  }
  
  // Display age as string with proper formatting
  String getAgeString() {
    final calculatedAge = getCalculatedAge();
    return '$calculatedAge tahun';
  }

  // Generate DiceBear avatar URL for a child if none is provided
  String getAvatarUrl() {
    // Always create a DiceBear URL for consistency and fallback
    final seed = Uri.encodeComponent(name);
    final diceBearUrl = 'https://api.dicebear.com/9.x/thumbs/png?seed=$seed';

    // If avatarUrl is not available or empty, use DiceBear
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return diceBearUrl;
    }

    // If avatarUrl is available, we still use it
    return avatarUrl!;
  }

  // For easy fallback to DiceBear if avatarUrl fails
  String getDiceBearUrl() {
    final seed = Uri.encodeComponent(name);
    return 'https://api.dicebear.com/9.x/thumbs/png?seed=$seed';
  }
}
