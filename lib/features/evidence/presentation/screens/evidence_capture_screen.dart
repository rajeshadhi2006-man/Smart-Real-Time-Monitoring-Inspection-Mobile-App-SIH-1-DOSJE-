import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/evidence_item.dart';
import '../providers/evidence_provider.dart';

class EvidenceCaptureScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const EvidenceCaptureScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  ConsumerState<EvidenceCaptureScreen> createState() =>
      _EvidenceCaptureScreenState();
}

class _EvidenceCaptureScreenState extends ConsumerState<EvidenceCaptureScreen> {
  String _selectedCategory = 'Infrastructure';
  bool _isCapturing = false;

  final _categories = [
    'Infrastructure',
    'Sanitation & Cleanliness',
    'Classrooms & Training Hall',
    'Beneficiary Mess / Dining',
    'Registers & Documentation',
    'Fire Safety & Access Ramps',
  ];

  Future<void> _capturePhoto() async {
    setState(() => _isCapturing = true);
    await ref.read(evidenceStateProvider.notifier).addSimulatedEvidence(
          inspectionId: widget.inspectionId,
          type: EvidenceType.photo,
          categoryTag: _selectedCategory,
          lat: 11.016844,
          lon: 76.955832,
        );
    setState(() => _isCapturing = false);
  }

  Future<void> _recordVideo() async {
    setState(() => _isCapturing = true);
    await ref.read(evidenceStateProvider.notifier).addSimulatedEvidence(
          inspectionId: widget.inspectionId,
          type: EvidenceType.video,
          categoryTag: _selectedCategory,
          lat: 11.016844,
          lon: 76.955832,
        );
    setState(() => _isCapturing = false);
  }

  @override
  Widget build(BuildContext context) {
    final evidenceList = ref.watch(evidenceStateProvider);
    final photoCount =
        evidenceList.where((e) => e.type == EvidenceType.photo).length;
    final videoCount =
        evidenceList.where((e) => e.type == EvidenceType.video).length;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Tamper-Evident Evidence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: AppColors.neonCyan),
            tooltip: 'View Evidence Vault',
            onPressed: () {
              context.push(
                '/inspection/${widget.inspectionId}/evidence/gallery',
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.operational,
        child: Column(
          children: [
            // Evidence Stats Summary Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C192E).withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: AppColors.neonCyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$photoCount Photos',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.videocam,
                        size: 16,
                        color: AppColors.accentSaffron,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$videoCount Videos',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      border: Border.all(
                        color: AppColors.neonEmerald.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonEmerald.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_clock,
                          size: 12,
                          color: AppColors.neonEmerald,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'SHA-256 HASHED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.neonEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category Selector Dropdown
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF091629).withValues(alpha: 0.9),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'TAG CATEGORY: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06101E),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(
                          color: AppColors.cyberBorder.withValues(alpha: 0.6),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0C192E),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: AppColors.neonCyan,
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Camera Viewport / Evidence List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.space16),
                itemCount: evidenceList.length,
                itemBuilder: (context, index) {
                  final item = evidenceList[index];
                  final isPhoto = item.type == EvidenceType.photo;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(AppDimensions.space14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C192E).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(
                        color: AppColors.cyberBorder.withValues(alpha: 0.5),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // High-tech Thumbnail frame
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isPhoto
                                ? AppColors.neonCyan.withValues(alpha: 0.12)
                                : AppColors.accentSaffron.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPhoto
                                  ? AppColors.neonCyan.withValues(alpha: 0.5)
                                  : AppColors.accentSaffron.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            isPhoto
                                ? Icons.image_rounded
                                : Icons.videocam_rounded,
                            color: isPhoto
                                ? AppColors.neonCyan
                                : AppColors.accentSaffron,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.categoryTag,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.status ==
                                              EvidenceUploadStatus.uploaded
                                          ? AppColors.neonEmerald.withValues(alpha: 0.15)
                                          : AppColors.solarSaffron.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: item.status ==
                                                EvidenceUploadStatus.uploaded
                                            ? AppColors.neonEmerald.withValues(alpha: 0.6)
                                            : AppColors.solarSaffron.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Text(
                                      item.status == EvidenceUploadStatus.uploaded
                                          ? 'UPLOADED'
                                          : 'SYNCING...',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: item.status ==
                                                EvidenceUploadStatus.uploaded
                                            ? AppColors.neonEmerald
                                            : AppColors.solarSaffron,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: AppColors.neonCyan,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)} • ${item.capturedAt.hour.toString().padLeft(2, '0')}:${item.capturedAt.minute.toString().padLeft(2, '0')} IST',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hash: ${item.sha256Hash.substring(0, 16)}...',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: AppColors.neonCyan,
                                ),
                              ),
                              if (item.uploadProgress < 1.0) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: item.uploadProgress,
                                    minHeight: 4,
                                    backgroundColor: const Color(0xFF152A47),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.neonCyan,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Capture Controls Bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: const Color(0xFF071224).withValues(alpha: 0.96),
                border: Border(
                  top: BorderSide(
                    color: AppColors.cyberBorder.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.neonCyan,
                            side: const BorderSide(
                              color: AppColors.neonCyan,
                              width: 1.3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _isCapturing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonCyan,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Capture Photo'),
                          onPressed: _isCapturing ? null : _capturePhoto,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentSaffron,
                            side: const BorderSide(
                              color: AppColors.accentSaffron,
                              width: 1.3,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Record Video'),
                          onPressed: _isCapturing ? null : _recordVideo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  AppButton(
                    label: 'Proceed to Beneficiary Attendance',
                    icon: Icons.people_alt_outlined,
                    onPressed: () {
                      context
                          .push('/inspection/${widget.inspectionId}/attendance');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
