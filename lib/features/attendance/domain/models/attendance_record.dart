enum VerificationMethod { manual, qrCode, faceRecognition }

class BeneficiaryRecord {
  final String id;
  final String udidNumber;
  final String name;
  final String category; // Divyangjan / Senior Citizen / Rehabilitation
  final bool isPresent;
  final VerificationMethod? method;
  final double? faceConfidence;
  final DateTime? verifiedAt;

  const BeneficiaryRecord({
    required this.id,
    required this.udidNumber,
    required this.name,
    required this.category,
    this.isPresent = false,
    this.method,
    this.faceConfidence,
    this.verifiedAt,
  });

  BeneficiaryRecord copyWith({
    bool? isPresent,
    VerificationMethod? method,
    double? faceConfidence,
    DateTime? verifiedAt,
  }) {
    return BeneficiaryRecord(
      id: id,
      udidNumber: udidNumber,
      name: name,
      category: category,
      isPresent: isPresent ?? this.isPresent,
      method: method ?? this.method,
      faceConfidence: faceConfidence ?? this.faceConfidence,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

class AttendanceAuditModel {
  final int expectedBeneficiaries;
  final int verifiedBeneficiaries;
  final List<BeneficiaryRecord> records;

  const AttendanceAuditModel({
    required this.expectedBeneficiaries,
    required this.verifiedBeneficiaries,
    required this.records,
  });

  int get pendingBeneficiaries => expectedBeneficiaries - verifiedBeneficiaries;
  double get attendancePercentage => expectedBeneficiaries == 0
      ? 0.0
      : (verifiedBeneficiaries / expectedBeneficiaries) * 100;
}
