class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? createdBy;
  final bool? isTempPassword;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdBy,
    this.isTempPassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'parent',
      createdBy: json['createdBy'],
      isTempPassword: json['isTempPassword'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'createdBy': createdBy,
      'isTempPassword': isTempPassword,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? createdBy,
    bool? isTempPassword,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      isTempPassword: isTempPassword ?? this.isTempPassword,
    );
  }

  bool get isTeacher => role == 'teacher';
  bool get isParent => role == 'parent';
}
