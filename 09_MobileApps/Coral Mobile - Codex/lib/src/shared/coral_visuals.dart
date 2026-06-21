import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class CoralThumbnail extends StatelessWidget {
  const CoralThumbnail({
    super.key,
    this.size = 96,
    this.variant = CoralVariant.healthy,
    this.showNetwork = false,
  });

  final double size;
  final CoralVariant variant;
  final bool showNetwork;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ModernCoralPainter(variant: variant),
          ),
          if (showNetwork)
            const Positioned.fill(
              child: CustomPaint(
                painter: _CoralNetworkPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class ConfidenceGauge extends StatelessWidget {
  const ConfidenceGauge({
    required this.value,
    required this.label,
    super.key,
    this.size = 150,
    this.color = AppColors.green,
  });

  final double value;
  final String label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _GaugePainter(value: value, color: color),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(size * 0.15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.analytics_rounded,
              color: color,
              size: size * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}

class HeatMapPreview extends StatelessWidget {
  const HeatMapPreview({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: _ModernCoralPainter(variant: CoralVariant.healthy),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: const CustomPaint(painter: _HeatMapOverlayPainter()),
          ),
        ],
      ),
    );
  }
}

class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (value / 100.0).clamp(0.0, 1.0),
                color: color,
                backgroundColor: const Color(0xFFE9F0F9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              '${value.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class CoralSparkline extends StatelessWidget {
  const CoralSparkline({
    required this.color,
    super.key,
    this.height = 44,
  });

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(painter: _SparklinePainter(color)),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    super.key,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

enum CoralVariant { healthy, bleached, dead, purple }

class _CoralNetworkPainter extends CustomPainter {
  const _CoralNetworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final networkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    final points = List.generate(12, (i) {
      final x = size.width * ((i * 37) % 100) / 100;
      final y = size.height * (0.08 + ((i * 53) % 80) / 100);
      return Offset(x, y);
    });
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], networkPaint);
      canvas.drawCircle(points[i], 2, Paint()..color = Colors.white.withValues(alpha: 0.65));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Background track with elegant thinness and soft color
    final track = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 6, track);

    // Glowing drop shadow for the active arc
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    // Calculate the sweep angle
    final sweepAngle = math.pi * 2 * (value / 100.0).clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      shadowPaint,
    );

    // Active arc with premium thickness
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      active,
    );
    
    // Elegant inner ring
    final innerTrack = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 20, innerTrack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeatMapOverlayPainter extends CustomPainter {
  const _HeatMapOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final heat = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.1, 0.25),
        radius: 0.7,
        colors: [
          Colors.red.withValues(alpha: 0.75),
          Colors.orange.withValues(alpha: 0.62),
          Colors.yellow.withValues(alpha: 0.45),
          Colors.cyan.withValues(alpha: 0.26),
          Colors.transparent,
        ],
        stops: const [0, .22, .42, .66, 1],
      ).createShader(rect);
    canvas.drawRect(rect, heat);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * .82)
      ..cubicTo(size.width * .22, size.height * .92, size.width * .38, size.height * .42, size.width * .56, size.height * .5)
      ..cubicTo(size.width * .72, size.height * .58, size.width * .78, size.height * .2, size.width, size.height * .08);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModernCoralPainter extends CustomPainter {
  const _ModernCoralPainter({required this.variant});

  final CoralVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.18));
    
    // Smooth minimalist backgrounds
    final bgColor = switch (variant) {
      CoralVariant.healthy => const Color(0xFFF0FDF4),
      CoralVariant.purple => const Color(0xFFFAF5FF),
      CoralVariant.bleached => const Color(0xFFF8FAFC),
      CoralVariant.dead => const Color(0xFFFEF2F2),
    };
    
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // Primary and secondary abstract tones
    final primaryColor = switch (variant) {
      CoralVariant.healthy => const Color(0xFF34D399),
      CoralVariant.purple => const Color(0xFFC084FC),
      CoralVariant.bleached => const Color(0xFFCBD5E1),
      CoralVariant.dead => const Color(0xFFF87171),
    };

    final secondaryColor = switch (variant) {
      CoralVariant.healthy => const Color(0xFF059669),
      CoralVariant.purple => const Color(0xFF7E22CE),
      CoralVariant.bleached => const Color(0xFF64748B),
      CoralVariant.dead => const Color(0xFFB91C1C),
    };

    canvas.save();
    canvas.clipRRect(rrect);

    // Draw modern, flowing vector paths
    final path1 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.4, size.width * 0.6, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.8, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.65, size.width * 0.5, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.95, size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final centerPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..cubicTo(size.width * 0.65, size.height * 0.3, size.width * 0.7, size.height * 0.6, size.width * 0.8, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..cubicTo(size.width * 0.3, size.height * 0.6, size.width * 0.35, size.height * 0.3, size.width * 0.5, size.height * 0.3)
      ..close();

    // Fill shapes with sleek gradients
    canvas.drawPath(
      centerPath, 
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [primaryColor.withValues(alpha: 0.9), secondaryColor],
      ).createShader(rect)
    );

    canvas.drawPath(
      path1, 
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [primaryColor.withValues(alpha: 0.6), secondaryColor.withValues(alpha: 0.8)],
      ).createShader(rect)
    );

    canvas.drawPath(
      path2, 
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomLeft, end: Alignment.topRight,
        colors: [secondaryColor, primaryColor.withValues(alpha: 0.4)],
      ).createShader(rect)
    );

    // Vector tech dots
    final dotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), size.width * 0.03, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.35), size.width * 0.02, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), size.width * 0.025, dotPaint);
    
    // Connect dots with thin lines
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.2), Offset(size.width * 0.7, size.height * 0.35), linePaint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.2), Offset(size.width * 0.3, size.height * 0.4), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ModernCoralPainter oldDelegate) => oldDelegate.variant != variant;
}
