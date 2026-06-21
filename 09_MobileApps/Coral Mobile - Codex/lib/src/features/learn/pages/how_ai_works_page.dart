import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/glass_card.dart';

class HowAiWorksPage extends StatelessWidget {
  const HowAiWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopBar(showSettingsButton: false),
                const SizedBox(height: 12),
                Text(
                  'How the AI Model Works',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dive into the mathematical and computational pipeline from raw underwater photo to health classification.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const _PipelineStepCard(
                  stepNumber: '01',
                  title: 'Tensor Preprocessing',
                  subtitle: 'Image Normalization & Resizing',
                  description:
                      'The raw input photograph is resized to 224x224 pixels and normalized across RGB channels using standard ImageNet mean and standard deviation matrices. This ensures uniform contrast and removes underwater lighting variance.',
                  icon: Icons.photo_size_select_large_rounded,
                  color: AppColors.cyan,
                ),
                const SizedBox(height: 16),
                const _PipelineStepCard(
                  stepNumber: '02',
                  title: 'Feature Extraction',
                  subtitle: 'EfficientNet-B0 Forward Pass',
                  description:
                      'The preprocessed image tensor passes through MBConv (Mobile Inverted Bottleneck Convolution) blocks. The model extracts deep semantic features such as coral shape, skeletal outline, tissue discoloration, and surface textures.',
                  icon: Icons.hub_rounded,
                  color: AppColors.violet,
                ),
                const SizedBox(height: 16),
                const _PipelineStepCard(
                  stepNumber: '03',
                  title: 'Attention Mapping',
                  subtitle: 'Grad-CAM Gradient Synthesis',
                  description:
                      'By backtracking gradients from the classification layer to the final convolutional feature maps, the system calculates the weighted sum of forward activation maps. This renders a visual heatmap showing where the model focused.',
                  icon: Icons.radar_rounded,
                  color: Color(0xFFF97316),
                ),
                const SizedBox(height: 16),
                const _PipelineStepCard(
                  stepNumber: '04',
                  title: 'Output Verification',
                  subtitle: 'Probability Calibration',
                  description:
                      'A final fully-connected layer outputs logits for each of the target categories (Healthy, Bleached, Dead). A Softmax function converts logits into probability scores, which must pass confidence thresholds before archiving.',
                  icon: Icons.verified_rounded,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PipelineStepCard extends StatefulWidget {
  const _PipelineStepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String stepNumber;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  @override
  State<_PipelineStepCard> createState() => _PipelineStepCardState();
}

class _PipelineStepCardState extends State<_PipelineStepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'STEP ${widget.stepNumber}',
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}
