import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import 'app_top_bar.dart';
import 'bottom_nav.dart';

class TabPageScaffold extends StatelessWidget {
  const TabPageScaffold({
    required this.activeTab,
    required this.children,
    super.key,
    this.showTopBar = true,
    this.fallbackRoute,
    this.topBarActionIcon,
    this.onTopBarAction,
  });

  final MainTab activeTab;
  final List<Widget> children;
  final bool showTopBar;
  final String? fallbackRoute;
  final IconData? topBarActionIcon;
  final VoidCallback? onTopBarAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [
            const Color(0xFF050E25),
            const Color(0xFF040D21),
            const Color(0xFF020712),
          ]
        : [
            const Color(0xFFFFFFFF),
            const Color(0xFFFBFBFA),
            AppColors.page,
          ];

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTopBar)
                  AppTopBar(
                    showBackButton: false,
                    fallbackRoute: fallbackRoute ?? AppRoutes.home,
                    extraActionIcon: topBarActionIcon,
                    onExtraAction: onTopBarAction,
                  ),
                ...children,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CoralBottomNav(activeTab: activeTab),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
