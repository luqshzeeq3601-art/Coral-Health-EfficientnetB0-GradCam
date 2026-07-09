import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../models/assessment_models.dart';

/// Visual styling (colors, icon, image) derived from a prediction's status.
/// Shared by the result panels so the severity → style mapping lives in one
/// place.
class StatusStyle {
  const StatusStyle({
    required this.color,
    required this.soft,
    required this.softBorder,
    required this.icon,
    required this.imageAsset,
  });

  final Color color;
  final Color soft;
  final Color softBorder;
  final IconData icon;
  final String imageAsset;
}

/// Maps a [PredictionResult]'s severity / prediction to its [StatusStyle].
StatusStyle resolveStatus(PredictionResult result) {
  final severity = result.status.severity.toLowerCase();
  final prediction = result.prediction.toLowerCase();

  if (severity == 'critical' || severity == 'high' || prediction == 'dead') {
    return const StatusStyle(
      color: AppColors.dead,
      soft: AppColors.deadSoft,
      softBorder: Color(0xFFF7C8C8),
      icon: Icons.warning_amber_rounded,
      imageAsset: 'assets/images/dead.png',
    );
  }

  if (severity == 'medium' ||
      severity == 'warning' ||
      prediction == 'bleached') {
    return const StatusStyle(
      color: AppColors.bleached,
      soft: AppColors.bleachedSoft,
      softBorder: Color(0xFFF4D9BD),
      icon: Icons.wb_sunny_outlined,
      imageAsset: 'assets/images/bleach.png',
    );
  }

  return const StatusStyle(
    color: AppColors.green,
    soft: AppColors.healthySoft,
    softBorder: Color(0xFFC9F1DE),
    icon: Icons.check_circle_outline_rounded,
    imageAsset: 'assets/images/health.png',
  );
}
