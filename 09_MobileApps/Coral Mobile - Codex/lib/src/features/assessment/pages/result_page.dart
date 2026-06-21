import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/assessment_stepper.dart';
import '../../../shared/bottom_nav.dart';
import '../../history/data/history_repository.dart';
import '../models/assessment_models.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({
    super.key,
    this.result,
  });

  final PredictionResult? result;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    if (widget.result != null) {
      HistoryRepository().saveAssessment(widget.result!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result == null) {
      return const _MissingResultPage();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [
            const Color(0xFF050E25),
            const Color(0xFF040D21),
            const Color(0xFF020712),
          ]
        : [
            const Color(0xFFFFFFFF),
            const Color(0xFFF8FBFF),
            AppColors.page,
          ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBody: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              if (!isDark) ...[
                const Positioned(
                  top: -42,
                  right: -30,
                  child: _BgOrb(
                    size: 180,
                    color: Color(0x140057E6),
                  ),
                ),
                const Positioned(
                  top: 180,
                  left: -54,
                  child: _BgOrb(
                    size: 160,
                    color: Color(0x1116B979),
                  ),
                ),
                const Positioned(
                  bottom: 140,
                  right: -30,
                  child: _BgOrb(
                    size: 140,
                    color: Color(0x10E9A106),
                  ),
                ),
              ],
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 220),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppTopBar(
                        showBackButton: false,
                      ),
                      const SizedBox(height: 12),
                      _Reveal(
                        animation: _controller,
                        interval:
                            const Interval(0, .3, curve: Curves.easeOutCubic),
                        child: const _StepperRail(
                          child: AssessmentStepper(
                              activeStep: AssessmentStep.result),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Reveal(
                        animation: _controller,
                        interval: const Interval(.06, .34,
                            curve: Curves.easeOutCubic),
                        child: const _ReportHeader(),
                      ),
                      const SizedBox(height: 16),
                      _Reveal(
                        animation: _controller,
                        interval:
                            const Interval(.1, .52, curve: Curves.easeOutCubic),
                        child: _HeroPanel(result: result),
                      ),
                      const SizedBox(height: 14),
                      _Reveal(
                        animation: _controller,
                        interval: const Interval(.18, .64,
                            curve: Curves.easeOutCubic),
                        child: _ConfidencePanel(result: result),
                      ),
                      const SizedBox(height: 14),
                      _Reveal(
                        animation: _controller,
                        interval: const Interval(.28, .76,
                            curve: Curves.easeOutCubic),
                        child: _EvidencePanel(result: result),
                      ),
                      const SizedBox(height: 14),
                      _Reveal(
                        animation: _controller,
                        interval: const Interval(.38, .86,
                            curve: Curves.easeOutCubic),
                        child: _InsightPanel(result: result),
                      ),
                      const SizedBox(height: 18),
                      _Reveal(
                        animation: _controller,
                        interval:
                            const Interval(.5, 1, curve: Curves.easeOutCubic),
                        child: _ResultActions(
                          onAsk: () => Navigator.of(context).pushNamed(
                            AppRoutes.chatbot,
                            arguments: widget.result,
                          ),
                          onAgain: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.upload),
                          onDone: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.home),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CoralBottomNav(activeTab: MainTab.assess),
      ),
    );
  }
}

class _MissingResultPage extends StatelessWidget {
  const _MissingResultPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF050E25), const Color(0xFF020712)]
                : [const Color(0xFFFFFFFF), AppColors.page],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopBar(showBackButton: false),
                const Spacer(),
                const Icon(
                  Icons.assignment_late_outlined,
                  color: AppColors.primary,
                  size: 56,
                ),
                const SizedBox(height: 18),
                Text(
                  'No result available',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Run an assessment first so the backend prediction can populate this report.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context)
                       .pushReplacementNamed(AppRoutes.upload),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Upload Coral Image'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Performance fix: _Reveal was creating new CurvedAnimation objects in build(),
// causing memory leaks. Now uses a StatefulWidget that caches them.
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.animation,
    required this.interval,
    required this.child,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  late final CurvedAnimation _curved;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _curved = CurvedAnimation(parent: widget.animation, curve: widget.interval);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_curved);
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}

class _BgOrb extends StatelessWidget {
  const _BgOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _StepperRail extends StatelessWidget {
  const _StepperRail({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: child,
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASSESSMENT REPORT',
          style: TextStyle(
            color: isDark ? AppColors.cyan : AppColors.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Diagnostic Results',
          style: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
            fontWeight: FontWeight.w900,
            fontSize: 34,
            letterSpacing: -1.2,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A concise, confidence-led summary of the coral scan.',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.result});

  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _resolveStatus(result);
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: status.color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              imageLabel.isNotEmpty ? imageLabel : 'Coral assessment completed.',
              style: TextStyle(
                color: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidencePanel extends StatelessWidget {
  const _ConfidencePanel({required this.result});

  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _resolveStatus(result);
    final confidence = result.confidence.clamp(0.0, 100.0);

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
          Text(
            'DIAGNOSTIC METRICS',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Confidence Score',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    confidence.toStringAsFixed(1),
                    style: TextStyle(
                      color: status.color,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '%',
                    style: TextStyle(
                      color: status.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: confidence / 100,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8EEF8),
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI MODEL USED',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.modelUsed.split('(').first.trim(),
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGNAL STATUS',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.status.severity.isNotEmpty
                          ? result.status.severity
                          : 'Standard',
                      style: TextStyle(
                        color: status.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidencePanel extends StatefulWidget {
  const _EvidencePanel({required this.result, super.key});

  final PredictionResult result;

  @override
  State<_EvidencePanel> createState() => _EvidencePanelState();
}

class _EvidencePanelState extends State<_EvidencePanel> {
  bool _showHeatmap = true;
  // Performance: cache decoded base64 images to avoid re-decoding on every
  // setState toggle (base64Decode of large Grad-CAM images = 50-200ms stall).
  Uint8List? _cachedOverlay;
  Uint8List? _cachedOriginal;

  Uint8List? _getDisplayImage() {
    final result = widget.result;
    if (_showHeatmap) {
      if (result.gradcamOverlayBase64 != null && _cachedOverlay == null) {
        _cachedOverlay = base64Decode(result.gradcamOverlayBase64!);
      }
      return _cachedOverlay;
    } else {
      if (result.originalImageBase64 != null && _cachedOriginal == null) {
        _cachedOriginal = base64Decode(result.originalImageBase64!);
      }
      return _cachedOriginal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (!result.hasGradcam) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Uint8List? displayImageBytes = _getDisplayImage();

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
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: displayImageBytes != null
                  ? Image.memory(
                      displayImageBytes,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // Performance: prevent re-decoding when bytes haven't changed
                      gaplessPlayback: true,
                    )
                  : Container(
                      height: 220,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: AppColors.muted),
                      ),
                    ),
            ),
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

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.result});

  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowConfidence = result.confidence < 75.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1830).withValues(alpha: 0.8) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2F4D) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                'ACTION PLAN & NOTES',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(Icons.playlist_add_check_rounded,
                  color: isDark ? AppColors.cyan : AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          if (result.status.recommendation.isNotEmpty) ...[
            _InsightRow(
              title: 'Recommendation',
              text: result.status.recommendation,
              icon: Icons.lightbulb_outline_rounded,
              iconColor: AppColors.cyan,
            ),
            const SizedBox(height: 16),
          ],
          if (isLowConfidence) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFCA5A5),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Uncertain Inference',
                          style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence is below 75%. Treat this diagnostic result as exploratory and perform a manual verification.',
                          style: TextStyle(
                            color: const Color(0xFFFCA5A5).withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.title,
    required this.text,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String text;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.ink,
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.onAsk,
    required this.onAgain,
    required this.onDone,
  });

  final VoidCallback onAsk;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        FilledButton.icon(
          onPressed: onAsk,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Ask'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: isDark ? const Color(0xFF0C2540) : AppColors.primarySoft,
            foregroundColor: isDark ? AppColors.cyan : AppColors.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rescan'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
                    width: 1.5,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
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

_StatusStyle _resolveStatus(PredictionResult result) {
  final severity = result.status.severity.toLowerCase();
  final prediction = result.prediction.toLowerCase();

  if (severity == 'critical' || severity == 'high' || prediction == 'dead') {
    return const _StatusStyle(
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
    return const _StatusStyle(
      color: AppColors.bleached,
      soft: AppColors.bleachedSoft,
      softBorder: Color(0xFFF4D9BD),
      icon: Icons.wb_sunny_outlined,
      imageAsset: 'assets/images/bleach.png',
    );
  }

  return const _StatusStyle(
    color: AppColors.green,
    soft: AppColors.healthySoft,
    softBorder: Color(0xFFC9F1DE),
    icon: Icons.check_circle_outline_rounded,
    imageAsset: 'assets/images/health.png',
  );
}
