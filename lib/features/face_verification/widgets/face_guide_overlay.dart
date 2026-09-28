import 'dart:math' as math;
import 'package:flutter/material.dart';

enum FaceGuideStatus {
  idle,
  detecting,
  valid,
  warning,
  error,
}

/// Sovereign Face Biometric Guide Overlay
/// Official MoSJE Sovereign Field Verification UX:
/// - Dual concentric oval with dynamic rotating radar tracking arc
/// - 5-Point facial landmark reticle (Left Eye, Right Eye, Nose Tip, Mouth Corners)
/// - Bilingual instructions (Hindi + English)
/// - Ambient illumination (Lux) and face distance telemetry
/// - Active liveness challenge (Blink detection prompt with pulsing eye)
/// - Shutter flash animation on capture
class FaceGuideOverlay extends StatefulWidget {
  final FaceGuideStatus status;
  final String instruction;
  final String? hindiInstruction;
  final bool isScanning;
  final bool isAadhaarMode;
  final bool showLandmarks;
  final bool promptBlink;
  final int? illuminationLux;
  final String? distanceStatus;
  final VoidCallback? onBlinkTap;
  final VoidCallback? onTap;
  final String? tapToScanLabel;

  const FaceGuideOverlay({
    super.key,
    required this.status,
    required this.instruction,
    this.hindiInstruction,
    this.isScanning = false,
    this.isAadhaarMode = false,
    this.showLandmarks = false,
    this.promptBlink = false,
    this.illuminationLux,
    this.distanceStatus,
    this.onBlinkTap,
    this.onTap,
    this.tapToScanLabel,
  });

  @override
  State<FaceGuideOverlay> createState() => _FaceGuideOverlayState();
}

class _FaceGuideOverlayState extends State<FaceGuideOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _radarController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _radarController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case FaceGuideStatus.valid:
        return const Color(0xFF10B981); // Sovereign Emerald green
      case FaceGuideStatus.detecting:
        return widget.isAadhaarMode ? const Color(0xFFFF9933) : const Color(0xFF38BDF8); // Aadhaar Saffron or Cyan
      case FaceGuideStatus.warning:
        return const Color(0xFFF59E0B); // Amber
      case FaceGuideStatus.error:
        return const Color(0xFFEF4444); // Red
      case FaceGuideStatus.idle:
        return widget.isAadhaarMode ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.85);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      child: Stack(
        children: [
          // 1. Custom Painter for Oval Cutout, Radar Arc & Landmark Crosshairs
          AnimatedBuilder(
            animation: Listenable.merge([_animController, _radarController]),
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _FaceOverlayPainter(
                  borderColor: statusColor,
                  scanProgress: widget.isScanning ? _animController.value : null,
                  radarAngle: _radarController.value * 2 * math.pi,
                  isAadhaarMode: widget.isAadhaarMode,
                  showLandmarks: widget.showLandmarks,
                ),
              );
            },
          ),

          // 2. Aadhaar FaceRD Telemetry Badges (Distance & Lighting)
          if (widget.isAadhaarMode)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lighting Lux Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC040A15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x4038BDF8), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, size: 13, color: Color(0xFFFDE68A)),
                        const SizedBox(width: 5),
                        Text(
                          "${widget.illuminationLux ?? 420} LUX • OPTIMAL",
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Distance Telemetry Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC040A15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x4038BDF8), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten_rounded, size: 13, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 5),
                        Text(
                          widget.distanceStatus ?? "35 CM • ALIGNED",
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Interactive Tap-To-Scan Action Badge inside Oval
          if (widget.onTap != null && !widget.isScanning)
            Align(
              alignment: const Alignment(0.0, 0.42),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final pulse = 1.0 + (_animController.value * 0.05);
                    return Transform.scale(
                      scale: pulse,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xF0071C38), Color(0xF0031124)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: statusColor,
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                              child: const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF040A15)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.tapToScanLabel ?? "CLICK TO SCAN FACE ARC",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 4. Aadhaar Liveness "Blink Eyes" Interactive Banner
          if (widget.promptBlink)
            Align(
              alignment: const Alignment(0.0, 0.44),
              child: GestureDetector(
                onTap: widget.onBlinkTap,
                child: AnimatedBuilder(
                  animation: _blinkController,
                  builder: (context, child) {
                    final scale = 1.0 + (_blinkController.value * 0.08);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _blinkController.value > 0.5
                                  ? Icons.remove_red_eye_rounded
                                  : Icons.visibility_off_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "कृपया पलकें झपकाएं • PLEASE BLINK EYES",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  "Neural Passive Liveness Verification Active (Tap to Simulate)",
                                  style: TextStyle(
                                    color: Color(0xFFFFE4E6),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 5. Floating Aadhaar Instruction Pill at Bottom of Frame
          Align(
            alignment: const Alignment(0.0, 0.72),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xEE040A15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.hindiInstruction != null) ...[
                          Text(
                            widget.hindiInstruction!,
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          widget.instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.status) {
      case FaceGuideStatus.valid:
        return const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20);
      case FaceGuideStatus.detecting:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9933)),
          ),
        );
      case FaceGuideStatus.warning:
        return const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20);
      case FaceGuideStatus.error:
        return const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20);
      case FaceGuideStatus.idle:
        return const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF38BDF8), size: 20);
    }
  }
}

class _FaceOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double? scanProgress;
  final double radarAngle;
  final bool isAadhaarMode;
  final bool showLandmarks;

  _FaceOverlayPainter({
    required this.borderColor,
    this.scanProgress,
    required this.radarAngle,
    this.isAadhaarMode = false,
    this.showLandmarks = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.72);

    final bool isLandscape = size.width > size.height;
    final centerX = size.width / 2;
    final centerY = isLandscape ? size.height * 0.46 : size.height * 0.38;
    final ovalWidth = isLandscape
        ? math.min(size.height * 0.58, 420.0)
        : math.min(size.width * 0.72, 380.0);
    final ovalHeight = ovalWidth * 1.30;

    final ovalRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalWidth,
      height: ovalHeight,
    );

    // 1. Draw outer background with oval cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, bgPaint);

    // 2. Draw Outer Subtle Halo Oval (Aadhaar concentric guidance)
    if (isAadhaarMode) {
      final outerOvalRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: ovalWidth + 16,
        height: ovalHeight + 16,
      );
      final outerHaloPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(outerOvalRect, outerHaloPaint);

      // Rotating Aadhaar Tracking Arc
      final radarPaint = Paint()
        ..color = const Color(0xFFFF9933).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      canvas.drawArc(
        outerOvalRect,
        radarAngle,
        1.1, // ~63 degree sweep
        false,
        radarPaint,
      );

      // Symmetrical Green Arc for Sovereign Tricolor balance
      final emeraldArcPaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      canvas.drawArc(
        outerOvalRect,
        radarAngle + math.pi,
        1.1,
        false,
        emeraldArcPaint,
      );
    }

    // 3. Draw Primary Oval Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    canvas.drawOval(ovalRect, borderPaint);

    // 4. Draw Aadhaar / Cyber Reticle Corner Brackets
    final bracketPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 26.0;
    final left = ovalRect.left - 10;
    final top = ovalRect.top - 10;
    final right = ovalRect.right + 10;
    final bottom = ovalRect.bottom + 10;

    // Top-Left Bracket
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), bracketPaint);

    // Top-Right Bracket
    canvas.drawLine(Offset(right - cornerLen, top), Offset(right, top), bracketPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLen), bracketPaint);

    // Bottom-Left Bracket
    canvas.drawLine(Offset(left, bottom - cornerLen), Offset(left, bottom), bracketPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLen, bottom), bracketPaint);

    // Bottom-Right Bracket
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right, bottom), bracketPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen), bracketPaint);

    // 4.5. Head & Chin Positioning Biometric Arcs
    final guideArcPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Upper forehead arc
    final foreheadRect = Rect.fromCenter(
      center: Offset(centerX, centerY - ovalHeight * 0.20),
      width: ovalWidth * 0.62,
      height: ovalHeight * 0.38,
    );
    canvas.drawArc(foreheadRect, math.pi * 1.15, math.pi * 0.70, false, guideArcPaint);

    // Lower chin arc
    final chinRect = Rect.fromCenter(
      center: Offset(centerX, centerY + ovalHeight * 0.25),
      width: ovalWidth * 0.48,
      height: ovalHeight * 0.32,
    );
    canvas.drawArc(chinRect, math.pi * 0.15, math.pi * 0.70, false, guideArcPaint);

    // 5. Draw Aadhaar 5-Point Landmark Target Crosshairs (Eyes, Nose, Mouth)
    if (showLandmarks) {
      final landmarkPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final dotPaint = Paint()
        ..color = const Color(0xFFFDE68A)
        ..style = PaintingStyle.fill;

      // Coordinates relative to oval center
      final eyeY = centerY - (ovalHeight * 0.12);
      final leftEyeX = centerX - (ovalWidth * 0.22);
      final rightEyeX = centerX + (ovalWidth * 0.22);
      final noseY = centerY + (ovalHeight * 0.04);
      final mouthY = centerY + (ovalHeight * 0.22);
      final leftMouthX = centerX - (ovalWidth * 0.14);
      final rightMouthX = centerX + (ovalWidth * 0.14);

      final points = [
        Offset(leftEyeX, eyeY),
        Offset(rightEyeX, eyeY),
        Offset(centerX, noseY),
        Offset(leftMouthX, mouthY),
        Offset(rightMouthX, mouthY),
      ];

      // Draw constellation connecting lines
      final constellationPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawLine(points[0], points[1], constellationPaint);
      canvas.drawLine(points[0], points[2], constellationPaint);
      canvas.drawLine(points[1], points[2], constellationPaint);
      canvas.drawLine(points[2], points[3], constellationPaint);
      canvas.drawLine(points[2], points[4], constellationPaint);
      canvas.drawLine(points[3], points[4], constellationPaint);

      for (final p in points) {
        // Draw crosshair
        canvas.drawLine(Offset(p.dx - 8, p.dy), Offset(p.dx + 8, p.dy), landmarkPaint);
        canvas.drawLine(Offset(p.dx, p.dy - 8), Offset(p.dx, p.dy + 8), landmarkPaint);
        canvas.drawCircle(p, 2.5, dotPaint);
      }
    }

    // 6. Scanning Laser Beam if Active
    if (scanProgress != null) {
      final beamY = ovalRect.top + ovalRect.height * scanProgress!;
      final laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            borderColor.withValues(alpha: 0.0),
            borderColor.withValues(alpha: 0.95),
            borderColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(ovalRect.left, beamY - 3, ovalRect.width, 6))
        ..strokeWidth = 3.5;

      canvas.drawLine(
        Offset(ovalRect.left + 12, beamY),
        Offset(ovalRect.right - 12, beamY),
        laserPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FaceOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.scanProgress != scanProgress ||
        oldDelegate.radarAngle != radarAngle ||
        oldDelegate.showLandmarks != showLandmarks ||
        oldDelegate.isAadhaarMode != isAadhaarMode;
  }
}
