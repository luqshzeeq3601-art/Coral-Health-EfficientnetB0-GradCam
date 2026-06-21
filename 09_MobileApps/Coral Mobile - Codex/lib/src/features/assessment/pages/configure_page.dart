import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/assessment_stepper.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/glass_card.dart';
import '../../../shared/primary_action_button.dart';
import '../models/assessment_models.dart';

class ConfigurePage extends StatefulWidget {
  const ConfigurePage({
    super.key,
    this.selectedImage,
  });

  final SelectedCoralImage? selectedImage;

  @override
  State<ConfigurePage> createState() => _ConfigurePageState();
}

class _ConfigurePageState extends State<ConfigurePage> {
  var _model = ModelType.ensemble;
  var _gradCam = true;
  var _runtimeMode = ModelRuntimeMode.auto;
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFBFBFA), AppColors.page],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 190),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopBar(fallbackRoute: AppRoutes.upload),
                const AssessmentStepper(activeStep: AssessmentStep.configure),
                Text('Configure Settings',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Choose the model and visualization settings for this assessment.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                MenuAnchor(
                  controller: _menuController,
                  alignmentOffset: const Offset(0, 8),
                  style: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.98)),
                    elevation: WidgetStateProperty.all(16),
                    shadowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.12)),
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Color(0xFFDCE8F7), width: 1.5),
                      ),
                    ),
                  ),
                  menuChildren: [
                    _buildDropdownItem(
                      context: context,
                      title: 'Ensemble (5-Seed SWA)',
                      description: 'Highest reliability for field research and reporting.',
                      value: ModelType.ensemble,
                      icon: Icons.hub_rounded,
                      chips: const ['Best Accuracy', 'Robust', 'Recommended'],
                    ),
                    const Divider(height: 1, color: AppColors.line, indent: 20, endIndent: 20),
                    _buildDropdownItem(
                      context: context,
                      title: 'Base EfficientNet-B0',
                      description: 'Faster mobile inference with smaller compute footprint.',
                      value: ModelType.base,
                      icon: Icons.bolt_rounded,
                      chips: const ['Faster', 'Lightweight', 'Good Accuracy'],
                    ),
                  ],
                  builder: (context, controller, child) {
                    final isEnsemble = _model == ModelType.ensemble;
                    return GlassCard(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  isEnsemble ? Icons.hub_rounded : Icons.bolt_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Model',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isEnsemble ? 'Ensemble (5-Seed SWA)' : 'Base EfficientNet-B0',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontSize: 16,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedRotation(
                                turns: controller.isOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('Execution Mode', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SegmentedButton<ModelRuntimeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ModelRuntimeMode.auto,
                      label: Text('Auto'),
                      icon: Icon(Icons.autorenew_rounded),
                    ),
                    ButtonSegment(
                      value: ModelRuntimeMode.offline,
                      label: Text('Offline'),
                      icon: Icon(Icons.cloud_off_rounded),
                    ),
                    ButtonSegment(
                      value: ModelRuntimeMode.online,
                      label: Text('Online'),
                      icon: Icon(Icons.cloud_done_rounded),
                    ),
                  ],
                  selected: {_runtimeMode},
                  onSelectionChanged: (Set<ModelRuntimeMode> newSelection) {
                    setState(() {
                      _runtimeMode = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primarySoft;
                        }
                        return Colors.white;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/grad.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          cacheWidth: 150,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Enable Grad-CAM',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                                'Generate a heatmap showing model attention areas.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                        value: _gradCam,
                        onChanged: (value) => setState(() => _gradCam = value),
                      ),
                    ],
                  ),
                ),
                if (widget.selectedImage == null) ...[
                  const SizedBox(height: 18),
                  const StatusBadge(
                    label: 'No coral image selected. Return to upload first.',
                    color: Colors.redAccent,
                    icon: Icons.error_outline_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryActionButton(
                label: 'Run Assessment',
                onPressed: () {
                  final selectedImage = widget.selectedImage;
                  if (selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Please upload a coral image before running assessment.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                    Navigator.of(context).pushReplacementNamed(AppRoutes.upload);
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.analyze,
                    arguments: AssessmentRun(
                      image: selectedImage,
                      config: AssessmentConfig(
                        modelType: _model,
                        gradcamEnabled: _gradCam,
                        runtimeMode: _runtimeMode,
                      ),
                    ),
                  );
                },
              ),
            ),
            const CoralBottomNav(activeTab: MainTab.assess),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem({
    required BuildContext context,
    required String title,
    required String description,
    required ModelType value,
    required IconData icon,
    required List<String> chips,
  }) {
    final selected = _model == value;
    final menuWidth = MediaQuery.of(context).size.width - 48;

    return SizedBox(
      width: menuWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _model = value);
            _menuController.close();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySoft : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.muted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 15,
                              color: selected ? AppColors.primary : AppColors.ink,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final chip in chips)
                            StatusBadge(
                              label: chip,
                              color: selected ? AppColors.primary : AppColors.muted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.muted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
