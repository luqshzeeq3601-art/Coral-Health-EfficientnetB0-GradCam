import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_assets.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../models/assessment_models.dart';
import '../widgets/upload_drop_zone.dart';
import '../../../shared/app_top_bar.dart';
import '../../../shared/assessment_stepper.dart';
import '../../../shared/bottom_nav.dart';
import '../../../shared/coral_visuals.dart';
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

  // Hard cap on accepted image size. image_picker already downscales picks to
  // <=1920px @ q70, so anything materially larger is abnormal — reject it
  // rather than risk an out-of-memory decode during analysis.
  static const int _maxUploadBytes = 12 * 1024 * 1024; // 12 MB

  void _startUploadMock(XFile file) async {
    final bytes = await file.length();

    if (!mounted) return;
    if (bytes <= 0 || bytes > _maxUploadBytes) {
      final maxMb = (_maxUploadBytes / (1024 * 1024)).round();
      final actualMb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bytes <= 0
                ? 'That image could not be read. Please choose another.'
                : 'Image is too large ($actualMb MB). Choose one under $maxMb MB.',
          ),
        ),
      );
      return;
    }

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
