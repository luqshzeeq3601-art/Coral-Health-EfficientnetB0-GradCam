import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.showBackButton = true,
    this.showSettingsButton = true,
    this.fallbackRoute,
    this.extraActionIcon,
    this.onExtraAction,
  });

  final bool showBackButton;
  final bool showSettingsButton;
  final String? fallbackRoute;
  final IconData? extraActionIcon;
  final VoidCallback? onExtraAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Row(
        children: [
          if (showBackButton)
            _RoundIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                  return;
                }
                navigator
                    .pushReplacementNamed(fallbackRoute ?? AppRoutes.home);
              },
            )
          else
            const SizedBox(width: 46, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Image.asset(AppAssets.logo, width: 40, height: 40),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Coral Health AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (extraActionIcon != null && onExtraAction != null) ...[
            _RoundIconButton(
              icon: extraActionIcon!,
              onPressed: onExtraAction,
            ),
            const SizedBox(width: 10),
          ],
          if (showSettingsButton)
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
              tooltip: 'Settings',
            )
          else
            const SizedBox(width: 46, height: 46),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

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
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : const Color(0x142362A7),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            color: onPressed == null
                ? AppColors.muted
                : (isDark ? const Color(0xFFF1F5F9) : AppColors.ink),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
