import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/inspection_provider.dart';

class SubmissionProgressScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const SubmissionProgressScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  ConsumerState<SubmissionProgressScreen> createState() =>
      _SubmissionProgressScreenState();
}

class _SubmissionProgressScreenState
    extends ConsumerState<SubmissionProgressScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isCompleted = false;

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  final _steps = [
    'Validating GPS coordinates & offline signatures...',
    'Hashing & encrypting photo/video evidence packages...',
    'Transmitting beneficiary attendance records to central register...',
    'Committing inspection dossier to MoSJE PostgreSQL database...',
    'Generating authoritative digital inspection receipt...',
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _startSubmissionSimulation();
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _startSubmissionSimulation() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }

    await ref.read(inspectionStateProvider.notifier).submitInspection(
          inspectionId: widget.inspectionId,
          remarks: 'Submitted securely with complete evidence.',
        );

    if (mounted) {
      setState(() => _isCompleted = true);
      _successController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Inspection Transmission'),
        automaticallyImplyLeading: false,
      ),
      body: AppBackground(
        variant: AppBackgroundVariant.hero,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Animated Success / Transmission Icon
                Center(
                  child: _isCompleted
                      ? ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF00FF88),
                                  Color(0xFF0D533C),
                                  Color(0xFF051C15),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.neonEmerald.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFF00F0FF),
                                Color(0xFF09294A),
                                Color(0xFF051426),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonCyan.withValues(alpha: 0.3),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                Text(
                  _isCompleted
                      ? 'Inspection Submitted Successfully!'
                      : 'Transmitting Encrypted Inspection...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isCompleted
                      ? 'Official audit report filed under Dossier ID: ${widget.inspectionId}.'
                      : 'Please maintain network connection while files and evidence hashes sync.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                // Step Progress Box
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C192E).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    border: Border.all(
                      color: AppColors.cyberBorder.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(_steps.length, (index) {
                      final isStepDone = _currentStep > index;
                      final isStepActive = _currentStep == index && !_isCompleted;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            if (isStepDone)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppColors.neonEmerald,
                              )
                            else if (isStepActive)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.neonCyan,
                                ),
                              )
                            else
                              const Icon(
                                Icons.radio_button_unchecked,
                                size: 18,
                                color: Colors.white24,
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _steps[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isStepDone || isStepActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isStepDone
                                      ? Colors.white
                                      : isStepActive
                                          ? AppColors.neonCyan
                                          : Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(),

                if (_isCompleted) ...[
                  // Digital Receipt Certificate Card
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09231D),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: AppColors.neonEmerald.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonEmerald.withValues(alpha: 0.12),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: AppColors.neonEmerald,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Digital Receipt: MOSJE-RCPT-2026-9901',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neonEmerald,
                                ),
                              ),
                              Text(
                                'SHA-256 Tamper Seal verified on Central Portal.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Return to PMU Dashboard',
                    icon: Icons.dashboard_rounded,
                    onPressed: () {
                      context.go(AppRoutes.dashboard);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
