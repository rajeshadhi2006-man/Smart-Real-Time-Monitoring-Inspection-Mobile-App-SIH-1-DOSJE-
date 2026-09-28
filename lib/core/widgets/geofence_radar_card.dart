import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Geofence Radar Card
/// High-impact visual radar tracking the inspector's distance to target facility
class GeofenceRadarCard extends StatelessWidget {
  final String facilityName;
  final String schemeName;
  final double distanceMeters;
  final double radiusMeters;
  final bool isInside;
  final VoidCallback? onNavigate;
  final VoidCallback? onVerify;

  const GeofenceRadarCard({
    super.key,
    required this.facilityName,
    required this.schemeName,
    required this.distanceMeters,
    this.radiusMeters = 500,
    required this.isInside,
    this.onNavigate,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final distKm = (distanceMeters / 1000).toStringAsFixed(2);
    final distDisplay = distanceMeters < 1000
        ? "${distanceMeters.toStringAsFixed(0)} m"
        : "$distKm km";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A192F),
            Color(0xFF0F274A),
            Color(0xFF132E59),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInside
              ? AppColors.statusGreen.withValues(alpha: 0.5)
              : const Color(0xFF243B66),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isInside
                ? AppColors.statusGreen.withValues(alpha: 0.15)
                : const Color(0x2E0A192F),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Radar Rings Graphic (Watermark)
          Positioned(
            right: -25,
            top: -25,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Scheme Tag + Perimeter Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.tricolorSaffron.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.tricolorSaffron.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          schemeName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInside
                            ? AppColors.statusGreen.withValues(alpha: 0.18)
                            : AppColors.statusAmber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isInside
                              ? AppColors.statusGreen
                              : AppColors.statusAmber,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isInside ? AppColors.statusGreen : AppColors.statusAmber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isInside ? AppColors.statusGreen : AppColors.statusAmber).withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isInside ? "INSIDE GEOFENCE" : "APPROACHING ZONE",
                            style: TextStyle(
                              color: isInside ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Facility Name
                Text(
                  facilityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Distance Radar Indicator & Progress Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      // Radial Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (isInside ? AppColors.statusGreen : const Color(0xFF38BDF8)).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isInside ? AppColors.statusGreen : const Color(0xFF38BDF8),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isInside ? Icons.my_location_rounded : Icons.explore_rounded,
                          color: isInside ? AppColors.statusGreen : const Color(0xFF38BDF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Distance Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Target Perimeter Gap",
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  distDisplay,
                                  style: TextStyle(
                                    color: isInside ? AppColors.statusGreen : Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Micro Linear Progress
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: isInside ? 1.0 : (radiusMeters / (distanceMeters + radiusMeters)).clamp(0.05, 0.95),
                                minHeight: 6,
                                backgroundColor: const Color(0xFF1E293B),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isInside ? AppColors.statusGreen : const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Triggers: Navigate & Verify
                Row(
                  children: [
                    if (onNavigate != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: const Text(
                            "MAP ROUTE",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B82F6), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (onNavigate != null && onVerify != null)
                      const SizedBox(width: 10),
                    if (onVerify != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onVerify,
                          icon: Icon(
                            isInside ? Icons.verified_rounded : Icons.fingerprint_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isInside ? "START AUDIT" : "VERIFY SITE",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInside ? AppColors.statusGreen : const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
