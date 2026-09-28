import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/permissions/permission_handler_service.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/officer_digital_id_card.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../providers/app_providers.dart';
import '../face_verification/screens/face_enrollment_screen.dart';
import '../face_verification/providers/face_verification_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, bool> _permissions = {
    'location': false,
    'camera': false,
    'microphone': false,
    'notification': false,
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await PermissionHandlerService.checkAllPermissionsStatus();
    if (mounted) {
      setState(() {
        _permissions = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: SovereignColorfulBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Official Sovereign Header
              const GovtEmblemHeader(
                compact: true,
                subtitle: "National Digital Officer Credential Service",
                backgroundColor: Color(0xCC07152B),
              ),

              // Main Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Official Government Sovereign Smart ID Card
                      OfficerDigitalIdCard(
                        fullName: user?.fullName ?? "Field Inspector",
                        officerId: user?.officerId ?? "OFF-001",
                        role: user?.role ?? "OFFICER",
                        department: user?.department ?? "Field Surveillance Unit",
                        circle: "Tamil Nadu Circle • Zone 04",
                        isBiometricBound: true,
                      ),
                      const SizedBox(height: 18),

                      // Biometric ArcFace Face Enrollment Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xD90A1B33),
                              Color(0xBF071324),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x3338BDF8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0x3338BDF8)),
                                        ),
                                        child: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF38BDF8), size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "ArcFace 512-D Biometrics",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                                            ),
                                            Text(
                                              "Neural Face Feature Vector Registered",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (user != null)
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final statusAsync = ref.watch(faceEnrollmentStatusProvider(user.user_id));
                                      return statusAsync.when(
                                        data: (status) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status.isEnrolled
                                                ? AppColors.statusGreen.withValues(alpha: 0.15)
                                                : AppColors.tricolorSaffron.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: status.isEnrolled ? AppColors.statusGreen : AppColors.tricolorSaffron,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                status.isEnrolled ? Icons.check_circle_rounded : Icons.pending_outlined,
                                                size: 13,
                                                color: status.isEnrolled ? AppColors.statusGreen : AppColors.tricolorSaffron,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                status.isEnrolled ? "ENROLLED" : "PENDING",
                                                style: TextStyle(
                                                  color: status.isEnrolled ? AppColors.statusGreen : AppColors.tricolorSaffron,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        loading: () => const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8))),
                                        error: (err, stack) => const SizedBox(),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Your face biometric template is cryptographically matched on-device during attendance check-ins and surprise inspection sign-offs.",
                              style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const FaceEnrollmentScreen()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_front_rounded, size: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          "UPDATE FACE BIOMETRIC TEMPLATE",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // System Permissions Matrix Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xD90A1B33),
                              Color(0xBF071324),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x3338BDF8), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.security_rounded, size: 18, color: Color(0xFF38BDF8)),
                                SizedBox(width: 8),
                                Text(
                                  "Device Hardware Permissions Matrix",
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildPermissionTile("GPS Location Telemetry", _permissions['location'] ?? false, () async {
                              await PermissionHandlerService.requestLocationPermission();
                              _checkPermissions();
                            }),
                            _buildPermissionTile("Camera & Evidence Capture", _permissions['camera'] ?? false, () async {
                              await PermissionHandlerService.requestCameraPermission();
                              _checkPermissions();
                            }),
                            _buildPermissionTile("Acoustic Passphrase Microphone", _permissions['microphone'] ?? false, () async {
                              await PermissionHandlerService.requestMicrophonePermission();
                              _checkPermissions();
                            }),
                            _buildPermissionTile("National Push Notification Stream", _permissions['notification'] ?? false, () async {
                              await PermissionHandlerService.requestNotificationPermission();
                              _checkPermissions();
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Backend Telemetry Gateway Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xD90A1B33),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x3338BDF8)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.dns_rounded, color: Color(0xFF38BDF8), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Backend Telemetry Gateway", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                                  Text(ApiConfig.baseUrl, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: AppColors.statusGreen, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Official Logout Session Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text("TERMINATE SECURE SESSION", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildPermissionTile(String title, bool isGranted, VoidCallback onRequest) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isGranted ? AppColors.statusGreen : const Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: onRequest,
              child: const Text("Enable", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
            )
          else
            const Text("Granted", style: TextStyle(fontSize: 12, color: AppColors.statusGreen, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
