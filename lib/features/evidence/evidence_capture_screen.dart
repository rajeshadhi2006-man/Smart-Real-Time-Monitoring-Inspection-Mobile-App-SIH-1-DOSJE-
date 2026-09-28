import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/tactical_telemetry_bar.dart';
import '../../models/inspection_model.dart';
import '../../providers/app_providers.dart';
import 'live_gps_map_camera_screen.dart';

class EvidenceCaptureScreen extends ConsumerStatefulWidget {
  const EvidenceCaptureScreen({super.key});

  @override
  ConsumerState<EvidenceCaptureScreen> createState() => _EvidenceCaptureScreenState();
}

class _EvidenceCaptureScreenState extends ConsumerState<EvidenceCaptureScreen> {
  final List<EvidenceItemModel> _evidenceItems = [];
  String _selectedCategory = 'Infrastructure';
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Infrastructure',
    'Attendance',
    'Beneficiary',
    'Document',
    'Safety',
    'Other'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(positionStreamProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final selectedAssignment = ref.watch(selectedAssignmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: SafeArea(
        child: Column(
          children: [
            // Sovereign Official Header
            Stack(
              children: [
                const GovtEmblemHeader(
                  compact: true,
                  subtitle: "Tamper-Evident SHA-256 Evidence Vault",
                  backgroundColor: Color(0xCC07152B),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tactical Telemetry Bar
                    TacticalTelemetryBar(
                      accuracy: positionAsync.valueOrNull?.accuracy,
                      isGpsLocked: positionAsync.valueOrNull != null,
                      isAntiSpoofActive: true,
                      isCloudConnected: true,
                    ),
                    const SizedBox(height: 14),

                    // HERO GPS Map Camera Banner (Matching Image 1 & 2)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A1B33), Color(0xFF0F2E59)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Glowing Camera Circle (Matching Image 1)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.statusGreen.withValues(alpha: 0.15),
                                  border: Border.all(color: AppColors.statusGreen, width: 1.5),
                                ),
                                child: const Center(
                                  child: Icon(Icons.camera_alt_rounded, color: AppColors.statusGreen, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.statusGreen.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "GEO-HASH",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.statusGreen,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "GPS MAP CAMERA",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF38BDF8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "Physical Evidence Capture",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Captures field photographs stamped with live satellite imagery, reverse geocoded locality, coordinates, timestamp, and SHA-256 cryptographic vault hash.",
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1), height: 1.35),
                          ),
                          const SizedBox(height: 16),

                          // Target Assignment Selector
                          assignmentsAsync.when(
                            data: (assignments) {
                              if (assignments.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final active = selectedAssignment ?? assignments.first;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF040A15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF38BDF8), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Active Assignment: ${active.title}",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Text(
                                            active.assignedLocation,
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LiveGpsMapCameraScreen(
                                              assignment: active,
                                              category: _selectedCategory,
                                              notes: _descriptionController.text.trim().isEmpty
                                                  ? null
                                                  : _descriptionController.text.trim(),
                                              forAssignmentCompletion: false,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("LIVE HUD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) => const SizedBox.shrink(),
                          ),

                          // Category Selector
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "Evidence Category",
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                          const SizedBox(height: 10),

                          // Description input
                          TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "Audit Notes & Observations",
                              hintText: "Enter observation details...",
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Primary Live Camera Trigger Button (Direct Real-Time Feed, Zero Upload Dialog)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final active = selectedAssignment ?? assignmentsAsync.valueOrNull?.firstOrNull;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LiveGpsMapCameraScreen(
                                      assignment: active,
                                      category: _selectedCategory,
                                      notes: _descriptionController.text.trim().isEmpty
                                          ? null
                                          : _descriptionController.text.trim(),
                                      forAssignmentCompletion: false,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.videocam_rounded, size: 22),
                              label: const Text(
                                "OPEN REAL-TIME CAMERA (LIVE FEED)",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Captured Evidence Stream Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "VAULT EVIDENCE STREAM (${_evidenceItems.length})",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (_evidenceItems.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF10B981)),
                            label: const Text("ALL VERIFIED", style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_evidenceItems.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071324),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.photo_camera_back_outlined, size: 40, color: Color(0xFF475569)),
                              SizedBox(height: 10),
                              Text(
                                "No evidence captured for this session yet.",
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Tap 'OPEN GPS MAP CAMERA' above to capture official geo-tagged evidence.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _evidenceItems.length,
                        itemBuilder: (context, index) {
                          final item = _evidenceItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1B33),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0x3338BDF8)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.statusGreen.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.statusGreen.withValues(alpha: 0.4)),
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: AppColors.statusGreen, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.description ?? item.category,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "GPS: ${item.latitude?.toStringAsFixed(5)}, ${item.longitude?.toStringAsFixed(5)} • ${item.timestamp.length >= 19 ? item.timestamp.substring(0, 19).replaceAll('T', ' ') : item.timestamp}",
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF040A15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.white10),
                                            ),
                                            child: Text(
                                              "SHA-256: ${item.sha256Hash != null ? (item.sha256Hash!.length > 16 ? "${item.sha256Hash!.substring(0, 16).toUpperCase()}..." : item.sha256Hash!.toUpperCase()) : item.id}",
                                              style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0x2610B981),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              "GPS MAP CAMERA ✓",
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
