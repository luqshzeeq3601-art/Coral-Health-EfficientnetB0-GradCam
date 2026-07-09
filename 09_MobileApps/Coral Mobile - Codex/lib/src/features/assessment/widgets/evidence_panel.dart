import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../models/assessment_models.dart';

/// "Visual Evidence" card on the result page: toggles between the original
/// image and the Grad-CAM overlay, with a heat-scale legend.
class EvidencePanel extends StatefulWidget {
  const EvidencePanel({required this.result, super.key});

  final PredictionResult result;

  @override
  State<EvidencePanel> createState() => _EvidencePanelState();
}

class _EvidencePanelState extends State<EvidencePanel> {
  bool _showHeatmap = true;
  // Performance: cache decoded base64 images to avoid re-decoding on every
  // setState toggle (base64Decode of large Grad-CAM images = 50-200ms stall).
  Uint8List? _cachedOverlay;
  Uint8List? _cachedOriginal;

  Widget _buildDisplayImage() {
    final result = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? imageWidget;

    if (_showHeatmap) {
      if (result.gradcamOverlayBase64 != null) {
        _cachedOverlay ??= base64Decode(result.gradcamOverlayBase64!);
        imageWidget = Image.memory(
          _cachedOverlay!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      }
    } else {
      if (result.originalImageBase64 != null) {
        _cachedOriginal ??= base64Decode(result.originalImageBase64!);
        imageWidget = Image.memory(
          _cachedOriginal!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } else if (result.selectedImage != null) {
        final selected = result.selectedImage!;
        if (selected.isAsset && selected.assetPath != null) {
          imageWidget = Image.asset(
            selected.assetPath!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        } else if (selected.filePath != null) {
          imageWidget = Image.file(
            File(selected.filePath!),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: imageWidget ??
          Container(
            height: 220,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: const Center(
              child: Icon(Icons.image_not_supported_rounded, color: AppColors.muted),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (!result.hasGradcam) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VISUAL EVIDENCE',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      label: 'Original',
                      isSelected: !_showHeatmap,
                      onTap: () => setState(() => _showHeatmap = false),
                    ),
                    _buildTabButton(
                      label: 'Grad-CAM',
                      isSelected: _showHeatmap,
                      onTap: () => setState(() => _showHeatmap = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDisplayImage(),
          if (_showHeatmap) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'LOW',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.red,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HIGH',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppColors.cyan : AppColors.primary)
                : (isDark ? const Color(0xFF94A3B8) : AppColors.muted),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
