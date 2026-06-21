import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/glass_card.dart';
import '../../assessment/models/assessment_models.dart';
import '../data/history_repository.dart';
import '../models/history_record.dart';

class HistoryDetailPage extends StatefulWidget {
  const HistoryDetailPage({required this.record, super.key});

  final HistoryRecord record;

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<Uint8List?> _captureScreenshot() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF061124),
                    const Color(0xFF040D1D),
                    const Color(0xFF020712),
                  ]
                : [Colors.white, const Color(0xFFFBFBFA), AppColors.page],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF061124),
                            const Color(0xFF040D1D),
                            const Color(0xFF020712),
                          ]
                        : [Colors.white, const Color(0xFFFBFBFA), AppColors.page],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailHeader(
                      record: widget.record,
                      onCaptureScreenshot: _captureScreenshot,
                    ),
                    const SizedBox(height: 18),
                    _HeroCard(record: widget.record),
                    const SizedBox(height: 16),
                    _ProbabilityCard(record: widget.record),
                    const SizedBox(height: 16),
                    _AttentionCard(record: widget.record),
                    const SizedBox(height: 16),
                    _MetadataCard(record: widget.record),
                    const SizedBox(height: 16),
                    _ManagementActions(record: widget.record),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CoralBottomNav(activeTab: MainTab.history),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.record,
    required this.onCaptureScreenshot,
  });

  final HistoryRecord record;
  final Future<Uint8List?> Function() onCaptureScreenshot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            navigator.pushReplacementNamed(AppRoutes.history);
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Assessment Report',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${record.id} · ${record.date}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9FB0CF) : AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.ios_share_rounded,
          onPressed: () => _showShareBottomSheet(context, record),
        ),
      ],
    );
  }

  void _showShareBottomSheet(BuildContext context, HistoryRecord record) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1830) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Share Assessment',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.image_rounded, color: AppColors.primary),
                ),
                title: const Text(
                  'Share Screenshot',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle:
                    const Text('Export report as an image.'),
                onTap: () {
                  Navigator.pop(context);
                  _shareImage(record);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Share PDF',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle:
                    const Text('Export report as a PDF document.'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePdf(record);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareImage(HistoryRecord record) async {
    final bytes = await onCaptureScreenshot();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/assessment_report_${record.id}.png');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        text: 'Coral Scan Result: ${record.label} (${record.score})',
        files: [XFile(file.path)],
      ),
    );
  }

  Future<void> _sharePdf(HistoryRecord record) async {
    final bytes = await onCaptureScreenshot();
    if (bytes == null) return;

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(bytes);

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(pdfImage));
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/assessment_report_${record.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        text: 'Coral Assessment PDF Report',
        files: [XFile(file.path)],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _softColor(context, record),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark 
              ? const Color(0xFF1E2F4D).withValues(alpha: 0.4) 
              : AppColors.line.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: record.color.withValues(alpha: isDark ? 0.03 : 0.02),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      '${record.label} Coral',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Archived assessment summary',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFB7C4DD) : AppColors.muted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: record.imagePath != null
                      ? Image.file(
                          File(record.imagePath!),
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                        )
                      : CoralThumbnail(
                          size: 104,
                          variant: record.variant,
                          showNetwork: true,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF040D21).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2F4D).withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
            child: Row(
              children: [
                ConfidenceGauge(
                  value: record.confidencePercent,
                  label: 'Confidence',
                  color: record.color,
                  size: 100,
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MetricTile(
                        icon: Icons.memory_rounded,
                        label: 'Model type',
                        value: record.model,
                      ),
                      const SizedBox(height: 12),
                      _MetricTile(
                        icon: Icons.calendar_month_rounded,
                        label: 'Date scanned',
                        value: record.date,
                      ),
                    ],
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

class _ProbabilityCard extends StatelessWidget {
  const _ProbabilityCard({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final ranked = record.rankedProbabilities;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Probability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final entry in ranked)
            ProbabilityBar(
              label: entry.key,
              value: entry.value,
              color: _labelColor(entry.key),
            ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grad-CAM Attention',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          if (record.gradcamHeatmapPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(record.gradcamHeatmapPath!),
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (record.gradcamOverlayPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(record.gradcamOverlayPath!),
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: const HeatMapPreview(height: 170),
            ),
          const SizedBox(height: 12),
          Text(
            record.notes,
            style: TextStyle(
              color: isDark ? const Color(0xFFB7C4DD) : AppColors.muted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _MetadataTile(
            icon: Icons.tag_rounded,
            label: 'Record ID',
            value: record.id,
          ),

        ],
      ),
    );
  }
}

class _ManagementActions extends StatelessWidget {
  const _ManagementActions({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
            onPressed: () {
              final contextResult = PredictionResult(
                prediction: record.label,
                confidence: record.confidencePercent,
                probabilities: record.probabilities,
                individualModels: const [],
                status: const PredictionStatus(
                  severity: 'Archived',
                  description: 'Historical scan data.',
                  recommendation: 'No immediate action.',
                ),
                uncertainty: false,
                notes: [record.notes],
                modelUsed: record.model,
                isOffline: true,
                gradcamHeatmapBase64: record.gradcamHeatmapPath,
                gradcamOverlayBase64: record.gradcamOverlayPath,
                originalImageBase64: record.imagePath,
              );
              Navigator.of(context).pushNamed(
                AppRoutes.chatbot,
                arguments: contextResult,
              );
            },
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Ask Qwen AI'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 54,
          height: 54,
          child: OutlinedButton(
            onPressed: () => _showDeleteDialog(context, record),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dead,
              side: BorderSide(color: AppColors.dead.withValues(alpha: 0.32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF040D21).withValues(alpha: 0.6)
            : AppColors.primarySoft.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF1E2F4D)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0E1A33)
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF0EA5FF) : AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _MetadataTile extends StatelessWidget {
  const _MetadataTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1A33) : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border:
                  isDark ? Border.all(color: const Color(0xFF1E2F4D)) : null,
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF0EA5FF) : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 46,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1A33) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x1A000000) : const Color(0x142362A7),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon,
              color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

void _showDeleteDialog(BuildContext context, HistoryRecord record) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete log entry?'),
        content: Text('This will remove ${record.id} from local history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await HistoryRepository().deleteRecord(record);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${record.id} deleted from history')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.dead),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Color _softColor(BuildContext context, HistoryRecord record) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return switch (record.label) {
      'Healthy' => const Color(0xFF0C2B1C),
      'Bleached' => const Color(0xFF382B14),
      'Dead' => const Color(0xFF3B161B),
      _ => const Color(0xFF0E1A33),
    };
  }
  return switch (record.label) {
    'Healthy' => AppColors.healthySoft,
    'Bleached' => AppColors.bleachedSoft,
    'Dead' => AppColors.deadSoft,
    _ => Colors.white,
  };
}

Color _labelColor(String label) {
  return switch (label) {
    'Healthy' => AppColors.healthy,
    'Bleached' => AppColors.bleached,
    'Dead' => AppColors.dead,
    _ => AppColors.primary,
  };
}

IconData _statusIcon(String label) {
  return switch (label) {
    'Healthy' => Icons.eco_outlined,
    'Bleached' => Icons.wb_sunny_outlined,
    'Dead' => Icons.warning_amber_rounded,
    _ => Icons.analytics_outlined,
  };
}
