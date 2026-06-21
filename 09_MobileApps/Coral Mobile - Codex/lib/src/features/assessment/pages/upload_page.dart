import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_assets.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../models/assessment_models.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/assessment_stepper.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
import '../../../shared/glass_card.dart';
import '../../../shared/primary_action_button.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage>
    with SingleTickerProviderStateMixin {
  bool _isUploading = false;
  bool _hasFile = false;
  DateTime _assessmentDate = DateTime.now();

  String? _fileName;
  String? _fileSize;
  CoralVariant? _selectedVariant;
  XFile? _pickedFile;
  SelectedCoralImage? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Performance: replaced Timer.periodic + setState (20 calls/sec) with
  // AnimationController — rebuilds only the progress widget via AnimatedBuilder.
  late final AnimationController _uploadController;

  @override
  void initState() {
    super.initState();
    _uploadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _uploadController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Upload simulation finished — update state once
        _onUploadComplete();
      }
    });
  }

  @override
  void dispose() {
    _uploadController.dispose();
    super.dispose();
  }

  // Completion callback parameters — set before animation starts
  String? _pendingName;
  String? _pendingSize;
  CoralVariant? _pendingVariant;
  String? _pendingAssetPath;
  String? _pendingFilePath;
  XFile? _pendingFile;

  void _startUploading(
    String name,
    String size,
    CoralVariant variant, {
    required String assetPath,
  }) {
    _pendingName = name;
    _pendingSize = size;
    _pendingVariant = variant;
    _pendingAssetPath = assetPath;
    _pendingFilePath = null;
    _pendingFile = null;
    setState(() {
      _isUploading = true;
      _hasFile = false;
    });
    _uploadController
      ..reset()
      ..forward();
  }

  void _onUploadComplete() {
    setState(() {
      _isUploading = false;
      _hasFile = true;
      _fileName = _pendingName;
      _fileSize = _pendingSize;
      _selectedVariant = _pendingVariant;
      _pickedFile = _pendingFile;
      if (_pendingFilePath != null) {
        _selectedImage = SelectedCoralImage(
          fileName: _pendingName!,
          fileSize: _pendingSize!,
          assessmentDate: _assessmentDate,
          previewVariant: _pendingVariant!,
          filePath: _pendingFilePath,
        );
      } else {
        _selectedImage = SelectedCoralImage(
          fileName: _pendingName!,
          fileSize: _pendingSize!,
          assessmentDate: _assessmentDate,
          previewVariant: _pendingVariant!,
          assetPath: _pendingAssetPath,
        );
      }
    });
  }

  void _clearSelectedFile() {
    _uploadController.reset();
    setState(() {
      _hasFile = false;
      _fileName = null;
      _fileSize = null;
      _selectedVariant = null;
      _pickedFile = null;
      _selectedImage = null;
    });
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        _startUploadMock(photo);
      }
    } catch (e) {
      // Handle error or cancellation silently
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        _startUploadMock(image);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _startUploadMock(XFile file) async {
    final bytes = await file.length();
    final fileSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    
    var name = file.name;
    if (name.length > 20) {
      name = name.substring(name.length - 20);
    }

    _pendingName = name;
    _pendingSize = fileSize;
    _pendingVariant = CoralVariant.healthy;
    _pendingAssetPath = null;
    _pendingFilePath = file.path;
    _pendingFile = file;

    setState(() {
      _isUploading = true;
      _hasFile = false;
    });
    _uploadController
      ..reset()
      ..forward();
  }

  Future<void> _pickAssessmentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _assessmentDate,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: 'Select assessment date',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.ink,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _assessmentDate = picked;
        final selectedImage = _selectedImage;
        if (selectedImage != null) {
          _selectedImage = SelectedCoralImage(
            fileName: selectedImage.fileName,
            fileSize: selectedImage.fileSize,
            assessmentDate: picked,
            previewVariant: selectedImage.previewVariant,
            filePath: selectedImage.filePath,
            assetPath: selectedImage.assetPath,
          );
        }
      });
    }
  }

  void _showPresetPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Coral Sample',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a sample image to simulate a high-resolution field upload.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _PresetTile(
                        title: 'Healthy Acropora',
                        size: '4.8 MB',
                        variant: CoralVariant.healthy,
                        onTap: () {
                          Navigator.pop(context);
                          _startUploading('healthy_acropora.jpg', '4.8 MB',
                              CoralVariant.healthy,
                              assetPath: AppAssets.healthyCoral);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _PresetTile(
                        title: 'Bleached Reef',
                        size: '5.1 MB',
                        variant: CoralVariant.bleached,
                        onTap: () {
                          Navigator.pop(context);
                          _startUploading('bleached_reef_04.jpg', '5.1 MB',
                              CoralVariant.bleached,
                              assetPath: AppAssets.bleachedCoral);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PresetTile(
                        title: 'Dead Coral',
                        size: '3.2 MB',
                        variant: CoralVariant.dead,
                        onTap: () {
                          Navigator.pop(context);
                          _startUploading('dead_micro_structure.jpg', '3.2 MB',
                              CoralVariant.dead,
                              assetPath: AppAssets.deadCoral);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _PresetTile(
                        title: 'Purple Stylophora',
                        size: '4.4 MB',
                        variant: CoralVariant.purple,
                        onTap: () {
                          Navigator.pop(context);
                          _startUploading('purple_stylophora.jpg', '4.4 MB',
                              CoralVariant.purple,
                              assetPath: AppAssets.purpleCoral);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

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
            colors: [Color(0xFFFFFFFF), Color(0xFFFBFBFA), AppColors.page],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 190),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopBar(fallbackRoute: AppRoutes.home),
                const AssessmentStepper(activeStep: AssessmentStep.upload),
                _AssessmentDateCard(
                  date: _assessmentDate,
                  onTap: _pickAssessmentDate,
                ),
                const SizedBox(height: 14),
                UploadDropZone(
                  isUploading: _isUploading,
                  uploadController: _uploadController,
                  hasFile: _hasFile,
                  selectedVariant: _selectedVariant,
                  pickedFile: _pickedFile,
                  onTap: () => _showPresetPicker(context),
                  onTapCamera: _pickFromCamera,
                  onTapGallery: _pickFromGallery,
                  onClear: _clearSelectedFile,
                ),
                const SizedBox(height: 20),
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
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hasFile ? 1.0 : 0.5,
                child: PrimaryActionButton(
                  label: 'Continue',
                  onPressed: _hasFile
                      ? () {
                          if (_selectedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Please select a valid coral image first.'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.configure,
                            arguments: _selectedImage,
                          );
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Please upload a coral image first!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                ),
              ),
            ),
            const CoralBottomNav(activeTab: MainTab.assess),
          ],
        ),
      ),
    );
  }
}

class _AssessmentDateCard extends StatelessWidget {
  const _AssessmentDateCard({
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assessment Date',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAssessmentDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                        ? AnimatedBuilder(
                            animation: uploadController,
                            builder: (context, _) => UploadingStateView(
                              progress: uploadController.value,
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

String _formatAssessmentDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.title,
    required this.size,
    required this.variant,
    required this.onTap,
  });

  final String title;
  final String size;
  final CoralVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.muted.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CoralThumbnail(
              size: 72,
              variant: variant,
              showNetwork: true,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              size,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadingStateView extends StatefulWidget {
  final double progress;
  const UploadingStateView({super.key, required this.progress});

  @override
  State<UploadingStateView> createState() => _UploadingStateViewState();
}

class _UploadingStateViewState extends State<UploadingStateView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 130 + (_pulseController.value * 20),
                    height: 130 + (_pulseController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12 - (_pulseController.value * 0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 10 + (_pulseController.value * 15),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Rotating dashed ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * math.pi * 2,
                    child: CustomPaint(
                      size: const Size(130, 130),
                      painter: _DashedRingPainter(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        strokeWidth: 1.5,
                        dashLength: 6,
                        dashSpace: 8,
                      ),
                    ),
                  );
                },
              ),
              
              // Core progress ring
              SizedBox(
                width: 110,
                height: 110,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _RefinedProgressPainter(
                        progress: value,
                        gradientColors: [AppColors.cyan, AppColors.primary, const Color(0xFF6366F1)],
                      ),
                    );
                  },
                ),
              ),
              
              // Inner content
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.progress),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).toInt()}',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 28,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const Text(
                            '%',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _RefinedUploadingText(),

      ],
    );
  }
}

class _RefinedUploadingText extends StatefulWidget {
  const _RefinedUploadingText();

  @override
  State<_RefinedUploadingText> createState() => _RefinedUploadingTextState();
}

class _RefinedUploadingTextState extends State<_RefinedUploadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
      
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.ink,
                AppColors.ink,
                AppColors.primary,
                AppColors.cyan,
                AppColors.ink,
                AppColors.ink,
              ],
              stops: [
                0.0,
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value - 0.1,
                _shimmerAnimation.value + 0.1,
                _shimmerAnimation.value + 0.3,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'Uploading Specimen',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white, // Masked by shader
            ),
          ),
        );
      },
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + dashSpace)).floor();
    final actualDashSpace = (circumference - (dashCount * dashLength)) / dashCount;
    final sweepAngle = dashLength / radius;
    final spaceAngle = actualDashSpace / radius;

    double currentAngle = 0;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle + spaceAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}

class _RefinedProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  _RefinedProgressPainter({
    required this.progress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;

    // Subtle track
    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweepGradient = SweepGradient(
      colors: gradientColors,
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 2 * progress;

    // Draw inner glow
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, glowPaint);
    // Draw solid progress
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, progressPaint);

    // Glowing dot at the end for an illuminated high-tech look
    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final dotGlowPaint = Paint()
      ..color = gradientColors.last.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(dotCenter, strokeWidth, dotGlowPaint);
    canvas.drawCircle(dotCenter, strokeWidth - 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RefinedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
