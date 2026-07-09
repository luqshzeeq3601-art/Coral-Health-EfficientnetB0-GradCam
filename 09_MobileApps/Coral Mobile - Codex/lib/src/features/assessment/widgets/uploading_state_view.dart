import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Animated progress view shown inside the upload drop zone while a file is
/// "uploading": an ambient pulse glow, a rotating dashed ring, a gradient
/// progress ring, and shimmering caption text.
///
/// The continuously-looping layers (pulse glow, rotating ring, shimmer text)
/// are each isolated in a [RepaintBoundary] so their per-frame repaints stay
/// local and don't invalidate the surrounding card.
class UploadingStateView extends StatefulWidget {
  final double progress;
  const UploadingStateView({super.key, required this.progress});

  @override
  State<UploadingStateView> createState() => _UploadingStateViewState();
}

class _UploadingStateViewState extends State<UploadingStateView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow (continuous pulse, isolated).
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 130 + (_pulseController.value * 20),
                      height: 130 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.12 - (_pulseController.value * 0.04)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 10 + (_pulseController.value * 15),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Rotating dashed ring (continuous rotation, isolated).
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * math.pi * 2,
                      child: CustomPaint(
                        size: const Size(130, 130),
                        painter: _DashedRingPainter(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          strokeWidth: 1.5,
                          dashLength: 6,
                          dashSpace: 8,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Core progress ring
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _RefinedProgressPainter(
                        progress: value,
                        gradientColors: [AppColors.cyan, AppColors.primary, const Color(0xFF6366F1)],
                      ),
                    );
                  },
                ),
              ),

              // Inner content
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.progress),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).toInt()}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Text(
                            '%',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const RepaintBoundary(child: _RefinedUploadingText()),
      ],
    );
  }
}

class _RefinedUploadingText extends StatefulWidget {
  const _RefinedUploadingText();

  @override
  State<_RefinedUploadingText> createState() => _RefinedUploadingTextState();
}

class _RefinedUploadingTextState extends State<_RefinedUploadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                AppColors.ink,
                AppColors.ink,
                AppColors.primary,
                AppColors.cyan,
                AppColors.ink,
                AppColors.ink,
              ],
              stops: [
                0.0,
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value - 0.1,
                _shimmerAnimation.value + 0.1,
                _shimmerAnimation.value + 0.3,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'Uploading Specimen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white, // Masked by shader
            ),
          ),
        );
      },
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + dashSpace)).floor();
    final actualDashSpace = (circumference - (dashCount * dashLength)) / dashCount;
    final sweepAngle = dashLength / radius;
    final spaceAngle = actualDashSpace / radius;

    double currentAngle = 0;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle + spaceAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}

class _RefinedProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _RefinedProgressPainter({
    required this.progress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    // Subtle track
    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepGradient = SweepGradient(
      colors: gradientColors,
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 2 * progress;

    // Draw inner glow
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, glowPaint);
    // Draw solid progress
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, progressPaint);

    // Glowing dot at the end for an illuminated high-tech look
    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = gradientColors.last.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(dotCenter, strokeWidth, dotGlowPaint);
    canvas.drawCircle(dotCenter, strokeWidth - 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RefinedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
