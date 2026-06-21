import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/tab_page_scaffold.dart';
import '../../history/models/history_record.dart';
import '../../history/data/history_repository.dart';

class ReefAnalyticsPage extends StatefulWidget {
  const ReefAnalyticsPage({super.key});

  @override
  State<ReefAnalyticsPage> createState() => _ReefAnalyticsPageState();
}

class _ReefAnalyticsPageState extends State<ReefAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered card animations
  late final Animation<double> _healthAnim;
  late final Animation<double> _statsAnim;
  late final Animation<double> _distAnim;
  late final Animation<double> _timelineAnim;

  // Aggregate stats variables
  int _totalSurveys = 0;
  double _healthyCount = 0;
  double _bleachedCount = 0;
  double _deadCount = 0;

  double _bleachingRate = 0.0;
  double _mortalityRate = 0.0;
  double _avgConfidence = 0.0;
  double _healthIndex = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _healthAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _statsAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
    );
    _distAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    );
    _timelineAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    );

    _calculateAggregates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _calculateAggregates() async {
    final records = await HistoryRepository().getAllRecords();

    if (records.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _controller.forward();
      return;
    }

    _totalSurveys = records.length;

    double confidenceSum = 0.0;

    for (final record in records) {
      confidenceSum += record.confidence;
      if (record.label.toLowerCase() == 'healthy') {
        _healthyCount++;
      } else if (record.label.toLowerCase() == 'bleached') {
        _bleachedCount++;
      } else if (record.label.toLowerCase() == 'dead') {
        _deadCount++;
      }
    }

    _bleachingRate = (_bleachedCount / _totalSurveys) * 100;
    _mortalityRate = (_deadCount / _totalSurveys) * 100;
    _avgConfidence = (confidenceSum / _totalSurveys) * 100;

    // Reef Health Index: Weighted scale where Healthy is 100%, Bleached is 50%, Dead is 0%
    _healthIndex =
        ((_healthyCount * 1.0 + _bleachedCount * 0.5) / _totalSurveys) * 100;
        
    setState(() {
      _isLoading = false;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      },
      child: TabPageScaffold(
        activeTab: MainTab.home, // Assuming analytics is not a MainTab anymore since error "no constant named analytics"
        fallbackRoute: AppRoutes.home,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            _AnimatedEntrance(
            animation: _healthAnim,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'Reef Analytics',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF1F5F9)
                      : AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AnimatedEntrance(
            animation: _healthAnim,
            child: _buildHealthIndexCard(),
          ),
          const SizedBox(height: 16),
          _AnimatedEntrance(
            animation: _statsAnim,
            child: _buildStatsGrid(),
          ),
          const SizedBox(height: 16),
          _AnimatedEntrance(
            animation: _distAnim,
            child: _buildDistributionCard(),
          ),
          const SizedBox(height: 16),
            _AnimatedEntrance(
              animation: _timelineAnim,
              child: const _RecentSurveysTable(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthIndexCard() {
    return _ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REEF HEALTH INDEX',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.cyan
                        : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Weighted Ecological Score',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF1F5F9)
                        : AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reflects relative ratios of live coral cover and tissue conditions calculated from the active survey log.',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF8E9DBE)
                        : AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _HealthGauge(value: _healthIndex),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        label: 'Total Surveys',
        value: '$_totalSurveys',
        unit: 'scans',
        icon: Icons.search_rounded,
        color: AppColors.primary,
      ),
      _StatData(
        label: 'Bleaching Rate',
        value: '${_bleachingRate.toStringAsFixed(1)}%',
        unit: 'of scans',
        icon: Icons.wb_sunny_outlined,
        color: AppColors.bleached,
      ),
      _StatData(
        label: 'Mortality Rate',
        value: '${_mortalityRate.toStringAsFixed(1)}%',
        unit: 'dead coral',
        icon: Icons.warning_amber_rounded,
        color: AppColors.dead,
      ),
      _StatData(
        label: 'Avg. Confidence',
        value: '${_avgConfidence.toStringAsFixed(1)}%',
        unit: 'AI readout',
        icon: Icons.psychology_outlined,
        color: AppColors.healthy,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(stats[0])),
            const SizedBox(width: 14),
            Expanded(child: _buildStatCard(stats[1])),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildStatCard(stats[2])),
            const SizedBox(width: 14),
            Expanded(child: _buildStatCard(stats[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final resolvedColor = (data.color == AppColors.primary && isDark) ? AppColors.cyan : data.color;

        return _ModernCard(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  data.icon,
                  size: 72,
                  color: resolvedColor.withValues(alpha: 0.05),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: resolvedColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(data.icon, color: resolvedColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data.value,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.unit,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistributionCard() {
    final double healthyRatio =
        _totalSurveys > 0 ? _healthyCount / _totalSurveys : 0.0;
    final double bleachedRatio =
        _totalSurveys > 0 ? _bleachedCount / _totalSurveys : 0.0;
    final double deadRatio =
        _totalSurveys > 0 ? _deadCount / _totalSurveys : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ECOLOGICAL HEALTH DISTRIBUTION',
            style: TextStyle(
              color: isDark ? AppColors.cyan : AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          // Horizontal segmented bar
          Container(
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: AppColors.muted.withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Row(
                children: [
                  if (healthyRatio > 0)
                    Expanded(
                      flex: (healthyRatio * 100).round(),
                      child: Container(color: AppColors.healthy),
                    ),
                  if (bleachedRatio > 0)
                    Expanded(
                      flex: (bleachedRatio * 100).round(),
                      child: Container(color: AppColors.bleached),
                    ),
                  if (deadRatio > 0)
                    Expanded(
                      flex: (deadRatio * 100).round(),
                      child: Container(color: AppColors.dead),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildLegendItem(
                    context,
                    'Healthy',
                    '${_healthyCount.toInt()}',
                    '${(healthyRatio * 100).toStringAsFixed(0)}%',
                    AppColors.healthy),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLegendItem(
                    context,
                    'Bleached',
                    '${_bleachedCount.toInt()}',
                    '${(bleachedRatio * 100).toStringAsFixed(0)}%',
                    AppColors.bleached),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLegendItem(
                    context,
                    'Dead',
                    '${_deadCount.toInt()}',
                    '${(deadRatio * 100).toStringAsFixed(0)}%',
                    AppColors.dead),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, String label, String count, String percentage, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count ($percentage)',
          style: TextStyle(
            color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }


}

class _RecentSurveysTable extends StatefulWidget {
  const _RecentSurveysTable();

  @override
  State<_RecentSurveysTable> createState() => _RecentSurveysTableState();
}

class _RecentSurveysTableState extends State<_RecentSurveysTable> {
  late Future<List<HistoryRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = HistoryRepository().getRecentRecords(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryRecord>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        final isDark = Theme.of(context).brightness == Brightness.dark;

    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No surveys recorded yet.',
            style: TextStyle(
              color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT SURVEY LOGS',
              style: TextStyle(
                color: isDark ? AppColors.cyan : AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '${records.length} total',
              style: TextStyle(
                color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Date
            1: FlexColumnWidth(1.4), // Type
            2: FlexColumnWidth(1.0), // Confidence
            3: FlexColumnWidth(1.0), // Model
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
                    width: 1,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'DATE',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'CLASSIFICATION',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'CONFIDENCE',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'MODEL',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            ...records.map((record) {
              return TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF1E2F4D).withValues(alpha: 0.5) : const Color(0xFFF0F0F0),
                      width: 1,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      record.date,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: record.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          record.label,
                          style: TextStyle(
                            color: record.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      record.score,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      record.model,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
      },
    );
  }
}

class _StatData {
  _StatData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
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

class _ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ModernCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
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
                : const Color(0xFF0A4BB8).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HealthGauge extends StatefulWidget {
  const _HealthGauge({required this.value});
  final double value;

  @override
  State<_HealthGauge> createState() => _HealthGaugeState();
}

class _HealthGaugeState extends State<_HealthGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gaugeController;
  late final Animation<double> _gaugeValueAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _gaugeValueAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value / 100.0,
    ).animate(CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutBack,
    ));

    _gaugeController.forward();
  }

  @override
  void didUpdateWidget(covariant _HealthGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _gaugeValueAnimation = Tween<double>(
        begin: _gaugeValueAnimation.value,
        end: widget.value / 100.0,
      ).animate(CurvedAnimation(
        parent: _gaugeController,
        curve: Curves.easeOutBack,
      ));
      _gaugeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 90,
      height: 90,
      child: AnimatedBuilder(
        animation: _gaugeValueAnimation,
        builder: (context, child) {
          final progress = _gaugeValueAnimation.value;
          return CustomPaint(
            painter: _CleanGaugePainter(progress: progress, isDark: isDark),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (progress * 100).toStringAsFixed(0),
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'INDEX',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      height: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CleanGaugePainter extends CustomPainter {
  _CleanGaugePainter({required this.progress, required this.isDark});
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track Paint
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = isDark ? const Color(0xFF1E2F4D) : AppColors.muted.withValues(alpha: 0.12);

    // Active Paint
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          AppColors.dead,
          AppColors.bleached,
          AppColors.healthy,
          isDark ? AppColors.cyan : AppColors.primary,
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CleanGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}


