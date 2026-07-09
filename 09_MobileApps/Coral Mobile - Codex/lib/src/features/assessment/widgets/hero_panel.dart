import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../models/assessment_models.dart';
import 'status_style.dart';

/// Diagnosis hero card at the top of the result page: status icon, the
/// predicted class, and a bulleted summary of the finding.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.result});

  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = resolveStatus(result);
    final isHealthy = result.prediction.toLowerCase() == 'healthy';
    final imageLabel = isHealthy
        ? 'Healthy coral detected with stable coloration and structure.'
        : result.status.description;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A33).withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0xFF0A4BB8).withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Center(
                  child: Image.asset(
                    status.imageAsset,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIAGNOSIS',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.prediction} Coral',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border(
                left: BorderSide(color: status.color, width: 4),
                top: BorderSide(color: status.color.withValues(alpha: 0.15), width: 1),
                right: BorderSide(color: status.color.withValues(alpha: 0.15), width: 1),
                bottom: BorderSide(color: status.color.withValues(alpha: 0.15), width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isHealthy) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(status.icon, color: status.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (imageLabel.isNotEmpty ? imageLabel : 'Coral assessment completed.')
                        .split('. ')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .map((sentence) {
                      final cleanSentence = sentence.replaceAll('⚠️ ', '').trim();
                      if (cleanSentence.isEmpty) return const SizedBox.shrink();
                      final finalSentence = cleanSentence.endsWith('.') ? cleanSentence : '$cleanSentence.';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0, right: 8.0),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: status.color.withValues(alpha: 0.7),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                finalSentence,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
