import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Fluid oceanic backdrop with slowly drifting aurora blobs.
///
/// Performance: the static base gradient and noise overlay are built once;
/// only the drifting blobs rebuild each frame, isolated behind a
/// [RepaintBoundary] so the animation never repaints the gradient, the noise,
/// or anything else on the page.
class OceanicBackground extends StatelessWidget {
  const OceanicBackground({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Static base gradient (non-positioned: sizes the stack, built once).
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF050E25), const Color(0xFF040D21), const Color(0xFF020712)]
                  : [Colors.white, const Color(0xFFFBFBFA), AppColors.page],
            ),
          ),
        ),
        // Moving aurora blobs — the only animated layer, isolated so its
        // per-frame repaints stay local.
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final v = controller.value * 2 * math.pi;
                return Stack(
                  children: [
                    Positioned(
                      top: math.sin(v) * 50 - 100,
                      left: math.cos(v) * 50 - 100,
                      child: _BlurBlob(
                        color: isDark
                            ? const Color(0xFF0EA5FF).withValues(alpha: 0.05)
                            : AppColors.primary.withValues(alpha: 0.06),
                        size: 400,
                      ),
                    ),
                    Positioned(
                      bottom: math.cos(v * 1.5) * 60 - 50,
                      right: math.sin(v * 1.2) * 60 - 50,
                      child: _BlurBlob(
                        color: isDark
                            ? const Color(0xFF0057E6).withValues(alpha: 0.04)
                            : AppColors.cyan.withValues(alpha: 0.05),
                        size: 350,
                      ),
                    ),
                    Positioned(
                      top: math.cos(v * 0.8) * 40 + 200,
                      right: math.sin(v * 0.9) * 40 - 100,
                      child: _BlurBlob(
                        color: isDark
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.03)
                            : AppColors.violet.withValues(alpha: 0.04),
                        size: 300,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Noise overlay for texture (static, built once).
        Positioned.fill(
          child: Opacity(
            opacity: 0.02,
            child: Image.asset(
              'assets/images/noise.png',
              repeat: ImageRepeat.repeat,
              cacheWidth: 400,
              errorBuilder: (c, e, s) => Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Performance: replaced BackdropFilter(sigma=80) with a cheap RadialGradient.
    // BackdropFilter is the most expensive widget in Flutter — using 3 of them
    // with sigma=80 and repositioning every frame was the #1 perf killer.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
