import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/settings_store.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/assessment_stepper.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/primary_action_button.dart';
import '../data/prediction_repository.dart';
import '../models/assessment_models.dart';
import '../widgets/oceanic_background.dart';
import '../widgets/processing_orb.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({
    super.key,
    this.run,
  });

  final AssessmentRun? run;

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _pipelineController;
  late final AnimationController _shimmerController;
  late final AnimationController _bgController;
  late final Animation<double> _entranceAnimation;
  bool _isComplete = false;
  bool _animationComplete = false;
  bool _isRunningPrediction = false;
  bool _navigated = false;
  PredictionResult? _result;
  PredictionError? _error;
  final PredictionRepository _repository = PredictionRepository();
  final SettingsStore _settingsStore = SettingsStore();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Performance: track pipeline completion without setState on every frame
  final ValueNotifier<bool> _pipelineCompleteNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final runtimeMode = widget.run?.config.runtimeMode ?? ModelRuntimeMode.auto;
    final isOffline = runtimeMode == ModelRuntimeMode.offline;

    _pipelineController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isOffline ? 1500 : 6500),
    );

    _entranceAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: const Interval(0, 0.32, curve: Curves.easeOutCubic),
    );

    // Performance fix: only react to completion, not every frame tick.
    // The AnimatedBuilder widgets below handle per-frame visual updates.
    _pipelineController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationComplete = true;
        final complete = _result != null;
        if (complete != _isComplete) {
          setState(() => _isComplete = complete);
        }
        _pipelineCompleteNotifier.value = true;
        _checkAndNavigate();
      }
    });

    _runPrediction();
  }

  @override
  void dispose() {
    _pipelineCompleteNotifier.dispose();
    _pulseController.dispose();
    _pipelineController.dispose();
    _shimmerController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (_result != null && _pipelineController.isCompleted) {
      if (!_navigated) {
        _navigated = true;

        // Trigger notification exactly as we transition
        _settingsStore.getAssessmentNotificationsEnabled().then((showNotification) {
          if (showNotification && mounted) {
            _showCompletionNotification(_result!);
          }
        });

        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.result,
            arguments: _result,
          );
        });
      }
    }
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(
      initSettings,
    );

    // Request permission on Android 13+ (API 33+)
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _showCompletionNotification(PredictionResult result) async {
    const androidDetails = AndroidNotificationDetails(
      'assessment_channel_id_v2',
      'Assessment Complete',
      channelDescription: 'Notifications for completed coral health assessments',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Coral Assessment Complete',
      'Result: ${result.prediction} (${result.confidence.toStringAsFixed(1)}% confidence)',
      platformDetails,
    );
  }

  Future<void> _runPrediction() async {
    // Wait for the transition animation to complete so page navigation is completely smooth
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final run = widget.run;
    if (run == null) {
      setState(() {
        _error = const PredictionError(
          message: 'No assessment image was provided. Return to upload and select a coral image.',
        );
        _isRunningPrediction = false;
      });
      return;
    }

    setState(() {
      _isRunningPrediction = true;
      _error = null;
      _result = null;
      _isComplete = false;
      _animationComplete = false;
      _navigated = false;
    });

    _pipelineController
      ..reset()
      ..forward();

    try {
      final result = await _repository.runPrediction(run);
      if (!mounted) return;

      // Smoothly animate the rest of the gauge based on how much is left
      if (_pipelineController.isAnimating) {
        final remainingFraction = 1.0 - _pipelineController.value;
        final isOffline = run.config.runtimeMode == ModelRuntimeMode.offline;

        // Take between 800ms and 1500ms (or 200ms and 400ms if offline/local) to finish the animation smoothly
        final minMs = isOffline ? 200 : 800;
        final maxMs = isOffline ? 400 : 1500;
        final multiplier = isOffline ? 500 : 2000;
        final remainingMs = (remainingFraction * multiplier).clamp(minMs, maxMs).toInt();

        _pipelineController.animateTo(
          1.0,
          duration: Duration(milliseconds: remainingMs),
          curve: Curves.easeOutCubic,
        );
      }

      setState(() {
        _result = result;
        _isRunningPrediction = false;
        _isComplete = _animationComplete || _pipelineController.isCompleted;
        _checkAndNavigate();
      });
    } on PredictionFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = failure.error;
        _isRunningPrediction = false;
        _isComplete = false;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Unexpected prediction error: $error');
      setState(() {
        _error = PredictionError(message: 'Unexpected error occurred: $error');
        _isRunningPrediction = false;
        _isComplete = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Fluid Oceanic Background
          OceanicBackground(controller: _bgController),

          // 2. Main Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppTopBar(showBackButton: false),
                  const AssessmentStepper(activeStep: AssessmentStep.analyze),
                  FadeTransition(
                    opacity: _entranceAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(_entranceAnimation),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Oceanic AI Analysis',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mapping coral tissue texture, health signals, and explainability heat layers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Performance: scope pipeline-value rebuilds to only these widgets
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pipelineController,
                      builder: (context, _) => ProcessingOrb(
                        pulseAnimation: _pulseController,
                        overallProgress: _pipelineController.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pipelineController,
                      builder: (context, _) => _PipelineList(
                        overallProgress: _pipelineController.value,
                        shimmerController: _shimmerController,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    _AnalysisFailureCard(
                      error: _error!,
                      onRetry: _runPrediction,
                      onSettings: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                      onUpload: () => Navigator.of(context).pushReplacementNamed(AppRoutes.upload),
                    ),
                  ] else if (_result != null && !_isComplete) ...[
                    const SizedBox(height: 18),
                    _WaitingForReportCard(isRunningPrediction: _isRunningPrediction),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _isComplete ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isComplete,
                  child: _ShimmerButton(
                    shimmerController: _shimmerController,
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                      AppRoutes.result,
                      arguments: _result,
                    ),
                  ),
                ),
              ),
            ),
            const CoralBottomNav(activeTab: MainTab.assess),
          ],
        ),
      ),
    );
  }
}

class _WaitingForReportCard extends StatelessWidget {
  const _WaitingForReportCard({required this.isRunningPrediction});

  final bool isRunningPrediction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A33).withValues(alpha: 0.84) : Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF1E2F4D) : AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt_rounded, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isRunningPrediction
                  ? 'Backend inference is still running...'
                  : 'Prediction is ready. Finishing the report animation...',
              style: TextStyle(
                color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisFailureCard extends StatelessWidget {
  const _AnalysisFailureCard({
    required this.error,
    required this.onRetry,
    required this.onSettings,
    required this.onUpload,
  });

  final PredictionError error;
  final VoidCallback onRetry;
  final VoidCallback onSettings;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A33).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF5A2A2A) : const Color(0xFFFFD1D1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x2A000000) : const Color(0x14000000),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D1D1D) : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend prediction failed',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      error.statusCode == null
                          ? error.message
                          : '${error.message} (HTTP ${error.statusCode})',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF8E9DBE) : AppColors.muted,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CompactActionButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onTap: onRetry,
                filled: true,
              ),
              _CompactActionButton(
                label: 'Settings',
                icon: Icons.settings_rounded,
                onTap: onSettings,
              ),
              _CompactActionButton(
                label: 'Upload',
                icon: Icons.image_rounded,
                onTap: onUpload,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 46,
      child: filled
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                side: BorderSide(color: isDark ? const Color(0xFF1E2F4D) : AppColors.line),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
    );
  }
}

enum PipelineStatus { standby, queued, running, complete }

class PipelineStepData {
  final String title;
  final String description;
  final IconData icon;
  final double progress;
  final PipelineStatus status;

  PipelineStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.status,
  });
}

class _PipelineList extends StatelessWidget {
  const _PipelineList({required this.overallProgress, required this.shimmerController});

  final double overallProgress;
  final AnimationController shimmerController;

  PipelineStepData getStepData(int stepIndex) {
    final start = [0.0, 0.25, 0.55, 0.80][stepIndex];
    final end = [0.25, 0.55, 0.80, 1.0][stepIndex];

    final String title = [
      'Image Preprocessing',
      'Feature Extraction',
      'Grad-CAM Generation',
      'Output Verification'
    ][stepIndex];

    final String description = [
      'Noise removal and chroma normalization complete.',
      'EfficientNet pass is isolating tissue morphology.',
      'Attention heatmap layers are being synthesized.',
      'Probability calibration and final class validation.'
    ][stepIndex];

    final IconData icon = [
      Icons.auto_awesome_rounded,
      Icons.account_tree_rounded,
      Icons.radar_rounded,
      Icons.verified_rounded
    ][stepIndex];

    double progress = 0.0;
    PipelineStatus status = PipelineStatus.standby;

    if (overallProgress >= end) {
      progress = 1.0;
      status = PipelineStatus.complete;
    } else if (overallProgress < start) {
      progress = 0.0;
      if (stepIndex == 1) {
        status = overallProgress > 0.0 ? PipelineStatus.queued : PipelineStatus.standby;
      } else if (stepIndex == 2) {
        status = overallProgress > 0.25 ? PipelineStatus.queued : PipelineStatus.standby;
      } else if (stepIndex == 3) {
        status = overallProgress > 0.55 ? PipelineStatus.queued : PipelineStatus.standby;
      } else {
        status = PipelineStatus.standby;
      }
    } else {
      progress = (overallProgress - start) / (end - start);
      status = PipelineStatus.running;
    }

    return PipelineStepData(
      title: title,
      description: description,
      icon: icon,
      progress: progress,
      status: status,
    );
  }

  Color getStatusColor(PipelineStatus status, int stepIndex) {
    final stepColors = [
      const Color(0xFF0EA5FF), // Cyan/Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF43F5E), // Rose
      const Color(0xFF10B981), // Emerald
    ];
    final activeColor = stepColors[stepIndex];

    switch (status) {
      case PipelineStatus.complete:
      case PipelineStatus.running:
        return activeColor;
      case PipelineStatus.queued:
        return AppColors.muted;
      case PipelineStatus.standby:
        return AppColors.muted.withValues(alpha: 0.6);
    }
  }

  String getStatusText(PipelineStatus status) {
    switch (status) {
      case PipelineStatus.complete:
        return 'Complete';
      case PipelineStatus.running:
        return 'Running';
      case PipelineStatus.queued:
        return 'Queued';
      case PipelineStatus.standby:
        return 'Standby';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) {
        final step = getStepData(index);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PipelineStep(
            title: step.title,
            description: step.description,
            progress: step.progress,
            icon: step.icon,
            color: getStatusColor(step.status, index),
            statusText: getStatusText(step.status),
            status: step.status,
            delay: index * 100,
            shimmerController: shimmerController,
          ),
        );
      }),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.title,
    required this.description,
    required this.progress,
    required this.icon,
    required this.color,
    required this.statusText,
    required this.status,
    required this.delay,
    required this.shimmerController,
  });

  final String title;
  final String description;
  final double progress;
  final IconData icon;
  final Color color;
  final String statusText;
  final PipelineStatus status;
  final int delay;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = status == PipelineStatus.running;
    final isComplete = status == PipelineStatus.complete;
    final isActive = isRunning || isComplete;

    Widget cardContent = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A33) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: isRunning ? 0.3 : 0.1)
              : (isDark ? const Color(0xFF1E2F4D) : AppColors.muted.withValues(alpha: 0.1)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? color.withValues(alpha: 0.08)
                : (isDark ? const Color(0x1A000000) : const Color(0x06000000)),
            blurRadius: isActive ? 24 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Elegant progress fill background
          if (progress > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.02),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

          // If complete, add a very subtle success wash
          if (isComplete)
            Positioned.fill(
              child: Container(
                color: color.withValues(alpha: 0.04),
              ),
            ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium Icon Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.12) : AppColors.muted.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isActive ? color : AppColors.muted.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isActive ? (isDark ? const Color(0xFFF1F5F9) : AppColors.ink) : (isDark ? const Color(0xFF8E9DBE).withValues(alpha: 0.7) : AppColors.muted.withValues(alpha: 0.7)),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: isActive ? (isDark ? const Color(0xFF8E9DBE) : AppColors.muted) : (isDark ? const Color(0xFF8E9DBE).withValues(alpha: 0.5) : AppColors.muted.withValues(alpha: 0.5)),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Indicator
                if (isActive) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isComplete ? color : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isRunning)
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 3.5,
                              color: color,
                              backgroundColor: color.withValues(alpha: 0.15),
                            ),
                          ),
                        if (isComplete)
                          const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        if (isRunning && progress > 0)
                          Text(
                            '${(progress * 100).toInt()}',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Apply shimmer if running
    if (isRunning) {
      cardContent = AnimatedBuilder(
        animation: shimmerController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  color.withValues(alpha: 0.0),
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.0),
                ],
                stops: [
                  shimmerController.value - 0.2,
                  shimmerController.value,
                  shimmerController.value + 0.2,
                ],
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                tileMode: TileMode.clamp,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          );
        },
        child: cardContent,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      // Performance: removed BackdropFilter from every pipeline step card.
      // 4 cards × BackdropFilter = extremely expensive on low-end devices.
      child: cardContent,
    );
  }
}

class _ShimmerButton extends StatelessWidget {
  const _ShimmerButton({required this.shimmerController, required this.onPressed});

  final AnimationController shimmerController;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                PrimaryActionButton(
                  label: 'Show Results',
                  onPressed: onPressed,
                ),
                // Shimmer sweep across the button
                Positioned.fill(
                  child: IgnorePointer(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        final v = shimmerController.value;
                        return LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.4),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: [v - 0.2, v, v + 0.2],
                          begin: const Alignment(-1.0, -0.3),
                          end: const Alignment(1.0, 0.3),
                          tileMode: TileMode.clamp,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
