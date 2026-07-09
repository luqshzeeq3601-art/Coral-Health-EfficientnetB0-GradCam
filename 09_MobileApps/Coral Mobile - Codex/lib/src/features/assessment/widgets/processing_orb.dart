import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Animated "processing" orb shown while an analysis runs: a rotating dashed
/// scanner ring, a progress HUD ring, and a pulsing coral/brain node.
///
/// The two pulse-driven animations (scanner rotation and the inner node) are
/// each isolated in their own [RepaintBoundary] so their continuous repaints
/// don't invalidate the progress ring (driven by a separate controller) or
/// each other.
class ProcessingOrb extends StatelessWidget {
  const ProcessingOrb({
    super.key,
    required this.pulseAnimation,
    required this.overallProgress,
  });

  final Animation<double> pulseAnimation;
  final double overallProgress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0E1A33).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2F4D).withValues(alpha: 0.8)
                : AppColors.line.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x1A000000) : const Color(0x122362A7),
              blurRadius: 40,
              offset: const Offset(0, 20),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Outer Scanner Ring (pulse-driven, isolated).
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: pulseAnimation.value * math.pi * 2,
                    child: SizedBox.square(
                      dimension: 220,
                      child: CustomPaint(
                        painter: _DashedScannerPainter(),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Progress Ring (driven by overallProgress, not the pulse).
            SizedBox.square(
              dimension: 190,
              child: CustomPaint(
                painter: _HudRingPainter(
                  progress: overallProgress,
                ),
              ),
            ),

            // Inner Custom Coral Node (pulse-driven, isolated).
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + math.sin(pulseAnimation.value * math.pi * 2) * 0.04,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFF0EA5FF),
                            Color(0xFF0057E6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(68, 68),
                          painter: _BrainPainter(animationValue: pulseAnimation.value),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrainPainter extends CustomPainter {
  final double animationValue;
  _BrainPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final circuitBasePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final circuitGlowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Scale slightly to fit nicely. Base coordinates designed for 44x44
    final double s = size.width / 44.0;
    canvas.scale(s, s);

    // Center Fissure
    canvas.drawLine(const Offset(0, -15), const Offset(0, 15), outlinePaint);

    // Left Hemisphere
    final leftPath = Path();
    leftPath.moveTo(0, -15);
    leftPath.cubicTo(-10, -22, -18, -12, -13, -6);
    leftPath.cubicTo(-24, -4, -22, 9, -13, 9);
    leftPath.cubicTo(-17, 18, -4, 20, 0, 15);
    canvas.drawPath(leftPath, outlinePaint);

    // Right Hemisphere
    final rightPath = Path();
    rightPath.moveTo(0, -15);
    rightPath.cubicTo(10, -22, 18, -12, 13, -6);
    rightPath.cubicTo(24, -4, 22, 9, 13, 9);
    rightPath.cubicTo(17, 18, 4, 20, 0, 15);
    canvas.drawPath(rightPath, outlinePaint);

    // Helper to draw circuits
    void drawCircuit(List<Offset> points, double offsetDelay, double speedMultiplier) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      // Draw faint base path
      canvas.drawPath(path, circuitBasePaint);

      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) return;

      final metric = metrics.first;
      final length = metric.length;

      // Electricity animation loop
      final double rawProgress = (animationValue * speedMultiplier + offsetDelay) % 1.0;

      const tailLength = 6.0;
      final distance = (length + tailLength) * rawProgress;

      final start = (distance - tailLength).clamp(0.0, length).toDouble();
      final end = distance.clamp(0.0, length).toDouble();

      // Draw sharp electricity pulse
      if (start < end) {
        final extractPath = metric.extractPath(start, end);
        canvas.drawPath(extractPath, circuitGlowPaint);
      }

      // Terminal dot behavior
      double radius = 1.5; // Sharp base dot

      if (distance >= length && distance <= length + tailLength) {
        // Flash the dot when electricity hits it
        final hitProgress = (distance - length) / tailLength;
        // Pop effect: expands to 3.0 then shrinks back to 1.5
        radius = 1.5 + 1.5 * math.sin(hitProgress * math.pi);
      }

      final activeDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points.last, radius, activeDotPaint);
    }

    // Left Circuits
    drawCircuit(const [Offset(0, -6), Offset(-4, -10), Offset(-9, -10)], 0.0, 1.5);
    drawCircuit(const [Offset(0, 1), Offset(-4, 1), Offset(-8, 5)], 0.4, 2.0);
    drawCircuit(const [Offset(0, 8), Offset(-4, 12)], 0.8, 1.2);

    // Right Circuits
    drawCircuit(const [Offset(0, -9), Offset(4, -13), Offset(9, -13)], 0.2, 1.8);
    drawCircuit(const [Offset(0, -2), Offset(4, -2), Offset(8, 2)], 0.6, 1.4);
    drawCircuit(const [Offset(0, 5), Offset(4, 9)], 0.9, 2.2);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrainPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _DashedScannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Faint inner and outer guide rings for a precision guide look
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.muted.withValues(alpha: 0.15);

    canvas.drawCircle(center, radius + 2, guidePaint);
    canvas.drawCircle(center, radius - 8, guidePaint);

    // Radial ticks
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.muted.withValues(alpha: 0.25);

    final majorTickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.muted.withValues(alpha: 0.4);

    const tickCount = 72;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * math.pi * 2) / tickCount;
      final bool isMajor = i % 6 == 0;
      final innerRadius = isMajor ? radius - 7 : radius - 3;

      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    // Active Sweep Segment (Radar tail effect)
    for (int i = 0; i < 18; i++) {
      final angle = (i * math.pi * 2) / tickCount;
      // Fade intensity from head (i=0) to tail (i=17)
      final sweepAlpha = (18 - i) / 18.0;

      final sweepTickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary.withValues(alpha: sweepAlpha * 0.9);

      final innerRadius = radius - 6;
      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(p1, p2, sweepTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HudRingPainter extends CustomPainter {
  const _HudRingPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Background groove track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.5);

    final trackBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = AppColors.line.withValues(alpha: 0.4);

    // Active Gradient Progress
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF0057E6), // Deep Blue
          Color(0xFF0EA5FF), // Cyan
          Color(0xFF16B979), // Green
          Color(0xFF5CD8A5), // Light Green
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
        transform: GradientRotation(math.pi * 0.8),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Glow Bloom
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = AppColors.primary.withValues(alpha: 0.25);

    const startAngle = -math.pi * 1.2;
    const maxSweep = math.pi * 1.4;

    // Draw groove
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      maxSweep,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      maxSweep,
      false,
      trackBorderPaint,
    );

    if (progress > 0) {
      final currentSweep = maxSweep * progress;

      // Draw shadow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        shadowPaint,
      );

      // Draw progress
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        activePaint,
      );

      // Draw a glowing head dot at the tip of the progress
      final headAngle = startAngle + currentSweep;
      final headPos = Offset(
        center.dx + radius * math.cos(headAngle),
        center.dy + radius * math.sin(headAngle),
      );

      final headGlowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final headCorePaint = Paint()..color = Colors.white;

      canvas.drawCircle(headPos, 5.0, headGlowPaint);
      canvas.drawCircle(headPos, 3.5, headCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
