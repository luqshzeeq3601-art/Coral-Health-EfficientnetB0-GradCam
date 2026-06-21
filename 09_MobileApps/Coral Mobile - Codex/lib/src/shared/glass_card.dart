import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBgColor = backgroundColor == Colors.white
        ? (isDark ? const Color(0xFF0E1A33) : Colors.white)
        : backgroundColor;

    final resolvedBorder = isDark ? const Color(0xFF1E2F4D) : AppColors.line;

    final resolvedShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.25)
        : const Color(0x1A2362A7);

    return Container(
      decoration: BoxDecoration(
        color: resolvedBgColor.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: resolvedBorder),
        boxShadow: [
          BoxShadow(
            color: resolvedShadowColor,
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
