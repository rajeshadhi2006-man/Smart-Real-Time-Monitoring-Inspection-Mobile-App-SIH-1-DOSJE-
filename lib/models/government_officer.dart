class GovernmentOfficer {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String accountStatus;
  final String connectedDevice;
  final DateTime lastSync;

  const GovernmentOfficer({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.accountStatus,
    required this.connectedDevice,
    required this.lastSync,
  });

  factory GovernmentOfficer.fromJson(Map<String, dynamic> json) {
    return GovernmentOfficer(
      id: json['officer_id']?.toString() ?? json['user_id']?.toString() ?? json['id']?.toString() ?? 'GOV-OFFICER',
      name: json['full_name'] ?? json['name'] ?? 'Government Officer',
      email: json['email'] ?? '',
      role: json['role'] ?? 'OFFICER',
      department: json['department'] ?? 'Ministry of Social Justice and Empowerment',
      accountStatus: json['account_status'] ?? 'Active',
      connectedDevice: json['connected_device'] ?? 'Official Field Device',
      lastSync: json['last_sync'] != null
          ? DateTime.tryParse(json['last_sync'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'account_status': accountStatus,
      'connected_device': connectedDevice,
      'last_sync': lastSync.toIso8601String(),
    };
  }
}
