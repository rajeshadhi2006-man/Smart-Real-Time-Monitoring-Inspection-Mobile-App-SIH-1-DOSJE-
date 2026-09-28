import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/location_service.dart';
import '../providers/inspection_provider.dart';

/// Interactive modal for enrolling a new live inspection site directly from the device
Future<void> showEnrollInspectionDialog(BuildContext context, WidgetRef ref) async {
  final locationState = ref.read(locationTrackingProvider);
  final defaultLat = locationState.currentLocation?.latitude ?? 12.9716;
  final defaultLon = locationState.currentLocation?.longitude ?? 77.5946;

  final nameController = TextEditingController();
  final orgController = TextEditingController();
  final districtController = TextEditingController();
  final latController = TextEditingController(text: defaultLat.toStringAsFixed(6));
  final lonController = TextEditingController(text: defaultLon.toStringAsFixed(6));
  final beneficiariesController = TextEditingController(text: '100');

  String selectedPriority = 'HIGH';
  bool isSubmitting = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0A1628),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_rounded,
                              color: Color(0xFF00F0FF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enroll Field Inspection Site',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Instant cloud replication to web & mobile',
                                style: TextStyle(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Facility Name
                  _buildInputLabel('Facility / Project Name', Icons.business_rounded),
                  _buildTextField(
                    controller: nameController,
                    hint: 'e.g. Apex Welfare Centre & Skill Institute',
                  ),
                  const SizedBox(height: 12),

                  // Organization & District Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Organization', Icons.domain_rounded),
                            _buildTextField(
                              controller: orgController,
                              hint: 'e.g. Welfare Trust / NGO',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('District & State', Icons.map_rounded),
                            _buildTextField(
                              controller: districtController,
                              hint: 'e.g. Bengaluru, Karnataka',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Coordinates Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Target Latitude', Icons.my_location_rounded),
                            _buildTextField(
                              controller: latController,
                              hint: '12.9716',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Target Longitude', Icons.my_location_rounded),
                            _buildTextField(
                              controller: lonController,
                              hint: '77.5946',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Auto-fill GPS button
                  if (locationState.currentLocation != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            latController.text =
                                locationState.currentLocation!.latitude.toStringAsFixed(6);
                            lonController.text =
                                locationState.currentLocation!.longitude.toStringAsFixed(6);
                          });
                        },
                        icon: const Icon(Icons.gps_fixed_rounded, size: 14, color: AppColors.neonCyan),
                        label: const Text(
                          'Use My Current GPS Position',
                          style: TextStyle(fontSize: 11, color: AppColors.neonCyan),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Priority & Beneficiaries
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Audit Priority', Icons.shield_rounded),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1E36),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPriority,
                                  dropdownColor: const Color(0xFF0D1E36),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  isExpanded: true,
                                  items: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']
                                      .map((p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedPriority = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Target Beneficiaries', Icons.group_rounded),
                            _buildTextField(
                              controller: beneficiariesController,
                              hint: '100',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final org = orgController.text.trim();
                              final dist = districtController.text.trim();
                              final lat = double.tryParse(latController.text.trim());
                              final lon = double.tryParse(lonController.text.trim());

                              if (name.isEmpty || org.isEmpty || dist.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all required facility information.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              if (lat == null || lon == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter valid numeric coordinates.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              setState(() => isSubmitting = true);

                              await ref.read(inspectionStateProvider.notifier).enrollInspection(
                                    projectName: name,
                                    organization: org,
                                    district: dist,
                                    latitude: lat,
                                    longitude: lon,
                                    priority: selectedPriority,
                                  );

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Field site "$name" enrolled! Broadcasted live to all nodes.'),
                                    backgroundColor: const Color(0xFF0F172A),
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Enroll & Broadcast to Cloud',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildInputLabel(String label, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Row(
      children: [
        Icon(icon, size: 13, color: AppColors.neonCyan),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0D1E36),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
      ),
    ),
  );
}
