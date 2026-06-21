import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../shared/coral_visuals.dart';

class HistoryRecord {
  const HistoryRecord({
    this.dbId,
    required this.id,
    required this.label,
    required this.confidence,
    required this.date,
    required this.model,
    required this.imageQuality,
    required this.probabilities,
    required this.notes,
    this.imagePath,
    this.gradcamOverlayPath,
    this.gradcamHeatmapPath,
    this.createdAt,
  });

  final int? dbId;
  final String id;
  final String label;
  final double confidence;
  final String date;
  final String model;
  final String imageQuality;
  final Map<String, double> probabilities;
  final String notes;
  final String? imagePath;
  final String? gradcamOverlayPath;
  final String? gradcamHeatmapPath;
  final DateTime? createdAt;

  CoralVariant get variant {
    return switch (label) {
      'Healthy' => CoralVariant.healthy,
      'Bleached' => CoralVariant.bleached,
      'Dead' => CoralVariant.dead,
      _ => CoralVariant.healthy,
    };
  }

  Color get color {
    return switch (label) {
      'Healthy' => AppColors.healthy,
      'Bleached' => AppColors.bleached,
      'Dead' => AppColors.dead,
      _ => AppColors.primary,
    };
  }

  double get confidencePercent => _normalizePercent(confidence);

  String get score => '${confidencePercent.toStringAsFixed(1)}%';

  Map<String, double> get normalizedProbabilities {
    return probabilities
        .map((key, value) => MapEntry(key, _normalizePercent(value)));
  }

  List<MapEntry<String, double>> get rankedProbabilities {
    final entries = normalizedProbabilities.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String get confidenceSummary {
    final percent = confidencePercent.clamp(0.0, 100.0);
    if (percent >= 90) return 'Strong signal';
    if (percent >= 70) return 'Solid signal';
    if (percent >= 50) return 'Moderate signal';
    return 'Needs review';
  }

  Map<String, dynamic> toMap() {
    return {
      if (dbId != null) 'id': dbId,
      'record_id': id,
      'label': label,
      'confidence': confidence,
      'variant': variant.name,
      'date': date,
      'model': model,
      'image_quality': imageQuality,
      'probabilities_json': jsonEncode(probabilities),
      'notes': notes,
      'image_path': imagePath,
      'gradcam_overlay_path': gradcamOverlayPath,
      'gradcam_heatmap_path': gradcamHeatmapPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory HistoryRecord.fromMap(Map<String, dynamic> map) {
    Map<String, double> probs = {};
    if (map['probabilities_json'] != null) {
      final decoded = jsonDecode(map['probabilities_json']);
      if (decoded is Map) {
        probs = decoded
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
      }
    }

    return HistoryRecord(
      dbId: map['id'] as int?,
      id: map['record_id'] as String,
      label: map['label'] as String,
      confidence: map['confidence'] as double,
      date: map['date'] as String,
      model: map['model'] as String,
      imageQuality: map['image_quality'] as String,
      probabilities: probs,
      notes: map['notes'] as String,
      imagePath: map['image_path'] as String?,
      gradcamOverlayPath: map['gradcam_overlay_path'] as String?,
      gradcamHeatmapPath: map['gradcam_heatmap_path'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }
}

double _normalizePercent(double value) {
  if (!value.isFinite) return 0;
  if (value <= 1) return value * 100;
  if (value > 100) return value / 100;
  return value;
}
