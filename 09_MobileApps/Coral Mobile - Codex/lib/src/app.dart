import 'package:flutter/material.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'features/assessment/models/assessment_models.dart';
import 'features/assessment/pages/analyze_page.dart';
import 'features/assessment/pages/configure_page.dart';
import 'features/assessment/pages/result_page.dart';
import 'features/assessment/pages/upload_page.dart';
import 'features/history/models/history_record.dart';
import 'features/history/pages/history_detail_page.dart';
import 'features/history/pages/history_page.dart';
import 'features/home/pages/home_page.dart';
import 'features/chatbot/pages/chatbot_page.dart';

import 'features/onboarding/pages/onboarding_page.dart';
import 'features/settings/pages/settings_page.dart';
import 'shared/desktop_phone_frame.dart';

class CoralHealthApp extends StatelessWidget {
  const CoralHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coral Health AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        final child = switch (settings.name) {
          AppRoutes.onboarding => const OnboardingPage(),
          AppRoutes.home => const HomePage(),
          AppRoutes.upload => const UploadPage(),
          AppRoutes.configure => ConfigurePage(
              selectedImage: args is SelectedCoralImage ? args : null,
            ),
          AppRoutes.analyze => AnalyzePage(
              run: args is AssessmentRun ? args : null,
            ),
          AppRoutes.result => ResultPage(
              result: args is PredictionResult ? args : null,
            ),
          AppRoutes.chatbot => ChatbotPage(
              predictionContext: args is PredictionResult ? args : null,
            ),
          AppRoutes.history => const HistoryPage(),
          AppRoutes.historyDetail => args is HistoryRecord
              ? HistoryDetailPage(record: args)
              : const HistoryPage(),
          AppRoutes.settings => const SettingsPage(),
          _ => const OnboardingPage(),
        };

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DesktopPhoneFrame(child: child),
        );
      },
    );
  }
}
