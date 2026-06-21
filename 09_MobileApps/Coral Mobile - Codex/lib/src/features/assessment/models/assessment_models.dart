import '../../../shared/coral_visuals.dart';

enum ModelType {
  ensemble,
  base;

  String get requestValue => switch (this) {
        ModelType.ensemble => 'ensemble',
        ModelType.base => 'base',
      };

  String get displayName => switch (this) {
        ModelType.ensemble => 'Ensemble (5-Seed SWA)',
        ModelType.base => 'Base EfficientNet-B0',
      };
}

class SelectedCoralImage {
  const SelectedCoralImage({
    required this.fileName,
    required this.fileSize,
    required this.assessmentDate,
    required this.previewVariant,
    this.filePath,
    this.assetPath,
  }) : assert(filePath != null || assetPath != null);

  final String fileName;
  final String fileSize;
  final DateTime assessmentDate;
  final CoralVariant previewVariant;
  final String? filePath;
  final String? assetPath;

  bool get isAsset => assetPath != null;
}

enum ModelRuntimeMode {
  auto,
  online,
  offline,
}

class AssessmentConfig {
  const AssessmentConfig({
    this.modelType = ModelType.ensemble,
    this.gradcamEnabled = true,
    this.runtimeMode = ModelRuntimeMode.auto,
  });

  final ModelType modelType;
  final bool gradcamEnabled;
  final ModelRuntimeMode runtimeMode;
}

class AssessmentRun {
  const AssessmentRun({
    required this.image,
    required this.config,
  });

  final SelectedCoralImage image;
  final AssessmentConfig config;
}

class IndividualModelResult {
  const IndividualModelResult({
    required this.fold,
    required this.prediction,
    required this.confidence,
    required this.probabilities,
  });

  final int fold;
  final String prediction;
  final double confidence;
  final Map<String, double> probabilities;

  factory IndividualModelResult.fromJson(Map<String, dynamic> json) {
    return IndividualModelResult(
      fold: _asInt(json['fold']),
      prediction: json['prediction']?.toString() ?? 'Unknown',
      confidence: _asDouble(json['confidence']),
      probabilities: _mapProbabilities(json['probabilities']),
    );
  }
}

class PredictionStatus {
  const PredictionStatus({
    required this.severity,
    required this.description,
    required this.recommendation,
  });

  final String severity;
  final String description;
  final String recommendation;

  factory PredictionStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PredictionStatus(
        severity: 'Unknown',
        description: 'No status details were returned by the backend.',
        recommendation: 'Review the backend response and try again.',
      );
    }

    return PredictionStatus(
      severity: json['severity']?.toString() ?? 'Unknown',
      description: json['description']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }
}

class PredictionResult {
  const PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.probabilities,
    required this.individualModels,
    required this.status,
    required this.uncertainty,
    required this.notes,
    required this.modelUsed,
    this.isOffline = false,
    this.gradcamHeatmapBase64,
    this.gradcamOverlayBase64,
    this.gradcamError,
    this.originalImageBase64,
    this.selectedImage,
  });

  final String prediction;
  final double confidence;
  final Map<String, double> probabilities;
  final List<IndividualModelResult> individualModels;
  final PredictionStatus status;
  final bool uncertainty;
  final List<String> notes;
  final String modelUsed;
  final bool isOffline;
  final String? gradcamHeatmapBase64;
  final String? gradcamOverlayBase64;
  final String? gradcamError;
  final String? originalImageBase64;
  final SelectedCoralImage? selectedImage;

  PredictionResult copyWith({
    SelectedCoralImage? selectedImage,
    bool? isOffline,
  }) {
    return PredictionResult(
      prediction: prediction,
      confidence: confidence,
      probabilities: probabilities,
      individualModels: individualModels,
      status: status,
      uncertainty: uncertainty,
      notes: notes,
      modelUsed: modelUsed,
      isOffline: isOffline ?? this.isOffline,
      gradcamHeatmapBase64: gradcamHeatmapBase64,
      gradcamOverlayBase64: gradcamOverlayBase64,
      gradcamError: gradcamError,
      originalImageBase64: originalImageBase64,
      selectedImage: selectedImage ?? this.selectedImage,
    );
  }

  bool get hasGradcam => gradcamOverlayBase64 != null || gradcamHeatmapBase64 != null;

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final gradcam = json['gradcam'];
    final gradcamMap = gradcam is Map
        ? gradcam.map((k, v) => MapEntry(k.toString(), v))
        : null;
    final individualModels = json['individual_models'];

    return PredictionResult(
      prediction: json['prediction']?.toString() ?? 'Unknown',
      confidence: _asDouble(json['confidence']),
      probabilities: _mapProbabilities(json['probabilities']),
      individualModels: individualModels is List
          ? individualModels
              .whereType<Map>()
              .map((item) => IndividualModelResult.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ))
              .toList()
          : const [],
      gradcamHeatmapBase64: gradcamMap?['heatmap']?.toString(),
      gradcamOverlayBase64: gradcamMap?['overlay']?.toString(),
      gradcamError: gradcamMap?['error']?.toString(),
      originalImageBase64: json['original_image']?.toString(),
      status: PredictionStatus.fromJson(
        json['status'] is Map
            ? (json['status'] as Map).map((k, v) => MapEntry(k.toString(), v))
            : null,
      ),
      uncertainty: json['uncertainty'] == true,
      notes: json['notes'] is List
          ? (json['notes'] as List).map((note) => note.toString()).toList()
          : const [],
      modelUsed: json['model_used']?.toString() ?? 'Unknown model',
    );
  }
}

class PredictionError {
  const PredictionError({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Map<String, double> _mapProbabilities(Object? value) {
  if (value is! Map) return const {};

  return value.map(
    (key, mapValue) => MapEntry(key.toString(), _asDouble(mapValue)),
  );
}
