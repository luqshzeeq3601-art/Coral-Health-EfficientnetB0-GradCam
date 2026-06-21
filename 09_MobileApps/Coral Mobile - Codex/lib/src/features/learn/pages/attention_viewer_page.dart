import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/glass_card.dart';

class AttentionViewerPage extends StatefulWidget {
  const AttentionViewerPage({super.key});

  @override
  State<AttentionViewerPage> createState() => _AttentionViewerPageState();
}

class _AttentionViewerPageState extends State<AttentionViewerPage> {
  int _activeLayer = 0;
  bool _showMath = false;

  final List<String> _layers = [
    'Conv2d_1a (Input Stem)',
    'MBConv Block 3 (Mid Features)',
    'MBConv Block 6 (Late Features)',
    'Conv2d_7b (Final Feature Map)',
  ];

  final List<String> _descriptions = [
    'Highlights low-level edges, shadows, and water-coral boundaries. High frequency activations, but low semantic specificity.',
    'Isolates coral branch shapes, contours, and texture distributions. Balances spatial resolution and feature abstraction.',
    'Focuses heavily on color deviations, surface tissue whitening, and skeletal fragmentation patterns.',
    'The final deep activation map. Yields highest class semantic activations, representing final Grad-CAM attention weights.',
  ];

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
                  'Attention Map Viewer',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Visualize neural weights across different processing resolutions and toggle gradient equations.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Viewport Area
                      Container(
                        height: 220,
                        width: double.infinity,
                        color: const Color(0xFF0F172A),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: 0.85,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/bleached_coral.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (c, e, s) => Container(
                                    color: const Color(0xFF1E293B),
                                    child: const Center(
                                      child: Icon(Icons.waves_rounded,
                                          color: AppColors.cyan, size: 68),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Simulated Heatmap overlay matching step
                            Opacity(
                              opacity: 0.55 + (_activeLayer * 0.1),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.4 + (_activeLayer * 0.15),
                                    colors: const [
                                      Colors.red,
                                      Colors.yellow,
                                      Colors.blue,
                                      Colors.transparent
                                    ],
                                    stops: const [0.0, 0.4, 0.75, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Layer: ${_layers[_activeLayer]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Layer Explanation',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _descriptions[_activeLayer],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Model Resolution Layer',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Column(
                  children: List.generate(_layers.length, (index) {
                    final active = _activeLayer == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _activeLayer = index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primarySoft
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  active ? AppColors.primary : AppColors.line,
                              width: active ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.muted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _layers[index],
                                  style: TextStyle(
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Formal Gradient Formula',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Switch(
                            value: _showMath,
                            onChanged: (val) => setState(() => _showMath = val),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'L^c_GradCAM = ReLU( Σ_k α^c_k A^k )\n\nwhere: α^c_k = (1/Z) * Σ_i Σ_j ( ∂Y^c / ∂A^k_ij )',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: AppColors.ink,
                                height: 1.45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        crossFadeState: _showMath
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
