import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Micro-precision national tricolor ribbon (Saffron, White, Emerald Green)
/// Adds prestigious Government of India sovereign identity to headers and cards
class TricolorAccentBar extends StatelessWidget {
  final double height;
  final BorderRadius? borderRadius;

  const TricolorAccentBar({
    super.key,
    this.height = 3.5,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.tricolorSaffron,
            AppColors.tricolorSaffron,
            Colors.white,
            Colors.white,
            AppColors.tricolorGreen,
            AppColors.tricolorGreen,
          ],
          stops: [0.0, 0.33, 0.33, 0.66, 0.66, 1.0],
        ),
      ),
    );
  }
}
