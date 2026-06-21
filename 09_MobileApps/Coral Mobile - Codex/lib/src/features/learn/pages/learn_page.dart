import 'package:flutter/material.dart';

import '../../../core/app_assets.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/glass_card.dart';
import '../../../shared/tab_page_scaffold.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPageScaffold(
      activeTab: MainTab.learn,
      children: [
        const _LearnHero(),
        const SizedBox(height: 22),
        _LearnCard(
          title: 'How AI Works',
          description:
              'Understand image preprocessing, feature extraction, and confidence scoring.',
          icon: Icons.psychology_alt_outlined,
          variant: CoralVariant.healthy,
          large: true,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.learnHowAiWorks),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _LearnCard(
                title: 'Core Technology',
                description:
                    'Explore EfficientNet-B0, SWA ensemble, and Grad-CAM.',
                icon: Icons.memory_rounded,
                variant: CoralVariant.purple,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.learnCoreTech),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _LearnCard(
                title: '3D Attention Viewer',
                description:
                    'Visualize model focus areas using interactive heatmaps.',
                icon: Icons.view_in_ar_rounded,
                variant: CoralVariant.healthy,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.learnAttentionViewer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LearnCard(
          title: 'About Project & Mission',
          description:
              'Connect model performance to reef conservation and restoration goals.',
          icon: Icons.volunteer_activism_outlined,
          variant: CoralVariant.bleached,
          large: true,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.learnAboutProject),
        ),
      ],
    );
  }
}

class _LearnHero extends StatelessWidget {
  const _LearnHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: const Image(
                image: AssetImage(AppAssets.homeHeroBackground),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xF7F7FBFF),
                    Color(0xBDF7FBFF),
                    Color(0x44F7FBFF)
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn & Explore',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 260,
                  child: Text(
                    'Dive into the science and technology powering Coral Health AI.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.variant,
    required this.onTap,
    this.large = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final CoralVariant variant;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      backgroundColor: const Color(0xFFEAF7FF),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: large ? 224 : 236,
          child: Stack(
            children: [
              Positioned(
                right: -28,
                bottom: -32,
                child: Opacity(
                  opacity: 0.18,
                  child: CoralThumbnail(
                    size: large ? 180 : 122,
                    variant: variant,
                    showNetwork: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x182362A7),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        description,
                        maxLines: large ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
