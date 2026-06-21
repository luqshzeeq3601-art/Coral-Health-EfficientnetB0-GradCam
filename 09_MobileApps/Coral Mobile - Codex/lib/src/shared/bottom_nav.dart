import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';

class CoralBottomNav extends StatelessWidget {
  const CoralBottomNav({
    required this.activeTab,
    super.key,
  });

  final MainTab activeTab;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home', MainTab.home,
          AppRoutes.home),
      _NavItem(Icons.photo_camera_rounded, Icons.photo_camera_outlined,
          'Analyze', MainTab.assess, AppRoutes.upload),
      _NavItem(Icons.psychology_rounded, Icons.psychology_outlined, 'Ask',
          MainTab.chatbot, AppRoutes.chatbot),
      _NavItem(Icons.watch_later_rounded, Icons.watch_later_outlined, 'History',
          MainTab.history, AppRoutes.history),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          // Performance: removed BackdropFilter (2-4ms/frame on every page).
          // A solid container with high opacity achieves a similar look.
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0E1A33).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E2F4D).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final item in items)
                  _BottomNavItem(
                    item: item,
                    isActive: item.tab == activeTab,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isActive,
  });

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.cyan : AppColors.primary;
    final color =
        isActive ? activeColor : AppColors.muted.withValues(alpha: 0.65);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isActive
          ? null
          : () => Navigator.of(context).pushReplacementNamed(item.route),
      child: SizedBox(
        width: 60,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Animated Icon movement
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: const ElasticOutCurve(0.9),
              top: isActive ? 6 : 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: isActive
                    ? ShaderMask(
                        key: const ValueKey('active'),
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [activeColor, AppColors.violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Icon(
                          item.activeIcon,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    : Icon(
                        item.inactiveIcon,
                        key: const ValueKey('inactive'),
                        color: color,
                        size: 24,
                      ),
              ),
            ),

            // Text fading in from the bottom
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: isActive ? 6 : -16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isActive ? 1.0 : 0.0,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(
      this.activeIcon, this.inactiveIcon, this.label, this.tab, this.route);

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final MainTab tab;
  final String route;
}

enum MainTab { home, assess, chatbot, history, learn }
