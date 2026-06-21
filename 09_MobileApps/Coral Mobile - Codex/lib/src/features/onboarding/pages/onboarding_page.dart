import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/app_assets.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';

// --- Particle Background Engine Models & Widgets ---

class _Bubble {
  double x;
  double y;
  double radius;
  double speed;
  double sway;
  double opacity;

  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.sway,
    required this.opacity,
  });
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  _BubblePainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final bubble in bubbles) {
      final center = Offset(bubble.x * size.width, bubble.y * size.height);
      paint.color = Colors.white.withValues(alpha: bubble.opacity);
      canvas.drawCircle(center, bubble.radius, paint);
      canvas.drawCircle(center, bubble.radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _UnderwaterBackground extends StatefulWidget {
  const _UnderwaterBackground({required this.child});
  final Widget child;

  @override
  State<_UnderwaterBackground> createState() => _UnderwaterBackgroundState();
}

class _UnderwaterBackgroundState extends State<_UnderwaterBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    // Pre-populate bubbles at initial positions across the screen
    for (int i = 0; i < 25; i++) {
      _bubbles.add(_createBubble(initialY: true));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(_updateBubbles)
      ..repeat();
  }

  _Bubble _createBubble({required bool initialY}) {
    final radius = 2.0 + 8.0 * math.Random().nextDouble();
    return _Bubble(
      x: math.Random().nextDouble(),
      y: initialY ? math.Random().nextDouble() : 1.1,
      radius: radius,
      speed: 0.0008 +
          0.0016 * (radius / 10.0), // larger bubbles rise slightly faster
      sway: 0.3 + 0.7 * math.Random().nextDouble(),
      opacity: 0.08 + 0.16 * math.Random().nextDouble(),
    );
  }

  void _updateBubbles() {
    if (!mounted) return;
    setState(() {
      for (final bubble in _bubbles) {
        bubble.y -= bubble.speed;
        // Sway back and forth using sine
        bubble.x += math.sin(bubble.y * 15.0) * 0.0015 * bubble.sway;

        // Reset bubble when it goes past the top
        if (bubble.y < -0.1) {
          final index = _bubbles.indexOf(bubble);
          _bubbles[index] = _createBubble(initialY: false);
        }
      }
    });
  }

  void _addBubbleAt(double x, double y) {
    if (_bubbles.length > 30) {
      _bubbles.removeAt(0); // Cap particles count for performance
    }
    _bubbles.add(_Bubble(
      x: x,
      y: y,
      radius: 4.0 + 6.0 * math.Random().nextDouble(),
      speed: 0.0015 + 0.0015 * math.Random().nextDouble(),
      sway: 0.5 + 0.5 * math.Random().nextDouble(),
      opacity: 0.2 + 0.3 * math.Random().nextDouble(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.globalPosition);
        final xFraction = localPos.dx / renderBox.size.width;
        final yFraction = localPos.dy / renderBox.size.height;
        // Spawn a burst of 4 bubbles on user tap!
        for (int i = 0; i < 4; i++) {
          _addBubbleAt(
            xFraction + (math.Random().nextDouble() - 0.5) * 0.06,
            yFraction + (math.Random().nextDouble() - 0.5) * 0.06,
          );
        }
      },
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              AppAssets.homeHeroBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 1080,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.20),
                    const Color(0xFF8EEBFF).withValues(alpha: 0.04),
                    const Color(0xFF0057E6).withValues(alpha: 0.10),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          // Interactive Bubbles Custom Paint Layer
          Positioned.fill(
            child: CustomPaint(
              painter: _BubblePainter(_bubbles),
            ),
          ),
          // Child Widget Tree
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

// --- Onboarding Page View ---

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered Animations
  late final Animation<double> _logoTitleAnimation;
  late final Animation<double> _bottomSheetAnimation;
  late final Animation<double> _card1Animation;
  late final Animation<double> _card2Animation;
  late final Animation<double> _card3Animation;
  late final Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoTitleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    _bottomSheetAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
    );

    _card1Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
    );

    _card2Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
    );

    _card3Animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    _buttonAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
    );

    // Trigger animations on start
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _UnderwaterBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 800;

            // Responsive sizing & spacing parameters
            final double logoSize = isSmallScreen ? 60 : 80;
            final double titleFontSize = isSmallScreen ? 34 : 44;
            final double subTitleFontSize = isSmallScreen ? 14 : 16;
            final double spacing = isSmallScreen ? 8 : 12;
            final double bottomSheetTopPadding = isSmallScreen ? 50 : 68;
            final double bottomSheetBottomPadding = isSmallScreen ? 20 : 32;

            return Stack(
              children: [
                // Top Content (Logo & Brand Title)
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: _logoTitleAnimation,
                      child: SlideTransition(
                        position: _logoTitleAnimation.drive(
                          Tween<Offset>(
                            begin: const Offset(0.0, -0.15),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOutCubic)),
                        ),
                        child: Padding(
                          padding:
                              EdgeInsets.only(top: isSmallScreen ? 12.0 : 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(AppAssets.logo,
                                  width: logoSize, height: logoSize),
                              SizedBox(height: spacing),
                              _BrandTitle(fontSize: titleFontSize),
                              SizedBox(height: spacing),
                              const _DividerMark(),
                              SizedBox(height: spacing),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: Text(
                                  'AI-powered insights for\nhealthier coral reefs',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: 0.86),
                                        fontSize: subTitleFontSize,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Glassmorphic Animated Bottom Sheet
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedBuilder(
                    animation: _bottomSheetAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                            0, (1.0 - _bottomSheetAnimation.value) * 350),
                        child: child,
                      );
                    },
                    child: ClipPath(
                      clipper: const _WaveClipper(waveHeight: 32.0),
                      child: CustomPaint(
                        foregroundPainter:
                            _WaveBorderPainter(waveHeight: 32.0),
                        child: Container(
                          width: double.infinity,
                          color:
                              const Color(0xFFF4FBFF).withValues(alpha: 0.98),
                            padding: EdgeInsets.fromLTRB(
                                24,
                                bottomSheetTopPadding,
                                24,
                                bottomSheetBottomPadding),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Headline
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontSize: isSmallScreen ? 22 : 26,
                                          height: 1.15,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                          letterSpacing: -0.6,
                                        ),
                                    children: const [
                                      TextSpan(
                                          text: "Welcome to\n"),
                                      TextSpan(
                                        text: 'Coral AI',
                                        style:
                                            TextStyle(color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12),

                                // Body text
                                Text(
                                  'Monitor, analyze, and protect our oceans.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 32),

                                // 3 Staggered & Interactive Feature Cards
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _FeatureCard(
                                        icon: Icons.center_focus_strong_rounded,
                                        title: 'Scan & Monitor',
                                        description:
                                            'Capture coral images\nwith your camera',
                                        animation: _card1Animation,
                                        iconGradientColors: const [
                                          Color(0xFF0EA5FF),
                                          Color(0xFF0057E6)
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _FeatureCard(
                                        icon: Icons.auto_awesome_rounded,
                                        title: 'AI Analysis',
                                        description:
                                            'Get instant AI-powered\nhealth insights',
                                        animation: _card2Animation,
                                        iconGradientColors: const [
                                          Color(0xFF6848F5),
                                          Color(0xFFC084FC)
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _FeatureCard(
                                        icon: Icons.stacked_line_chart_rounded,
                                        title: 'Track & Improve',
                                        description:
                                            'Monitor changes and\nsupport reef health',
                                        animation: _card3Animation,
                                        iconGradientColors: const [
                                          Color(0xFF10B981),
                                          Color(0xFF06B6D4)
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 32),

                                // Animated Get Started Button
                                _GetStartedButton(
                                  animation: _buttonAnimation,
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed(AppRoutes.home);
                                  },
                                ),
                                SizedBox(height: isSmallScreen ? 4 : 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper({this.waveHeight = 32.0});
  final double waveHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, waveHeight);
    path.quadraticBezierTo(size.width / 2, 0, size.width, waveHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class _WaveBorderPainter extends CustomPainter {
  final double waveHeight;
  _WaveBorderPainter({this.waveHeight = 32.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white12,
          Colors.white,
          Colors.white12,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, waveHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, waveHeight);
    path.quadraticBezierTo(size.width / 2, 0, size.width, waveHeight);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandTitle extends StatefulWidget {
  const _BrandTitle({this.fontSize = 44});
  final double fontSize;

  @override
  State<_BrandTitle> createState() => _BrandTitleState();
}

class _BrandTitleState extends State<_BrandTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Column(
          children: [
            Text(
              'Coral',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.ink,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1.2,
                  ),
            ),
            ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    AppColors.primary,
                    AppColors.violet,
                    Color(0xFF0B3FB8),
                  ],
                  stops: [
                    0.0,
                    value,
                    1.0,
                  ],
                ).createShader(rect);
              },
              child: Text(
                'Health AI',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -1.2,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DividerMark extends StatelessWidget {
  const _DividerMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          child: Divider(
              color: AppColors.primary.withValues(alpha: 0.5), thickness: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CircleAvatar(
              radius: 3.5,
              backgroundColor: AppColors.primary.withValues(alpha: 0.7)),
        ),
        SizedBox(
          width: 32,
          child: Divider(
              color: AppColors.primary.withValues(alpha: 0.5), thickness: 1.5),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.animation,
    required this.iconGradientColors,
  });

  final IconData icon;
  final String title;
  final String description;
  final Animation<double> animation;
  final List<Color> iconGradientColors;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animation,
      child: SlideTransition(
        position: widget.animation.drive(
          Tween<Offset>(
            begin: const Offset(0.0, 0.25),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isTapped = true),
          onTapUp: (_) => setState(() => _isTapped = false),
          onTapCancel: () => setState(() => _isTapped = false),
          child: AnimatedScale(
            scale: _isTapped ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _isTapped ? 0.95 : 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isTapped
                      ? widget.iconGradientColors.first.withValues(alpha: 0.5)
                      : const Color(0xFFEEF2FF).withValues(alpha: 0.8),
                  width: _isTapped ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isTapped
                        ? widget.iconGradientColors.first
                            .withValues(alpha: 0.15)
                        : const Color(0xFF0A4BB8).withValues(alpha: 0.04),
                    blurRadius: _isTapped ? 16 : 12,
                    offset: _isTapped ? const Offset(0, 6) : const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Double-layered custom glassmorphic gradient icon container
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: widget.iconGradientColors.first
                            .withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconGradientColors.first
                              .withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.iconGradientColors,
                      ).createShader(bounds),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton({required this.onPressed, required this.animation});
  final VoidCallback onPressed;
  final Animation<double> animation;

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
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
    return FadeTransition(
      opacity: widget.animation,
      child: ScaleTransition(
        scale: widget.animation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                // Ambient pulse shadow animation
                final pulseGlow = 14.0 +
                    6.0 * math.sin(_shineController.value * 2.0 * math.pi);
                final arrowOffset =
                    math.sin(_shineController.value * 2.0 * math.pi) * 2.5;

                return Container(
                  width: double.infinity,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0057E6),
                        Color(0xFF2F6FF2),
                        Color(0xFF6848F5),
                      ],
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
                        spreadRadius: 2.0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF6848F5).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Metallic shine sweeping overlay
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
                                  Colors.white.withValues(alpha: 0.3),
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

                      // Central interactive row contents
                      Positioned.fill(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: _isPressed ? 18.0 : 12.0,
                            ),
                            Transform.translate(
                              offset: Offset(arrowOffset, 0.0),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
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
        ),
      ),
    );
  }
}
