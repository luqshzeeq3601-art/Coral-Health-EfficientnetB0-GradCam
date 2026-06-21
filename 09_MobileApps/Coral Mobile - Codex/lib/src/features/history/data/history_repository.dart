import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database_helper.dart';
import '../../assessment/models/assessment_models.dart';
import '../models/history_record.dart';

class HistoryRepository {
  static const String _tableName = 'scan_history';

  Future<List<HistoryRecord>> getAllRecords() async {
    final records = await DatabaseHelper.instance.queryAll(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return records.map((map) => HistoryRecord.fromMap(map)).toList();
  }

  Future<List<HistoryRecord>> getRecentRecords({int limit = 4}) async {
    final records = await DatabaseHelper.instance.queryLimit(
      _tableName,
      limit: limit,
      orderBy: 'created_at DESC',
    );
    return records.map((map) => HistoryRecord.fromMap(map)).toList();
  }

  Future<HistoryRecord> saveAssessment(PredictionResult result) async {
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy').format(now);
    final recordId = 'CH-${DateFormat('yyyy-MMdd-HHmmss').format(now)}';

    String? savedImagePath;
    String? gradcamOverlayPath;
    String? gradcamHeatmapPath;

    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(appDir.path, 'scans'));
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    // Save Original Image
    if (result.selectedImage?.filePath != null) {
      final originalFile = File(result.selectedImage!.filePath!);
      if (await originalFile.exists()) {
        final ext = p.extension(originalFile.path);
        final newPath = p.join(scansDir.path, '${recordId}_original$ext');
        await originalFile.copy(newPath);
        savedImagePath = newPath;
      }
    }

    // Save Grad-CAM Heatmap
    if (result.gradcamHeatmapBase64 != null &&
        result.gradcamHeatmapBase64!.isNotEmpty) {
      final bytes = base64Decode(result.gradcamHeatmapBase64!);
      final file = File(p.join(scansDir.path, '${recordId}_heatmap.png'));
      await file.writeAsBytes(bytes);
      gradcamHeatmapPath = file.path;
    }

    // Save Grad-CAM Overlay
    if (result.gradcamOverlayBase64 != null &&
        result.gradcamOverlayBase64!.isNotEmpty) {
      final bytes = base64Decode(result.gradcamOverlayBase64!);
      final file = File(p.join(scansDir.path, '${recordId}_overlay.png'));
      await file.writeAsBytes(bytes);
      gradcamOverlayPath = file.path;
    }

    // Determine status description for notes if notes are empty
    String notes = result.notes.isNotEmpty
        ? result.notes.join(' ')
        : result.status.description.isNotEmpty
            ? result.status.description
            : 'No detailed notes available.';

    final confidence = _normalizePercent(result.confidence);
    final probabilities = _normalizeProbabilityMap(result.probabilities);

    final record = HistoryRecord(
      id: recordId,
      label: result.prediction,
      confidence: confidence,
      date: dateStr,
      model: result.modelUsed,
      imageQuality:
          'Standard resolution - AI assessed', // Add a field to selectedImage in future if needed
      probabilities: probabilities,
      notes: notes,
      imagePath: savedImagePath,
      gradcamOverlayPath: gradcamOverlayPath,
      gradcamHeatmapPath: gradcamHeatmapPath,
      createdAt: now,
    );

    final id = await DatabaseHelper.instance.insert(_tableName, record.toMap());

    // Return record with assigned DB ID
    return HistoryRecord(
      dbId: id,
      id: record.id,
      label: record.label,
      confidence: record.confidence,
      date: record.date,
      model: record.model,
      imageQuality: record.imageQuality,
      probabilities: record.probabilities,
      notes: record.notes,
      imagePath: record.imagePath,
      gradcamOverlayPath: record.gradcamOverlayPath,
      gradcamHeatmapPath: record.gradcamHeatmapPath,
      createdAt: record.createdAt,
    );
  }

  Future<void> deleteRecord(HistoryRecord record) async {
    if (record.dbId != null) {
      await DatabaseHelper.instance.delete(_tableName, record.dbId!);

      // Delete associated files
      final filesToDelete = [
        record.imagePath,
        record.gradcamOverlayPath,
        record.gradcamHeatmapPath,
      ];

      for (final path in filesToDelete) {
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    }
  }
}

double _normalizePercent(double value) {
  if (!value.isFinite) return 0;
  if (value <= 1) return value * 100;
  if (value > 100) return value / 100;
  return value;
}

Map<String, double> _normalizeProbabilityMap(Map<String, double> source) {
  return source.map((key, value) => MapEntry(key, _normalizePercent(value)));
}
