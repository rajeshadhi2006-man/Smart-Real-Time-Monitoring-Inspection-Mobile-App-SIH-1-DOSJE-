import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Pill badge representing AI anomaly Risk Levels (LOW, MEDIUM, HIGH, CRITICAL)
class RiskBadge extends StatelessWidget {
  final String riskLevel;

  const RiskBadge({
    super.key,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;

    switch (riskLevel.toLowerCase()) {
      case 'low':
        color = AppColors.successGreen;
        bgColor = AppColors.successLight;
        break;
      case 'medium':
        color = AppColors.warningAmber;
        bgColor = AppColors.warningLight;
        break;
      case 'high':
      case 'critical':
        color = AppColors.dangerRed;
        bgColor = AppColors.dangerLight;
        break;
      default:
        color = AppColors.textSecondary;
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 12, color: color),
          const SizedBox(width: AppDimensions.space4),
          Text(
            'RISK: ${riskLevel.toUpperCase()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
