import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/services/reverse_geocoding_service.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/gps_map_camera_watermark.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../models/assignment_model.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import 'assignment_camera_screen.dart';

class AssignmentPreviewScreen extends ConsumerStatefulWidget {
  final AssignmentModel assignment;
  final XFile photoFile;
  final Position capturePosition;
  final String captureGeohash;
  final double distanceMeters;
  final DateTime captureTimestamp;
  final GeoAddressData? addressData;

  const AssignmentPreviewScreen({
    super.key,
    required this.assignment,
    required this.photoFile,
    required this.capturePosition,
    required this.captureGeohash,
    required this.distanceMeters,
    required this.captureTimestamp,
    this.addressData,
  });

  @override
  ConsumerState<AssignmentPreviewScreen> createState() => _AssignmentPreviewScreenState();
}

class _AssignmentPreviewScreenState extends ConsumerState<AssignmentPreviewScreen> {
  Uint8List? _imageBytes;
  bool _isLoadingImage = true;
  bool _isSubmitting = false;
  String? _submissionError;
  final GlobalKey _watermarkBoundaryKey = GlobalKey();
  GeoAddressData? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _resolvedAddress = widget.addressData;
    _loadImage();
    _ensureAddressData();
  }

  Future<void> _ensureAddressData() async {
    if (_resolvedAddress == null) {
      final addr = await ReverseGeocodingService.lookupAddress(
        latitude: widget.capturePosition.latitude,
        longitude: widget.capturePosition.longitude,
        fallbackTitle: widget.assignment.title,
        fallbackLocation: widget.assignment.assignedLocation,
      );
      if (mounted) {
        setState(() {
          _resolvedAddress = addr;
        });
      }
    }
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.photoFile.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
          _submissionError = "Failed to load captured photo: $e";
        });
      }
    }
  }

  Future<void> _submitAssignment() async {
    if (_imageBytes == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      // 1. Burn GPS Map Camera watermark stamp into output bytes
      Uint8List bytesToUpload = _imageBytes!;
      try {
        final stamped = await GpsMapCameraStamper.captureWatermarkedPhoto(_watermarkBoundaryKey);
        bytesToUpload = stamped;
      } catch (e) {
        debugPrint("Watermark stamping capture note: $e, using raw photo bytes");
      }

      final authState = ref.read(authProvider);
      final currentUserId = (authState.value?.id.isNotEmpty == true)
          ? authState.value!.id
          : (authState.value?.email ?? "unauthenticated_user");

      final api = ApiService();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytesToUpload,
          filename: "gps_camera_evidence_${widget.assignment.assignmentId}_${DateTime.now().millisecondsSinceEpoch}.png",
        ),
        'user_id': currentUserId,
        'latitude': widget.capturePosition.latitude.toString(),
        'longitude': widget.capturePosition.longitude.toString(),
        'accuracy': widget.capturePosition.accuracy.toString(),
        'geohash': widget.captureGeohash,
        'captured_at': widget.captureTimestamp.toUtc().toIso8601String(),
        'device_info': kIsWeb ? "Web Inspection Terminal" : "Android Field Tablet",
      });

      final response = await api.post(
        "/api/assignments/${widget.assignment.assignmentId}/submit-evidence",
        data: formData,
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        // Invalidate assignments list to fetch updated status
        ref.invalidate(assignmentsProvider);

        if (mounted) {
          _showSuccessModal(resData);
        }
      } else {
        throw Exception("Server responded with code ${response.statusCode}: ${response.data}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  void _showSuccessModal(dynamic data) {
    final submissionId = data['submission_id'] ?? 'SUB-CONFIRMED';
    final serverTimestamp = data['server_timestamp'] ?? DateTime.now().toIso8601String();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF07152B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.8),
        ),
        title: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0x3310B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              "ASSIGNMENT COMPLETED ✓",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow("Submission ID:", submissionId),
            _buildDialogRow("Assignment:", widget.assignment.title),
            _buildDialogRow("Location Status:", "VERIFIED (Distance: ${widget.distanceMeters.toStringAsFixed(1)}m)"),
            _buildDialogRow("Server GeoHash:", widget.captureGeohash),
            _buildDialogRow("GPS Accuracy:", "±${widget.capturePosition.accuracy.toStringAsFixed(1)}m"),
            _buildDialogRow("Recorded At:", serverTimestamp),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x1A10B981),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x4D10B981)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_tethering_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Real-time update published to Central Government Dashboard.",
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx); // Close modal
                Navigator.pop(context); // Return to assignment list
              },
              child: const Text(
                "DONE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestampFormatted = DateFormat("dd-MMM-yyyy HH:mm:ss 'IST'").format(widget.captureTimestamp);

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: SovereignColorfulBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Sovereign Header
              const GovtEmblemHeader(
                compact: true,
                subtitle: "Evidence Verification & Secure Geo-Tagged Dispatch",
                backgroundColor: Color(0xCC07152B),
              ),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "PHOTO PREVIEW",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF38BDF8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x2610B981),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  "GEO-TAG VERIFIED ✓",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Image Display Box with GPS Map Camera Watermark Stamp
                      RepaintBoundary(
                        key: _watermarkBoundaryKey,
                        child: Container(
                          width: double.infinity,
                          height: 320,
                          decoration: BoxDecoration(
                            color: const Color(0xFF071324),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x4D38BDF8), width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // 1. Captured Photo in Background
                                Positioned.fill(
                                  child: _isLoadingImage
                                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                                      : _imageBytes != null
                                          ? Image.memory(
                                              _imageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(
                                              child: Icon(Icons.broken_image, size: 48, color: Colors.white24),
                                            ),
                                ),

                                // 2. Stamped GPS Map Camera Overlay (Matching Reference Image)
                                if (_imageBytes != null)
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: GpsMapCameraWatermark(
                                      latitude: widget.capturePosition.latitude,
                                      longitude: widget.capturePosition.longitude,
                                      timestamp: widget.captureTimestamp,
                                      addressData: _resolvedAddress ??
                                          GeoAddressData.defaultForCoordinates(
                                            widget.capturePosition.latitude,
                                            widget.capturePosition.longitude,
                                            fallbackTitle: widget.assignment.title,
                                            fallbackLocation: widget.assignment.assignedLocation,
                                          ),
                                      showHeaderBadge: true,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xD90A1B33),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x3338BDF8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetaRow("Assignment:", widget.assignment.title, isBold: true),
                            const Divider(color: Colors.white12, height: 16),
                            _buildMetaRow(
                              "Location:",
                              "${widget.capturePosition.latitude.toStringAsFixed(5)}, ${widget.capturePosition.longitude.toStringAsFixed(5)} (VERIFIED ✓)",
                              highlightColor: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 8),
                            _buildMetaRow("GeoHash:", widget.captureGeohash, highlightColor: const Color(0xFF38BDF8)),
                            const SizedBox(height: 8),
                            _buildMetaRow("GPS Accuracy:", "±${widget.capturePosition.accuracy.toStringAsFixed(1)} m"),
                            const SizedBox(height: 8),
                            _buildMetaRow("Captured:", timestampFormatted),
                            const SizedBox(height: 8),
                            _buildMetaRow("Status:", "GEO-TAG VERIFIED ✓", highlightColor: const Color(0xFF10B981)),
                          ],
                        ),
                      ),

                      if (_submissionError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x26EF4444),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _submissionError!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons: RETAKE & SUBMIT ASSIGNMENT
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF38BDF8)),
                                  foregroundColor: const Color(0xFF38BDF8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AssignmentCameraScreen(assignment: widget.assignment),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                label: const Text("RETAKE", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _isSubmitting ? null : _submitAssignment,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                                label: Text(
                                  _isSubmitting ? "SUBMITTING..." : "SUBMIT ASSIGNMENT",
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: highlightColor ?? Colors.white,
              fontWeight: isBold || highlightColor != null ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
