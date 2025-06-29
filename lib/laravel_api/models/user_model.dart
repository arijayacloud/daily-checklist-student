// Model User untuk API Laravel
class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? createdBy;
  final bool? isTempPassword;
  final String? phoneNumber;
  final String? address;
  final String? profilePicture;
  final String? status;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.createdBy,
    this.isTempPassword,
    this.phoneNumber,
    this.address,
    this.profilePicture,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'parent',
      createdBy: json['created_by']?.toString(),
      isTempPassword: json['is_temp_password'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_by': createdBy,
      'is_temp_password': isTempPassword,
      'phone_number': phoneNumber,
      'address': address,
      'profile_picture': profilePicture,
      'status': status,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? createdBy,
    bool? isTempPassword,
    String? phoneNumber,
    String? address,
    String? profilePicture,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      isTempPassword: isTempPassword ?? this.isTempPassword,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      status: status ?? this.status,
    );
  }

  // Check if user is a teacher (now includes superadmin for UI purposes)
  bool get isTeacher => role == 'teacher' || role == 'superadmin';
  
  // Original teacher check (when we need to distinguish between actual teachers and superadmins)
  bool get isRealTeacher => role == 'teacher';
  
  // Check if user is a parent
  bool get isParent => role == 'parent';
  
  // Check if user is a superadmin
  bool get isSuperadmin => role == 'superadmin';
}
