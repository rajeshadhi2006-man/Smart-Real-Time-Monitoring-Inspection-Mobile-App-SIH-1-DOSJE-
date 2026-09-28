class AnomalyReport {
  final String inspectionId;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final int overallScore; // 0 - 100
  final double attendanceVariancePercent; // e.g. -14.2%
  final bool locationMismatchDetected;
  final List<String> missingEvidenceTags;
  final List<String> explainableFlags;
  final String recommendedAction;
  final DateTime analyzedAt;

  const AnomalyReport({
    required this.inspectionId,
    required this.riskLevel,
    required this.overallScore,
    required this.attendanceVariancePercent,
    required this.locationMismatchDetected,
    required this.missingEvidenceTags,
    required this.explainableFlags,
    required this.recommendedAction,
    required this.analyzedAt,
  });

  factory AnomalyReport.mockForInspection(String id) {
    return AnomalyReport(
      inspectionId: id,
      riskLevel: 'MEDIUM',
      overallScore: 78,
      attendanceVariancePercent: -14.2,
      locationMismatchDetected: false,
      missingEvidenceTags: ['Fire Safety NOC', 'Vocational Training Workshop'],
      explainableFlags: [
        'Beneficiary physical headcount (103/120) is 14.2% lower than the 90-day institutional average.',
        'Two mandatory photo evidence categories are pending capture.',
        'Previous inspection on 12 Aug 2026 reported 98.3% compliance score.',
        'Registered geofence verified at 48m with acceptable GPS accuracy (±8m).',
      ],
      recommendedAction:
          'Proceed with checklist verification. Require secondary supervisor sign-off on attendance shortfall before final closure.',
      analyzedAt: DateTime.now(),
    );
  }
}
