import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/assignment_model.dart';
import '../../models/inspection_model.dart';
import '../evidence/live_gps_map_camera_screen.dart';
import 'inspection_summary_screen.dart';

class InspectionFormScreen extends ConsumerStatefulWidget {
  final AssignmentModel assignment;

  const InspectionFormScreen({super.key, required this.assignment});

  @override
  ConsumerState<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _beneficiaryCountController = TextEditingController(text: '45');
  final _staffCountController = TextEditingController(text: '8');
  final _observationsController = TextEditingController(text: 'Facility is operating within standard safety parameters.');
  final _complianceController = TextEditingController(text: 'All essential fire safety and registration certificates verified.');
  final _violationsController = TextEditingController(text: 'None detected.');
  final _remarksController = TextEditingController(text: 'Satisfactory inspection score.');

  final List<EvidenceItemModel> _capturedEvidence = [];
  bool _isCapturingPhoto = false;

  @override
  void dispose() {
    _beneficiaryCountController.dispose();
    _staffCountController.dispose();
    _observationsController.dispose();
    _complianceController.dispose();
    _violationsController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _captureGeoTaggedPhoto() async {
    setState(() => _isCapturingPhoto = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveGpsMapCameraScreen(
            assignment: widget.assignment,
            category: "Infrastructure",
            notes: "Field Inspection Photo Evidence",
            forAssignmentCompletion: false,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingPhoto = false);
      }
    }
  }

  void _proceedToSummary() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionSummaryScreen(
          assignment: widget.assignment,
          beneficiaryCount: _beneficiaryCountController.text,
          staffCount: _staffCountController.text,
          observations: _observationsController.text,
          complianceFindings: _complianceController.text,
          violations: _violationsController.text,
          remarks: _remarksController.text,
          evidenceList: _capturedEvidence,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inspection Checklist"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Header Info
              Card(
                color: AppTheme.primaryNavy.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assignment.schemeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text("Institution: ${widget.assignment.institutionName}"),
                      Text("Location: ${widget.assignment.geofenceName}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Staff & Beneficiary Section
              Text("1. Staff & Beneficiaries Count", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _beneficiaryCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Beneficiary Count"),
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _staffCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Staff Count"),
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Observations Section
              Text("2. Field Observations & Infrastructure", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _observationsController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Field Observations"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),

              // Compliance & Violations
              Text("3. Compliance & Violations", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextFormField(
                controller: _complianceController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Compliance Findings"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _violationsController,
                decoration: const InputDecoration(labelText: "Violations / Discrepancies"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: "Final Remarks"),
              ),
              const SizedBox(height: 24),

              // Geo-Tagged Photo Evidence Section
              Text("4. Geo-Tagged Photo Evidence", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                "Photos must be captured inside application with live GPS location.",
                style: TextStyle(fontSize: 12, color: AppTheme.statusNeutral),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isCapturingPhoto ? null : _captureGeoTaggedPhoto,
                icon: const Icon(Icons.camera_alt),
                label: _isCapturingPhoto
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("CAPTURE GEO-TAGGED PHOTO"),
              ),
              const SizedBox(height: 12),

              if (_capturedEvidence.isNotEmpty) ...[
                Text("Captured Items (${_capturedEvidence.length}):", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _capturedEvidence.map((ev) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.statusSuccess),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.statusSuccess, size: 16),
                          const SizedBox(width: 6),
                          Text("Geo-tag verified (${ev.latitude?.toStringAsFixed(3)}, ${ev.longitude?.toStringAsFixed(3)})", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: _proceedToSummary,
                child: const Text("REVIEW INSPECTION SUMMARY"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
