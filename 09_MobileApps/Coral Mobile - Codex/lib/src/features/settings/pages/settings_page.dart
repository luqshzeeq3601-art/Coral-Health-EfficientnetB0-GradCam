import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../core/settings_store.dart';
import '../../../core/app_theme.dart';
import '../../assessment/data/online_prediction_service.dart';
import '../../../shared/app_top_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _apiUrlController;
  bool _assessmentNotifications = true;
  bool _offlineCache = false;
  bool _monthlyImpactReports = false;
  bool _isTestingConnection = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.idle;
  final SettingsStore _settingsStore = SettingsStore();

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(
      text: SettingsStore.defaultBackendUrl,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final url = await _settingsStore.getBackendUrl();
    final notifications = await _settingsStore.getAssessmentNotificationsEnabled();
    final offlineCache = await _settingsStore.getOfflineCacheEnabled();
    final monthlyImpactReports = await _settingsStore.getMonthlyImpactReportsEnabled();
    if (!mounted) return;
    setState(() {
      _apiUrlController.text = url;
      _assessmentNotifications = notifications;
      _offlineCache = offlineCache;
      _monthlyImpactReports = monthlyImpactReports;
    });
  }


  Future<void> _testConnection() async {
    final normalizedUrl = SettingsStore.normalizeBackendUrl(_apiUrlController.text);
    final uri = Uri.tryParse(normalizedUrl);
    final isValidUrl = uri != null &&
        uri.hasScheme &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');

    setState(() {
      _isTestingConnection = true;
      _connectionStatus = ConnectionStatus.idle;
    });

    if (!isValidUrl) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = ConnectionStatus.failed;
      });
      return;
    }

    try {
      final service = OnlinePredictionService(backendBaseUrl: normalizedUrl);
      await service.health();
      await _settingsStore.saveBackendUrl(normalizedUrl);
      if (!mounted) return;

      setState(() {
        _apiUrlController.text = normalizedUrl;
        _isTestingConnection = false;
        _connectionStatus = ConnectionStatus.connected;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isTestingConnection = false;
        _connectionStatus = ConnectionStatus.failed;
      });
    }
  }

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
            const Color(0xFFF1F5F9),
            const Color(0xFFF1F5F9),
            const Color(0xFFF1F5F9),
          ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopBar(showSettingsButton: false),
                const _SettingsHero(),
                const SizedBox(height: 18),
                _ConnectionCard(
                  controller: _apiUrlController,
                  isTesting: _isTestingConnection,
                  status: _connectionStatus,
                  onTestConnection: _testConnection,
                ),

                const SizedBox(height: 14),
                _ModernSection(
                  title: 'Account',
                  icon: Icons.person_outline_rounded,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.onboarding,
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                            side: BorderSide(
                              color: isDark ? const Color(0xFF1E2F4D) : AppColors.line,
                              width: 1.2,
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _AppInfoFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


enum ConnectionStatus { idle, connected, failed }

TextStyle _titleStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );
}


class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'Settings',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tune alerts, analysis behavior, and data handling for field work.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                height: 1.5,
                fontSize: 15,
              ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C2540) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waves_rounded,
            color: isDark ? AppColors.cyan : AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Field Research Team',
            style: TextStyle(
              color: isDark ? AppColors.cyan : AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const dotColor = AppColors.green;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.controller,
    required this.isTesting,
    required this.status,
    required this.onTestConnection,
  });

  final TextEditingController controller;
  final bool isTesting;
  final ConnectionStatus status;
  final VoidCallback onTestConnection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ModernSection(
      title: 'Connection',
      icon: Icons.wifi_tethering_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backend API URL', style: _titleStyle(context).copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      'Remote endpoint for AI inference processing.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1D4ED8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Make sure "run coral ai.bat" is running on your laptop to accept connections.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.muted, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? AppColors.cyan : AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Presets',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _PresetChip(
                    label: 'Laptop',
                    url: 'http://192.168.0.8:5000',
                    controller: controller,
                    currentValue: value.text,
                  ),
                  _PresetChip(
                    label: 'Emulator',
                    url: 'http://10.0.2.2:5000',
                    controller: controller,
                    currentValue: value.text,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isTesting ? null : onTestConnection,
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                foregroundColor: isDark ? Colors.white : AppColors.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Test Connection',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
            ),
          ),
          if (status != ConnectionStatus.idle) ...[
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _ConnectionMessage(status: status),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.url,
    required this.controller,
    required this.currentValue,
  });

  final String label;
  final String url;
  final TextEditingController controller;
  final String currentValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = currentValue.trim().replaceAll(RegExp(r'/$'), '') ==
        url.trim().replaceAll(RegExp(r'/$'), '');

    return GestureDetector(
      onTap: () {
        controller.text = url;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: url.length),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.1) : AppColors.primarySoft)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.cyan : AppColors.primary)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppColors.cyan : AppColors.primary)
                : (isDark ? const Color(0xFF94A3B8) : AppColors.muted),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ModernSection extends StatelessWidget {
  const _ModernSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? AppColors.cyan : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF1F5F9) : AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionMessage extends StatelessWidget {
  const _ConnectionMessage({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    // Only show a message for connected or failed states, not idle
    if (status == ConnectionStatus.idle) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, text, color, background) = switch (status) {
      ConnectionStatus.connected => (
          Icons.check_circle_rounded,
          'Connected! Endpoint saved successfully.',
          AppColors.green,
          isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFEAFBF3),
        ),
      ConnectionStatus.failed => (
          Icons.error_rounded,
          'Could not reach backend. Check the URL and make sure the server is running.',
          const Color(0xFFEF4444),
          isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFFF0F0),
        ),
      ConnectionStatus.idle => (
          Icons.info_outline_rounded,
          '',
          AppColors.muted,
          Colors.transparent,
        ),
    };

    return Container(
      key: ValueKey(status),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                height: 1.35,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfoFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waves_rounded,
                size: 16,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 6),
              Text(
                'Coral Health AI  •  v1.0.0',
                style: TextStyle(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'EfficientNet-B0  •  On-device + Cloud inference',
            style: TextStyle(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}



class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: value
                ? (isDark ? AppColors.cyan : AppColors.primary)
                : AppColors.muted,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle(context).copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: isDark ? AppColors.cyan : AppColors.primary,
            activeTrackColor: (isDark ? AppColors.cyan : AppColors.primary).withValues(alpha: 0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}



class _IconBubble extends StatelessWidget {
  const _IconBubble(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}


