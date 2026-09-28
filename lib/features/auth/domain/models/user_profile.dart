enum UserRole {
  departmentOfficial('Department Official'),
  pmuOfficer('PMU Officer'),
  inspectionOfficer('Inspection Officer'),
  projectStaff('Project Staff');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'officer':
      case 'inspection officer':
      case 'inspection_officer':
        return UserRole.inspectionOfficer;
      case 'admin':
      case 'pmu officer':
      case 'pmu_officer':
        return UserRole.pmuOfficer;
      case 'department official':
      case 'department_official':
        return UserRole.departmentOfficial;
      case 'project staff':
      case 'project_staff':
        return UserRole.projectStaff;
      default:
        return UserRole.inspectionOfficer;
    }
  }
}

/// Official Inspector Profile
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String officerId;
  final UserRole role;
  final String department;
  final String assignedDistrict;
  final String? phone;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.officerId,
    required this.role,
    required this.department,
    required this.assignedDistrict,
    this.phone,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'officer_id': officerId,
        'role': role.label,
        'department': department,
        'assigned_district': assignedDistrict,
        'phone': phone,
        'avatar_url': avatarUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String? ?? 'Officer',
        officerId: json['officer_id'] as String? ?? 'MOSJE-OFFICER',
        role: UserRole.fromString(json['role'] as String?),
        department: json['department'] as String? ??
            'Department of Social Justice & Empowerment',
        assignedDistrict: json['assigned_district'] as String? ?? 'Central Command Zone',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? officerId,
    UserRole? role,
    String? department,
    String? assignedDistrict,
    String? phone,
    String? avatarUrl,
  }) =>
      UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        officerId: officerId ?? this.officerId,
        role: role ?? this.role,
        department: department ?? this.department,
        assignedDistrict: assignedDistrict ?? this.assignedDistrict,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
