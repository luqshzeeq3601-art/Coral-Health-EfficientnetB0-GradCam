import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/glass_card.dart';

class CoreTechPage extends StatelessWidget {
  const CoreTechPage({super.key});

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
                  'Core Technology Pillars',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn about the models, pooling strategies, and interpretability frameworks behind Coral Health AI.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const _TechPillarCard(
                  title: 'EfficientNet-B0',
                  role: 'Feature Extractor Backbone',
                  description:
                      'EfficientNet-B0 serves as the primary convolutional backbone. It uses compound scaling to balance depth, width, and resolution. This yields extreme parameter efficiency (only ~5.3M parameters), making it perfect for real-time mobile and browser execution in the field without sacrificing diagnostic accuracy.',
                  icon: Icons.memory_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const _TechPillarCard(
                  title: '5-Seed SWA Ensemble',
                  role: 'Stochastic Weight Averaging',
                  description:
                      'Stochastic Weight Averaging (SWA) averages weights of the neural network during multiple epochs using a cyclical learning rate. By combining 5 distinct seed checkpoints, our ensemble smooths out loss landscapes. This provides robust generalization against underwater perturbations, scattering, and color shifts.',
                  icon: Icons.hub_rounded,
                  color: AppColors.violet,
                ),
                const SizedBox(height: 16),
                const _TechPillarCard(
                  title: 'Grad-CAM Interpretability',
                  role: 'Attention Heatmap Extraction',
                  description:
                      'Gradient-weighted Class Activation Mapping (Grad-CAM) extracts spatial importance weights. By computing gradients of output logits with respect to final convolution layer activation maps, it highlights exactly which reef sections led to classification outcomes, ensuring field operators can trust the prediction.',
                  icon: Icons.radar_rounded,
                  color: Color(0xFF0EA5FF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TechPillarCard extends StatelessWidget {
  const _TechPillarCard({
    required this.title,
    required this.role,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String role;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
