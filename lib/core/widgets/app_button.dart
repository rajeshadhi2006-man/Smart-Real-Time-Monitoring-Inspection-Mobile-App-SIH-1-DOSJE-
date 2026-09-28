import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// Premium high-tech enterprise button with tactile gradient, bevel sheen, and icon capsule
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 52.0,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    List<Color> gradientColors;
    Color textColor;
    Border? border;
    List<BoxShadow> shadows;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        gradientColors = isEnabled
            ? const [
                Color(0xFF0284C7), // Vibrant Ocean Blue
                Color(0xFF0369A1), // Deep Sapphire
                Color(0xFF075985),
              ]
            : [const Color(0xFF1E293B), const Color(0xFF0F172A)];
        textColor = Colors.white;
        border = Border.all(
          color: isEnabled ? const Color(0xFF38BDF8) : Colors.white12,
          width: 1.3,
        );
        shadows = isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [];
        break;

      case AppButtonVariant.secondary:
        gradientColors = isEnabled
            ? const [
                Color(0xFF0D9488), // Tech Teal
                Color(0xFF0F766E), // Deep Teal
              ]
            : [const Color(0xFF1E293B), const Color(0xFF0F172A)];
        textColor = Colors.white;
        border = Border.all(
          color: isEnabled ? const Color(0xFF2DD4BF) : Colors.white12,
          width: 1.3,
        );
        shadows = isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [];
        break;

      case AppButtonVariant.outline:
        gradientColors = [
          const Color(0xFF0D1B2E),
          const Color(0xFF091424),
        ];
        textColor = AppColors.neonCyan;
        border = Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.5),
          width: 1.4,
        );
        shadows = [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case AppButtonVariant.danger:
        gradientColors = isEnabled
            ? const [
                Color(0xFFDC2626),
                Color(0xFF991B1B),
              ]
            : [Colors.grey.shade400, Colors.grey.shade500];
        textColor = Colors.white;
        border = Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        );
        shadows = isEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : [];
        break;
    }

    final effectiveRadius = BorderRadius.circular(16.0);

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          border: border,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: effectiveRadius,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Label text with modern Plus Jakarta Sans typography
                        Flexible(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Trailing Icon Capsule Pill
                        if (widget.icon != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: widget.variant == AppButtonVariant.outline
                                  ? AppColors.primaryLight
                                  : Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                widget.icon,
                                size: 16,
                                color: widget.variant == AppButtonVariant.outline
                                    ? AppColors.primaryNavy
                                    : textColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
