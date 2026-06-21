import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'app_top_bar.dart';
import 'assessment_stepper.dart';
import 'bottom_nav.dart';
import 'glass_card.dart';
import 'primary_action_button.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.activeTab,
    super.key,
    this.activeStep,
    this.nextRoute,
    this.nextLabel,
  });

  final String title;
  final String subtitle;
  final MainTab activeTab;
  final AssessmentStep? activeStep;
  final String? nextRoute;
  final String? nextLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4FAFF), Color(0xFFEFF8FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopBar(),
                if (activeStep != null) AssessmentStepper(activeStep: activeStep!),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 28),
                      Container(
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: AppColors.primarySoft,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Icon(
                          _iconForTab(activeTab),
                          size: 72,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (nextRoute != null && nextLabel != null) ...[
                  const SizedBox(height: 28),
                  PrimaryActionButton(
                    label: nextLabel!,
                    onPressed: () => Navigator.of(context).pushReplacementNamed(nextRoute!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CoralBottomNav(activeTab: activeTab),
    );
  }

  IconData _iconForTab(MainTab tab) {
    return switch (tab) {
      MainTab.home => Icons.home_outlined,
      MainTab.assess => Icons.camera_alt_outlined,
      MainTab.history => Icons.schedule_rounded,
      MainTab.learn => Icons.school_outlined,
      MainTab.chatbot => Icons.chat_bubble_outline_rounded,
    };
  }
}
