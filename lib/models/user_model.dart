class UserModel {
  final String id;
  final String officerId;
  final String fullName;
  final String email;
  final String role;
  final String department;
  final String? profilePhoto;

  UserModel({
    required this.id,
    required this.officerId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.department,
    this.profilePhoto,
  });

  String get user_id => id.isNotEmpty ? id : (email.isNotEmpty ? email : officerId);
  String get userId => user_id;
  String get name => fullName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      officerId: json['officer_id'] ?? json['user_id'] ?? 'OFF-001',
      fullName: json['full_name'] ?? json['name'] ?? 'Field Inspector',
      email: json['email'] ?? '',
      role: json['role'] ?? 'INSPECTOR',
      department: json['department'] ?? 'Field Surveillance Unit',
      profilePhoto: json['profile_photo'] ?? json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'officer_id': officerId,
      'full_name': fullName,
      'name': fullName,
      'email': email,
      'role': role,
      'department': department,
      'profile_photo': profilePhoto,
    };
  }
}
