import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';

enum AssessmentStep { upload, configure, analyze, result }

class AssessmentStepper extends StatelessWidget {
  const AssessmentStepper({required this.activeStep, super.key});

  final AssessmentStep activeStep;

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepMeta(AssessmentStep.upload, Icons.cloud_upload_rounded, 'Upload', AppRoutes.upload),
      _StepMeta(AssessmentStep.configure, Icons.tune_rounded, 'Configure', AppRoutes.configure),
      _StepMeta(AssessmentStep.analyze, Icons.psychology_rounded, 'Analyze', AppRoutes.analyze),
      _StepMeta(AssessmentStep.result, Icons.check_rounded, 'Result', AppRoutes.result),
    ];
    final activeIndex = steps.indexWhere((step) => step.step == activeStep);
    final isClickable = activeStep != AssessmentStep.result && activeStep != AssessmentStep.analyze;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _StepItem(
                meta: steps[index],
                isActive: index == activeIndex,
                isDone: index < activeIndex,
                isClickable: isClickable,
              ),
            ),
            if (index != steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30), // Vertically centers with the 62px circle container
                  child: Hero(
                    tag: 'step_line_$index',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        color: index < activeIndex
                            ? AppColors.green
                            : AppColors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.meta,
    required this.isActive,
    required this.isDone,
    required this.isClickable,
  });

  final _StepMeta meta;
  final bool isActive;
  final bool isDone;
  final bool isClickable;

  @override
  Widget build(BuildContext context) {
    final active = isActive || isDone;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: (isClickable && !isActive)
          ? () => Navigator.of(context).pushReplacementNamed(meta.route)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 62,
              child: Center(
                child: Hero(
                  tag: 'step_circle_${meta.label}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: isActive ? 60 : 52,
                    height: isActive ? 60 : 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : isDone
                                ? AppColors.green.withValues(alpha: 0.08)
                                : Colors.transparent,
                        width: isActive ? 3 : 1.5,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDone
                            ? const LinearGradient(
                                colors: [Color(0xFF16B979), Color(0xFF0F9662)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : isActive
                                ? const LinearGradient(
                                    colors: [AppColors.primary, AppColors.cyan],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Colors.white, Color(0xFFF1F6FB)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                        border: Border.all(
                          color: isDone
                              ? AppColors.green.withValues(alpha: 0.4)
                              : isActive
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.line,
                          width: 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : isDone
                                ? [
                                    BoxShadow(
                                      color: AppColors.green.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.015),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isDone ? Icons.check_rounded : meta.icon,
                            key: ValueKey(isDone),
                            color: active ? Colors.white : AppColors.muted,
                            size: isActive ? 24 : 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Hero(
              tag: 'step_label_${meta.label}',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  meta.label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : isDone
                            ? AppColors.green
                            : AppColors.muted,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.15,
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

class _StepMeta {
  const _StepMeta(this.step, this.icon, this.label, this.route);

  final AssessmentStep step;
  final IconData icon;
  final String label;
  final String route;
}

