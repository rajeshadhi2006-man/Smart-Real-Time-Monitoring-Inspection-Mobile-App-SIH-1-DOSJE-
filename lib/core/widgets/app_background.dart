import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AppBackgroundVariant {
  hero,
  operational,
  analytical,
  calm,
}

/// Ultra-Modern, Luminous Cyber-Space Background System
/// Features deep obsidian foundations, radiant neon ambient orbs,
/// flowing illuminated splines, and sovereign Ashoka radar geometry.
class AppBackground extends StatelessWidget {
  final Widget child;
  final AppBackgroundVariant variant;
  final bool showPattern;

  const AppBackground({
    super.key,
    required this.child,
    this.variant = AppBackgroundVariant.operational,
    this.showPattern = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Deep Cyber Foundation Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(),
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
          ),
        ),

        // 2. High-Tech Visual Painter (Neon Glowing Orbs, Splines, Ashoka Radar)
        if (showPattern)
          Positioned.fill(
            child: CustomPaint(
              painter: _CyberDesignPainter(variant: variant),
            ),
          ),

        // 3. Primary screen content layer
        child,
      ],
    );
  }

  List<Color> _getGradientColors() {
    switch (variant) {
      case AppBackgroundVariant.hero:
        return const [
          Color(0xFF050C18), // Deep Obsidian Navy
          Color(0xFF0C192E), // Cyber Sapphire
          Color(0xFF091424), // Midnight Blue
          Color(0xFF030710), // Deep Void
        ];
      case AppBackgroundVariant.analytical:
        return const [
          Color(0xFF04101A), // Deep Cyber Teal
          Color(0xFF081E2C), // Aquamarine Void
          Color(0xFF061522), // Midnight Cyan
          Color(0xFF020910), // Deep Foundation
        ];
      case AppBackgroundVariant.operational:
        return const [
          Color(0xFF060E1A), // Deep Command Navy
          Color(0xFF0C1B33), // Electric Slate
          Color(0xFF091528), // Midnight Space
          Color(0xFF040912), // Deep Foundation
        ];
      case AppBackgroundVariant.calm:
        return const [
          Color(0xFF0D0F18), // Warm Midnight Velvet
          Color(0xFF151828), // Royal Amethyst Space
          Color(0xFF0E1220), // Deep Indigo Base
          Color(0xFF07080E), // Base Foundation
        ];
    }
  }
}

class _CyberDesignPainter extends CustomPainter {
  final AppBackgroundVariant variant;

  const _CyberDesignPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // A. RADIANT NEON GLOWING AMBIENT ORBS
    // 1. Top-Left: Radiant Solar Saffron / Gold Orb
    final Paint saffronGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9933).withValues(alpha: 0.38),
          const Color(0xFFFF9933).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.15, height * 0.08),
        radius: width * 0.60,
      ));
    canvas.drawCircle(Offset(width * 0.15, height * 0.08), width * 0.60, saffronGlow);

    // 2. Top-Right: Electric Neon Cyan Orb
    final Paint cyanGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00F0FF).withValues(alpha: 0.35),
          const Color(0xFF00F0FF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.88, height * 0.16),
        radius: width * 0.65,
      ));
    canvas.drawCircle(Offset(width * 0.88, height * 0.16), width * 0.65, cyanGlow);

    // 3. Middle-Left: Royal Violet / Neon Amethyst Orb
    final Paint violetGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withValues(alpha: 0.28),
          const Color(0xFF8B5CF6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.08, height * 0.50),
        radius: width * 0.55,
      ));
    canvas.drawCircle(Offset(width * 0.08, height * 0.50), width * 0.55, violetGlow);

    // 4. Center/Bottom: Cyber Emerald Mint Orb
    final Paint emeraldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF88).withValues(alpha: 0.25),
          const Color(0xFF00FF88).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(width * 0.72, height * 0.78),
        radius: width * 0.65,
      ));
    canvas.drawCircle(Offset(width * 0.72, height * 0.78), width * 0.65, emeraldGlow);

    // B. DYNAMIC ILLUMINATED CYBER SPLINES
    final splinePaint1 = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path1 = Path();
    path1.moveTo(0, height * 0.22);
    path1.cubicTo(
      width * 0.35, height * 0.10,
      width * 0.65, height * 0.32,
      width, height * 0.18,
    );
    canvas.drawPath(path1, splinePaint1);

    final splinePaint2 = Paint()
      ..color = const Color(0xFFFF9933).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final path2 = Path();
    path2.moveTo(0, height * 0.28);
    path2.cubicTo(
      width * 0.30, height * 0.40,
      width * 0.70, height * 0.16,
      width, height * 0.28,
    );
    canvas.drawPath(path2, splinePaint2);

    // Bottom Horizon Laser Wave
    final splinePaint3 = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path3 = Path();
    path3.moveTo(0, height * 0.84);
    path3.quadraticBezierTo(width * 0.5, height * 0.90, width, height * 0.82);
    canvas.drawPath(path3, splinePaint3);

    // C. SOVEREIGN ASHOKA CHAKRA / GEOFENCE RADAR WATERMARK MOTIF
    final watermarkCenter = Offset(width * 0.85, height * 0.11);
    final watermarkPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Concentric geofence rings
    canvas.drawCircle(watermarkCenter, 60, watermarkPaint);
    canvas.drawCircle(watermarkCenter, 42, watermarkPaint);
    canvas.drawCircle(watermarkCenter, 24, watermarkPaint);
    canvas.drawCircle(watermarkCenter, 7, watermarkPaint);

    // 12 radiating coordinate lines
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final p1 = Offset(
        watermarkCenter.dx + 24 * math.cos(angle),
        watermarkCenter.dy + 24 * math.sin(angle),
      );
      final p2 = Offset(
        watermarkCenter.dx + 60 * math.cos(angle),
        watermarkCenter.dy + 60 * math.sin(angle),
      );
      canvas.drawLine(p1, p2, watermarkPaint);
    }

    // D. HIGH-TECH CYBER DOT MATRIX GRID (Glowing neon dots)
    final dotPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.14)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const double dotSpacing = 24.0;
    final double maxGridHeight = height * 0.40;

    for (double x = 16; x < width - 10; x += dotSpacing) {
      for (double y = 16; y < maxGridHeight; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CyberDesignPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
