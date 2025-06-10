// Model Child untuk API Laravel
class ChildModel {
  final String id;
  final String name;
  final int age;
  final String parentId;
  final String teacherId;
  final String? avatarUrl;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.parentId,
    required this.teacherId,
    this.avatarUrl,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
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
      'parent_id': parentId,
      'teacher_id': teacherId,
      'avatar_url': avatarUrl,
    };
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
