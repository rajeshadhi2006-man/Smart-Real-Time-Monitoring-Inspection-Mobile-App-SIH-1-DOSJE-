import '../../../inspections/domain/models/inspection_model.dart';

/// Registered Project Details with Geo-Anchor and compliance metrics
class ProjectModel {
  final String id;
  final String name;
  final String organization;
  final String projectType;
  final String district;
  final String state;
  final String address;
  final String contactPerson;
  final String contactPhone;
  final int registeredBeneficiaries;
  final String lastInspectionDate;
  final String riskLevel; // Low, Medium, High, Critical
  final int complianceScore; // e.g. 92%
  final bool cctvAvailable;
  final int activeCamerasCount;
  final double registeredLatitude;
  final double registeredLongitude;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.organization,
    required this.projectType,
    required this.district,
    required this.state,
    required this.address,
    required this.contactPerson,
    required this.contactPhone,
    required this.registeredBeneficiaries,
    required this.lastInspectionDate,
    required this.riskLevel,
    required this.complianceScore,
    required this.cctvAvailable,
    required this.activeCamerasCount,
    required this.registeredLatitude,
    required this.registeredLongitude,
  });

  factory ProjectModel.fromInspection(InspectionModel inspection) {
    return ProjectModel(
      id: inspection.projectId,
      name: inspection.projectName,
      organization: inspection.organization,
      projectType: 'Central MoSJE Welfare Facility',
      district: inspection.district,
      state: 'Registered Jurisdiction',
      address: '${inspection.projectName}, ${inspection.district}',
      contactPerson: inspection.assignedInspector,
      contactPhone: '+91 (Government Audited)',
      registeredBeneficiaries: inspection.expectedBeneficiaries,
      lastInspectionDate: inspection.deadline,
      riskLevel: inspection.aiRiskLevel,
      complianceScore: inspection.isGpsVerified ? 95 : 70,
      cctvAvailable: true,
      activeCamerasCount: 2,
      registeredLatitude: inspection.verifiedLatitude ?? 12.9716,
      registeredLongitude: inspection.verifiedLongitude ?? 77.5946,
    );
  }

  factory ProjectModel.demo({
    String? id,
    String? name,
    String? organization,
    String? district,
    double? latitude,
    double? longitude,
  }) {
    return ProjectModel(
      id: id ?? 'PRJ-LIVE',
      name: name ?? 'Live Field Telemetry Site',
      organization: organization ?? 'MoSJE Field Verification',
      projectType: 'Autonomous Telemetry Facility',
      district: district ?? 'Live Telemetry Active',
      state: 'India',
      address: 'MoSJE Verified Facility Location',
      contactPerson: 'Field Officer (Active)',
      contactPhone: '+91 (Verified)',
      registeredBeneficiaries: 100,
      lastInspectionDate: 'Today',
      riskLevel: 'Low',
      complianceScore: 90,
      cctvAvailable: true,
      activeCamerasCount: 2,
      registeredLatitude: latitude ?? 12.9716,
      registeredLongitude: longitude ?? 77.5946,
    );
  }
}
