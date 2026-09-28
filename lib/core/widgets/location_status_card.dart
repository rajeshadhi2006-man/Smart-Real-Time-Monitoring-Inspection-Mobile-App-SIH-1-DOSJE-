import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/geo_utils.dart';

/// Critical GPS location verification card
class LocationStatusCard extends StatelessWidget {
  final bool isVerified;
  final double distanceMeters;
  final double? accuracyMeters;
  final bool isDetecting;
  final String? errorMessage;
  final VoidCallback onRetry;

  const LocationStatusCard({
    super.key,
    required this.isVerified,
    required this.distanceMeters,
    this.accuracyMeters,
    this.isDetecting = false,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isVerified ? AppColors.successGreen : AppColors.warningAmber;
    final statusBg = isVerified ? AppColors.successLight : AppColors.warningLight;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2E),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isVerified ? AppColors.successGreen.withValues(alpha: 0.6) : AppColors.warningAmber.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isVerified ? AppColors.successGreen : AppColors.warningAmber).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 18,
                    color: isVerified ? AppColors.neonCyan : AppColors.warningAmber,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  const Text(
                    'LOCATION VERIFICATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      isVerified ? 'VERIFIED' : 'OUTSIDE RADIUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          _buildLocationRow(
            label: 'Current Location',
            status: isDetecting ? 'Detecting GPS...' : 'Detected',
            isPositive: !isDetecting,
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildLocationRow(
            label: 'Project Location',
            status: 'Registered Anchor',
            isPositive: true,
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildLocationRow(
            label: 'Distance to Site',
            status: GeoUtils.formatDistance(distanceMeters),
            isPositive: isVerified,
          ),
          if (accuracyMeters != null) ...[
            const SizedBox(height: AppDimensions.space8),
            _buildLocationRow(
              label: 'GPS Accuracy',
              status: '±${accuracyMeters!.toStringAsFixed(1)} m',
              isPositive: accuracyMeters! <= 25,
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: AppDimensions.space12),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: AppDimensions.roundedSmall,
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.dangerRed),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.dangerRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonCyan,
                side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                backgroundColor: AppColors.neonCyan.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: isDetecting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                isDetecting ? 'Acquiring GPS...' : 'Refresh Location',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: isDetecting ? null : onRetry,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required String label,
    required String status,
    required bool isPositive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isPositive ? AppColors.successGreen : AppColors.warningAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPositive ? AppColors.textPrimary : AppColors.warningAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
