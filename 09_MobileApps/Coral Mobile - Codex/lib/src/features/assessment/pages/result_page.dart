import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/assessment_stepper.dart';
import '../../../shared/bottom_nav.dart';
import '../../history/data/history_repository.dart';
import '../models/assessment_models.dart';
import '../widgets/evidence_panel.dart';
import '../widgets/hero_panel.dart';
import '../widgets/status_style.dart';

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
                        child: HeroPanel(result: result),
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
                        child: EvidencePanel(result: result),
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

class _ConfidencePanel extends StatelessWidget {
  const _ConfidencePanel({required this.result});

  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = resolveStatus(result);
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFE85D4E).withValues(alpha: 0.08)
                    : const Color(0xFFE85D4E).withValues(alpha: 0.05),
                border: Border(
                  left: const BorderSide(color: Color(0xFFE85D4E), width: 4),
                  top: BorderSide(color: const Color(0xFFE85D4E).withValues(alpha: 0.15), width: 1),
                  right: BorderSide(color: const Color(0xFFE85D4E).withValues(alpha: 0.15), width: 1),
                  bottom: BorderSide(color: const Color(0xFFE85D4E).withValues(alpha: 0.15), width: 1),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE85D4E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UNCERTAIN INFERENCE',
                          style: TextStyle(
                            fontFamily: 'Rethink Sans',
                            color: Color(0xFFE85D4E),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1.5, right: 10),
                              child: Icon(
                                Icons.analytics_outlined,
                                size: 15,
                                color: const Color(0xFFE85D4E).withValues(alpha: 0.8),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
                                    fontSize: 13.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Confidence score is '),
                                    TextSpan(
                                      text: '${result.confidence.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        color: Color(0xFFE85D4E),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const TextSpan(text: ' (below the 75% threshold).'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1.5, right: 10),
                              child: Icon(
                                Icons.biotech_rounded,
                                size: 15,
                                color: const Color(0xFFE85D4E).withValues(alpha: 0.8),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Treat this diagnostic result as exploratory.',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
                                  fontSize: 13.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1.5, right: 10),
                              child: Icon(
                                Icons.rule_rounded,
                                size: 15,
                                color: const Color(0xFFE85D4E).withValues(alpha: 0.8),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Perform a manual verification or capture a new image.',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                  color: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
                                  fontSize: 13.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Split text into sentences for bullet points
    final sentences = text.split('. ').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

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
                  color: isDark ? Colors.white70 : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              ...sentences.asMap().entries.map((entry) {
                final index = entry.key;
                final sentence = entry.value;
                final finalSentence = sentence.endsWith('.') ? sentence : '$sentence.';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.5, right: 10),
                        child: Text(
                          '0${index + 1}',
                          style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                            color: (isDark ? AppColors.cyan : AppColors.primary).withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          finalSentence,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.ink,
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
