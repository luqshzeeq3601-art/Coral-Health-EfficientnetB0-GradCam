import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/app_assets.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/modern_scroll_indicator.dart';
import '../../../shared/tab_page_scaffold.dart';
import '../../history/models/history_record.dart';
import '../../history/data/history_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heroAnim;
  late final Animation<double> _headerAnim;
  late final Animation<double> _listAnim;
  late final Animation<double> _missionAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _heroAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _headerAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    );
    _listAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    );
    _missionAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      },
      child: TabPageScaffold(
        activeTab: MainTab.home,
        fallbackRoute: AppRoutes.onboarding,
        children: [
          _AnimatedEntrance(
            animation: _heroAnim,
            child: const _HeroAccuracyCard(),
          ),
          _AnimatedEntrance(
            animation: _headerAnim,
            child: Padding(
              padding: const EdgeInsets.only(top: 26, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Assessments',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFF1F5F9)
                            : AppColors.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.history),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cyan
                            : AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _AnimatedEntrance(
            animation: _listAnim,
            child: const _RecentAssessments(),
          ),
          const SizedBox(height: 18),
          _AnimatedEntrance(
            animation: _missionAnim,
            child: const _MissionCard(),
          ),
        ],
      ),
    );
  }
}

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        )),
        child: child,
      ),
    );
  }
}

class _HeroAccuracyCard extends StatefulWidget {
  const _HeroAccuracyCard();

  @override
  State<_HeroAccuracyCard> createState() => _HeroAccuracyCardState();
}

class _HeroAccuracyCardState extends State<_HeroAccuracyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _numberAnimation = Tween<double>(begin: 0.0, end: 98.11).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start the animation slightly after the page enters
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: (MediaQuery.of(context).size.height * 0.38).clamp(320.0, 400.0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A33) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E2F4D)
              : Colors.white.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x332362A7),
            blurRadius: 38,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.homeHeroBackground,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                // Performance: replaced BackdropFilter(sigma=4) with a stronger
                // gradient overlay. Blurring a static image on every frame is
                // wasteful — a denser gradient achieves the same visual.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF041031).withValues(alpha: 0.92),
                        const Color(0xFF0A4BB8).withValues(alpha: 0.60),
                        const Color(0xFF0EA5FF).withValues(alpha: 0.10),
                      ],
                      stops: const [0.1, 0.65, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _GlassPill(
                      icon: Icons.memory_rounded,
                      label: 'Model Performance',
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _numberAnimation,
                      builder: (context, child) {
                        final value = _numberAnimation.value;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${value.toStringAsFixed(2)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 50,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.2,
                                            height: 0.95,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Accuracy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                      height: 1.05,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _AccuracyGauge(value: value),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 285,
                      child: Text(
                        'Coral health detection accuracy across all models',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AnimatedHeroButton(
                      label: 'Analyze',
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.upload),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyGauge extends StatelessWidget {
  const _AccuracyGauge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0).toDouble();

    return Semantics(
      label: 'Accuracy gauge ${value.toStringAsFixed(2)} percent',
      child: SizedBox(
        width: 88,
        height: 64,
        child: CustomPaint(
          painter: _AccuracyGaugePainter(progress: progress),
        ),
      ),
    );
  }
}

class _AccuracyGaugePainter extends CustomPainter {
  const _AccuracyGaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 7);
    final radius = math.min(size.width / 2 - 8, size.height - 12);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.24);

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF35D6FF),
          Color(0xFF54F2A8),
          Color(0xFFFFE27A),
        ],
      ).createShader(rect);

    const startAngle = math.pi;
    const sweepAngle = math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);
    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, activePaint);

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i <= 4; i++) {
      final angle = startAngle + sweepAngle * (i / 4);
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 12),
        center.dy + math.sin(angle) * (radius - 12),
      );
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 3),
        center.dy + math.sin(angle) * (radius - 3),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final needleAngle = startAngle + sweepAngle * progress;
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 11),
      center.dy + math.sin(needleAngle) * (radius - 11),
    );

    final glowPaint = Paint()
      ..color = const Color(0xFF8DF6FF).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, glowPaint);
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      3,
      Paint()..color = const Color(0xFF0A4BB8),
    );
  }

  @override
  bool shouldRepaint(covariant _AccuracyGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AnimatedHeroButton extends StatefulWidget {
  const _AnimatedHeroButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_AnimatedHeroButton> createState() => _AnimatedHeroButtonState();
}

class _AnimatedHeroButtonState extends State<_AnimatedHeroButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _shineController,
          builder: (context, child) {
            final pulseGlow =
                12.0 + 4.0 * math.sin(_shineController.value * 2.0 * math.pi);
            final arrowOffset =
                math.sin(_shineController.value * 2.0 * math.pi) * 2.5;

            return Container(
              width: double.infinity,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6848F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: pulseGlow + 4.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      alignment: Alignment(
                        -2.0 + (_shineController.value * 4.0),
                        0.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: _isPressed ? 16.0 : 10.0,
                        ),
                        Transform.translate(
                          offset: Offset(arrowOffset, 0.0),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecentAssessments extends StatefulWidget {
  const _RecentAssessments();

  @override
  State<_RecentAssessments> createState() => _RecentAssessmentsState();
}

class _RecentAssessmentsState extends State<_RecentAssessments> {
  final _scrollController = ScrollController();
  late Future<List<HistoryRecord>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _recentFuture = HistoryRepository().getRecentRecords(limit: 4);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryRecord>>(
      future: _recentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 246,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1A33) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.history_rounded, size: 48, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text(
                    'No recent assessments',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload a coral image to begin.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 246,
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _RecentCard(item: items[index]),
              ),
            ),
            const SizedBox(height: 4),
            ModernScrollIndicator(
              controller: _scrollController,
              trackWidth: 60.0,
              pillWidth: 18.0,
            ),
          ],
        );
      },
    );
  }
}



class _RecentCardState extends State<_RecentCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      child: AnimatedScale(
        scale: _isTapped ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: (MediaQuery.of(context).size.width * 0.48).clamp(180.0, 240.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E1A33) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2F4D) : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFF0A4BB8).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with gradient overlay
              SizedBox(
                height: 130,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.item.imagePath != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          child: ClipRRect(
                            child: Image.file(
                              File(widget.item.imagePath!),
                              width: (MediaQuery.of(context).size.width * 0.48).clamp(180.0, 240.0),
                              height: 130,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          child: CoralThumbnail(
                            size: (MediaQuery.of(context).size.width * 0.48).clamp(180.0, 240.0),
                            variant: widget.item.variant,
                            showNetwork: true,
                          ),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.4),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.item.score,
                        style: TextStyle(
                          color: widget.item.color,
                          fontSize: 22,
                          letterSpacing: -0.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFF1F5F9).withValues(alpha: 0.8)
                              : AppColors.ink.withValues(alpha: 0.8),
                          fontSize: 14,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0C2540),
                  const Color(0xFF07142A),
                ]
              : [
                  const Color(0xFFF1FBFF),
                  const Color(0xFFE0F3FF),
                ],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2F4D) : Colors.white,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0A4BB8).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(AppAssets.logo, width: 42, height: 42),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CORE TECHNOLOGY',
                      style: TextStyle(
                        color: isDark ? AppColors.cyan : AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'EfficientNet-B0 +\nGrad-CAM',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time, on-device coral health classification powered by state-of-the-art vision models and visual explainability.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF8E9DBE)
                            : AppColors.ink.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MissionStat('224px', 'Input Size'),
              _MissionStat('5-Seed', 'Ensemble'),
              _MissionStat('<0.2s', 'Latency'),
              _MissionStat('Local', 'Inference'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Performance: removed BackdropFilter from glass pill. The blur was
    // unnecessary on a small pill widget and cost GPU time every frame.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _MissionStat extends StatelessWidget {
  const _MissionStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [isDark ? AppColors.cyan : AppColors.primary, const Color(0xFF6848F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white, // Needs to be white for ShaderMask
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF8E9DBE) : AppColors.ink.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _RecentCard extends StatefulWidget {
  const _RecentCard({required this.item});
  final HistoryRecord item;

  @override
  State<_RecentCard> createState() => _RecentCardState();
}
