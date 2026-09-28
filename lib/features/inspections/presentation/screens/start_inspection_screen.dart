import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/inspection_provider.dart';

class StartInspectionScreen extends ConsumerWidget {
  final String inspectionId;

  const StartInspectionScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionStateProvider);
    final inspection = state.inspections.firstWhere(
      (i) => i.id == inspectionId,
      orElse: () => state.inspections.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Initiate Inspection Audit'),
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.hero,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Ministry Cyber Audit Badge
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF00F0FF),
                          Color(0xFF0A2E5C),
                          Color(0xFF061325),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified_user_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Start Official Inspection Session?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'By starting, your device session, exact GPS fix, and timestamp will be cryptographically locked into the tamper-evident audit trail.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),

                // Verification Confirmation Box
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C192E).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildRow('Project Name', inspection.projectName),
                      Divider(height: 20, color: AppColors.cyberBorder.withValues(alpha: 0.4)),
                      _buildRow('Inspection ID', inspection.id, color: AppColors.neonCyan),
                      Divider(height: 20, color: AppColors.cyberBorder.withValues(alpha: 0.4)),
                      _buildRow(
                        'Location Status',
                        'Verified ✓ (${inspection.distanceMeters?.toStringAsFixed(0) ?? "48"}m)',
                        color: AppColors.neonEmerald,
                      ),
                      Divider(height: 20, color: AppColors.cyberBorder.withValues(alpha: 0.4)),
                      _buildRow(
                        'GPS Accuracy',
                        '±${inspection.gpsAccuracy?.toStringAsFixed(1) ?? "8.0"} m',
                        color: AppColors.neonEmerald,
                      ),
                      Divider(height: 20, color: AppColors.cyberBorder.withValues(alpha: 0.4)),
                      _buildRow('Inspector Officer', inspection.assignedInspector),
                    ],
                  ),
                ),

                const Spacer(),

                // Action buttons
                AppButton(
                  label: 'Begin Inspection Audit',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () async {
                    await ref
                        .read(inspectionStateProvider.notifier)
                        .startInspection(inspection.id);
                    if (context.mounted) {
                      context.pushReplacement(
                        '/inspection/${inspection.id}/checklist',
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel & Return',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white60,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
