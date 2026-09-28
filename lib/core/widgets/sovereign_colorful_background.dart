import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Sovereign Colorful Background
/// Premium, colorful national digital architecture canvas with glowing tricolor auroras,
/// Ashoka Chakra sacred geometry, and high-tech defense-grade ambient depth.
class SovereignColorfulBackground extends StatelessWidget {
  final Widget child;
  final bool showWatermark;
  final bool showGrid;

  const SovereignColorfulBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base Deep Cosmic Navy Gradient Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF040A15), // Ultra-deep space navy
                  Color(0xFF08152B), // Ashoka midnight
                  Color(0xFF0A1F3E), // Royal blue deep
                  Color(0xFF060E1E), // Sovereign ground
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // 2. Ambient Glow 1: Radiant National Saffron Aura (Top Right)
        Positioned(
          top: -100,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9933).withValues(alpha: 0.28), // Vibrant Saffron
                    const Color(0xFFEA580C).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Ambient Glow 2: Sovereign Emerald Green Aura (Bottom Left)
        Positioned(
          bottom: -120,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.26), // Sovereign Green
                    const Color(0xFF059669).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 4. Ambient Glow 3: Ashoka Royal Blue Core Glow (Center Left)
        Positioned(
          top: size.height * 0.35,
          left: size.width * 0.2,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.22), // Electric Royal Blue
                    const Color(0xFF1D4ED8).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 5. Subtle Sacred Ashoka Chakra Watermark & Defense Orbital Rings
        if (showWatermark)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SovereignWatermarkPainter(),
              ),
            ),
          ),

        // 6. Subtle High-Tech Lattice Grid Lines
        if (showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TechGridPainter(),
              ),
            ),
          ),

        // 7. Child Content (Wrapped in Positioned.fill and transparent Material for safe layout & event bubbling)
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for Ashoka Chakra watermark & tactical orbital concentric rings
class _SovereignWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.25);
    final centerBottom = Offset(size.width * 0.1, size.height * 0.82);

    final ringPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final saffronRing = Paint()
      ..color = const Color(0xFFFF9933).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final greenRing = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric orbital defense rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, i * 45.0, i % 2 == 0 ? ringPaint : saffronRing);
    }

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(centerBottom, i * 50.0, greenRing);
    }

    // 24-spoke Ashoka Chakra geometry watermark in background
    final chakraCenter = Offset(size.width * 0.5, size.height * 0.5);
    final chakraRadius = size.width * 0.38;

    final chakraPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(chakraCenter, chakraRadius, chakraPaint);
    canvas.drawCircle(chakraCenter, chakraRadius * 0.85, chakraPaint);
    canvas.drawCircle(chakraCenter, chakraRadius * 0.25, chakraPaint);

    for (int i = 0; i < 24; i++) {
      final angle = i * (2 * math.pi / 24);
      final x1 = chakraCenter.dx + (chakraRadius * 0.25) * math.cos(angle);
      final y1 = chakraCenter.dy + (chakraRadius * 0.25) * math.sin(angle);
      final x2 = chakraCenter.dx + chakraRadius * math.cos(angle);
      final y2 = chakraCenter.dy + chakraRadius * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), chakraPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for subtle cyber-defense grid dots
class _TechGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const step = 48.0;
    for (double x = 20; x < size.width; x += step) {
      for (double y = 20; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
