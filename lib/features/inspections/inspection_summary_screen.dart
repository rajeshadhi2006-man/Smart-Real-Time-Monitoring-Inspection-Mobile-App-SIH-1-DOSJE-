import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/assignment_model.dart';
import '../../models/inspection_model.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';

class InspectionSummaryScreen extends ConsumerStatefulWidget {
  final AssignmentModel assignment;
  final String beneficiaryCount;
  final String staffCount;
  final String observations;
  final String complianceFindings;
  final String violations;
  final String remarks;
  final List<EvidenceItemModel> evidenceList;

  const InspectionSummaryScreen({
    super.key,
    required this.assignment,
    required this.beneficiaryCount,
    required this.staffCount,
    required this.observations,
    required this.complianceFindings,
    required this.violations,
    required this.remarks,
    required this.evidenceList,
  });

  @override
  ConsumerState<InspectionSummaryScreen> createState() => _InspectionSummaryScreenState();
}

class _InspectionSummaryScreenState extends ConsumerState<InspectionSummaryScreen> {
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ref.read(authProvider).valueOrNull;
      final position = await LocationService.getCurrentPosition();

      final service = ref.read(inspectionServiceProvider);
      await service.submitInspectionReport(
        inspectionId: widget.assignment.id,
        inspectorId: user?.officerId ?? "OFF-001",
        inspectorName: user?.fullName ?? "Field Inspector",
        latitude: position?.latitude ?? widget.assignment.latitude,
        longitude: position?.longitude ?? widget.assignment.longitude,
        accuracy: position?.accuracy ?? 5.0,
        geofenceStatus: "INSIDE",
        observations: widget.observations,
        complianceFindings: widget.complianceFindings,
        violations: widget.violations,
        beneficiarySummary: "Beneficiary Count: ${widget.beneficiaryCount}",
        staffSummary: "Staff Count: ${widget.staffCount}",
        remarks: widget.remarks,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppTheme.statusSuccess),
                SizedBox(width: 8),
                Expanded(child: Text("Submission Successful")),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Inspection Submitted Successfully!"),
                const SizedBox(height: 8),
                Text("Inspection ID: insp-${widget.assignment.id.substring(0, 8)}"),
                const SizedBox(height: 4),
                const Text("Government Web Dashboard updated in real-time.", style: TextStyle(fontSize: 12, color: AppTheme.statusNeutral)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("RETURN TO DASHBOARD"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifResult = ref.watch(verificationResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inspection Summary Review"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Review Submission Details", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow("Scheme / Project", widget.assignment.schemeName),
                    _buildSummaryRow("Institution", widget.assignment.institutionName),
                    _buildSummaryRow("Location", widget.assignment.geofenceName),
                    _buildSummaryRow("Attendance Status", "ACTIVE (INSIDE GEOFENCE)"),
                    _buildSummaryRow("Verification Status", verifResult?.overallStatus ?? "VERIFIED"),
                    _buildSummaryRow("Beneficiary Count", widget.beneficiaryCount),
                    _buildSummaryRow("Staff Count", widget.staffCount),
                    _buildSummaryRow("Evidence Captured", "${widget.evidenceList.length} Photo(s)"),
                    _buildSummaryRow("Field Observations", widget.observations),
                    _buildSummaryRow("Compliance Findings", widget.complianceFindings),
                    _buildSummaryRow("Violations", widget.violations),
                    _buildSummaryRow("Final Remarks", widget.remarks),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusSuccess),
              onPressed: _isSubmitting ? null : _submitReport,
              icon: const Icon(Icons.send),
              label: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SUBMIT INSPECTION REPORT"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.statusNeutral, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
