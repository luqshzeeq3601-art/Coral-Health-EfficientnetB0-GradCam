import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ModernScrollIndicator extends StatelessWidget {
  const ModernScrollIndicator({
    super.key,
    required this.controller,
    this.trackWidth = 50.0,
    this.pillWidth = 16.0,
  });

  final ScrollController controller;
  final double trackWidth;
  final double pillWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (!controller.hasClients) return const SizedBox.shrink();
        if (!controller.position.hasContentDimensions) {
          return const SizedBox.shrink();
        }

        final maxScroll = controller.position.maxScrollExtent;
        if (maxScroll <= 0) return const SizedBox.shrink();

        final offset = controller.offset.clamp(0.0, maxScroll);
        final progress = offset / maxScroll;
        final leftOffset = progress * (trackWidth - pillWidth);

        return Center(
          child: Container(
            width: trackWidth,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: leftOffset,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: pillWidth,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
