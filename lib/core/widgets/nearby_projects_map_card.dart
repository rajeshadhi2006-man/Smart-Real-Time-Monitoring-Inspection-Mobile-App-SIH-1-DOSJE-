import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../features/inspections/domain/models/inspection_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// High-Tech Cyber Radar Viewport displaying nearby assigned audit facilities
class NearbyProjectsMapCard extends StatelessWidget {
  final int activeProjectsCount;
  final List<InspectionModel> inspections;
  final VoidCallback onTap;

  const NearbyProjectsMapCard({
    super.key,
    required this.activeProjectsCount,
    this.inspections = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2342),
            Color(0xFF081426),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with live satellite chip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 18,
                          color: Color(0xFF00F0FF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Nearby Field Facilities',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentTeal.withValues(alpha: 0.15),
                            AppColors.accentCyan.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        border: Border.all(
                          color: AppColors.accentTeal.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        inspections.isEmpty
                            ? 'Awaiting Enrollment'
                            : '${inspections.length} Enrolled',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. High-Tech Cyber Radar Viewport
              Container(
                height: 130,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF071426), // Deep Space Navy
                      Color(0xFF0F2648), // Cyber Slate
                      Color(0xFF0A1F3B), // Midnight Blue
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium - 1),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radar Grid Lines & Rings Painter
                      CustomPaint(
                        size: const Size(double.infinity, 130),
                        painter: _FuturisticRadarPainter(),
                      ),

                      // Center Inspector Node with glowing pulse
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'You (GPS Live)',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Dynamic Render: Only plot real enrolled inspections
                      if (inspections.isEmpty) ...[
                        Positioned(
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1F38).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: const Text(
                              'Radar Ready • Awaiting Web Portal Site Enrollment',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Dynamic Pin 1
                        if (inspections.isNotEmpty)
                          Positioned(
                            top: 20,
                            right: 24,
                            child: _buildPin(
                              label: inspections[0].projectName.length > 20
                                  ? '${inspections[0].projectName.substring(0, 18)}...'
                                  : inspections[0].projectName,
                              color: const Color(0xFF10B981),
                              dotColor: const Color(0xFF34D399),
                            ),
                          ),
                        // Dynamic Pin 2
                        if (inspections.length > 1)
                          Positioned(
                            bottom: 22,
                            left: 20,
                            child: _buildPin(
                              label: inspections[1].projectName.length > 20
                                  ? '${inspections[1].projectName.substring(0, 18)}...'
                                  : inspections[1].projectName,
                              color: const Color(0xFF06B6D4),
                              dotColor: const Color(0xFF67E8F9),
                            ),
                          ),
                        // Dynamic Pin 3
                        if (inspections.length > 2)
                          Positioned(
                            top: 24,
                            left: 40,
                            child: _buildPin(
                              label: inspections[2].projectName.length > 20
                                  ? '${inspections[2].projectName.substring(0, 18)}...'
                                  : inspections[2].projectName,
                              color: const Color(0xFFFBBF24),
                              dotColor: const Color(0xFFFDE68A),
                            ),
                          ),
                      ],

                      // Bottom-left geofence mode label
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: Text(
                          '100m Perimeter Lock',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Bottom footer link
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to open interactive live geofence radar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.accentTeal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPin({
    required String label,
    required Color color,
    required Color dotColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.9),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _FuturisticRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Glowing cyan radar rings
    final ringPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset(centerX, centerY), 28, ringPaint);
    canvas.drawCircle(Offset(centerX, centerY), 56, ringPaint);
    canvas.drawCircle(Offset(centerX, centerY), 85, ringPaint);

    // Inner 100m geofence ring (Emerald dashed-like ring)
    final geofencePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(centerX, centerY), 42, geofencePaint);

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.20)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      crosshairPaint,
    );

    // 45-degree diagonal radar grid rays
    for (int angle in [45, 135, 225, 315]) {
      final rad = angle * math.pi / 180;
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(centerX + 90 * math.cos(rad), centerY + 90 * math.sin(rad)),
        crosshairPaint..color = const Color(0xFF0EA5E9).withValues(alpha: 0.10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
