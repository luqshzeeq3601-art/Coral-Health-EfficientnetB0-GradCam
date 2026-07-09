import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_theme.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/glass_card.dart';
import 'uploading_state_view.dart';

/// The main upload surface: an empty drop zone with Camera/Gallery options, an
/// in-progress uploading animation, or a preview of the selected image.
class UploadDropZone extends StatelessWidget {
  const UploadDropZone({
    super.key,
    required this.isUploading,
    required this.uploadController,
    required this.hasFile,
    required this.selectedVariant,
    this.pickedFile,
    required this.onTap,
    required this.onTapCamera,
    required this.onTapGallery,
    required this.onClear,
  });

  final bool isUploading;
  final AnimationController uploadController;
  final bool hasFile;
  final CoralVariant? selectedVariant;
  final XFile? pickedFile;
  final VoidCallback onTap;
  final VoidCallback onTapCamera;
  final VoidCallback onTapGallery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : (hasFile ? onTap : null),
      child: GlassCard(
        padding: EdgeInsets.zero,
        backgroundColor: const Color(0xFFF4FAFD),
        child: SizedBox(
          height: (MediaQuery.of(context).size.height * 0.35).clamp(300.0, 380.0),
          child: Stack(
            children: [
              if (!hasFile && !isUploading)
                const Positioned(
                  right: -18,
                  bottom: -18,
                  child: Opacity(
                    opacity: 0.14,
                    child: CoralThumbnail(
                      size: 150,
                      variant: CoralVariant.healthy,
                      showNetwork: true,
                    ),
                  ),
                ),
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasFile
                          ? [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.2)
                            ]
                          : [
                              const Color(0xFFE2F3FF),
                              const Color(0xFFEBFDF9),
                            ],
                    ),
                  ),
                ),
              ),
              if (hasFile && selectedVariant != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Transform.scale(
                            scale: 1.1,
                            child: pickedFile != null
                                ? (kIsWeb
                                    ? Image.network(
                                        pickedFile!.path,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Image.file(
                                        File(pickedFile!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        cacheWidth: 800,
                                      ))
                                : CoralThumbnail(
                                    size: double.infinity,
                                    variant: selectedVariant!,
                                    showNetwork: true,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.line),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 20),
                                onPressed: onClear,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!hasFile)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isUploading
                        ? RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: uploadController,
                              builder: (context, _) => UploadingStateView(
                                progress: uploadController.value,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Add Coral Image',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose a method to analyze your reef',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.muted,
                                      height: 1.25,
                                    ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: _UploadOptionCard(
                                      icon: Icons.camera_alt_rounded,
                                      title: 'Camera',
                                      subtitle: 'Take new photo',
                                      color: const Color(0xFF0EA5FF),
                                      onTap: onTapCamera,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _UploadOptionCard(
                                      icon: Icons.photo_library_rounded,
                                      title: 'Gallery',
                                      subtitle: 'Upload from device',
                                      color: const Color(0xFF8B5CF6),
                                      onTap: onTapGallery,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadOptionCard extends StatelessWidget {
  const _UploadOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.75),
            color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: color.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1.2,
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
