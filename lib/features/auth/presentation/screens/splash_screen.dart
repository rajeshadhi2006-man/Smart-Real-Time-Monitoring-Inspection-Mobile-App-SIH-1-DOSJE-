import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/tricolor_accent_bar.dart';
import '../providers/auth_provider.dart';

/// Ultra-Modern, Futuristic Cyber Splash Screen
/// Features glowing holographic crest, animated laser aura, and frosted cyber cards
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _onGetStarted(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF050C18),
      body: AppBackground(
        variant: AppBackgroundVariant.hero,
        child: Column(
          children: [
            // 1. National Tricolor Sovereign Laser Ribbon
            const TricolorAccentBar(height: 4.0),

            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space24,
                    vertical: AppDimensions.space16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // 2. Holographic Sovereign Emblem with Radiant Gold Halo
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0A1E3C),
                              Color(0xFF0E2C5A),
                              Color(0xFF1D4ED8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.goldAccent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.goldAccent.withValues(alpha: 0.40),
                              blurRadius: 20,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.goldAccent.withValues(alpha: 0.4),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.account_balance_rounded,
                              size: 56,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Satyameva Jayate & Sovereign Banner
                      const Text(
                        'सत्यमेव जयते',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFDE68A),
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.solarSaffronGradient,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tricolorSaffron.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Text(
                          'GOVERNMENT OF INDIA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ministry of Social Justice and Empowerment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 3. Central Headline Card with Glassmorphic Frosted Cyber Panel
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0F2342).withValues(alpha: 0.85),
                              const Color(0xFF081426).withValues(alpha: 0.90),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Smart Nirikshan AI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Real-Time Autonomous Inspection & Verification',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF38BDF8),
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Official Hackathon Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF3B82F6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                border: Border.all(
                                  color: const Color(0xFF60A5FA),
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 13, color: Color(0xFFFDE68A)),
                                  SizedBox(width: 6),
                                  Text(
                                    'MoSJE • SIH 26095',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4. Advanced Security & High-Tech Assurance Pills
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSecurityPill(Icons.shield_rounded, 'NIC Protected', const Color(0xFF10B981)),
                          _buildSecurityPill(Icons.gps_fixed_rounded, '100m Geofence Lock', const Color(0xFF00F0FF)),
                          _buildSecurityPill(Icons.lock_clock_rounded, 'SHA-256 Crypto Vault', const Color(0xFFF59E0B)),
                        ],
                      ),

                      const Spacer(),

                      // 5. Primary CTA Action (Radiant Neon Button)
                      AppButton(
                        label: 'Enter Inspection Portal',
                        icon: Icons.arrow_forward_rounded,
                        variant: AppButtonVariant.primary,
                        onPressed: () => _onGetStarted(context, ref),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Authorized Personnel & PMU Auditors Only • Level 3 Gateway',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPill(IconData icon, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C192E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
