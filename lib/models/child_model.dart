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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      parentId: json['parentId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'parentId': parentId,
      'teacherId': teacherId,
      'avatarUrl': avatarUrl,
    };
  }

  // Generate DiceBear avatar URL for a child if none is provided
  String getAvatarUrl() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return avatarUrl!;
    }
    // Menggunakan API DiceBear versi terbaru (9.x)
    final seed = Uri.encodeComponent(name);
    return 'https://api.dicebear.com/9.x/thumbs/svg?seed=$seed';
  }
}
