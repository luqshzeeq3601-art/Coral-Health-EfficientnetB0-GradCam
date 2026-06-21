import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/assessment_models.dart';
import 'offline_cam_utils.dart';

class OfflinePredictionService {
  static final OfflinePredictionService _instance =
      OfflinePredictionService._internal();

  factory OfflinePredictionService() {
    return _instance;
  }

  OfflinePredictionService._internal() {
    _init();
  }

  bool _isInitialized = false;
  
  final List<Interpreter> _ensembleInterpreters = [];
  final List<IsolateInterpreter> _ensembleIsolateInterpreters = [];
  
  Interpreter? _baseInterpreter;
  IsolateInterpreter? _baseIsolateInterpreter;
  
  double _temperature = 1.0;
  Future<void>? _initFuture;

  Future<void> preload() async {
    await _init();
  }

  Future<void> _init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    if (_isInitialized) return;

    try {
      final tempStr =
          await rootBundle.loadString('assets/models/temperature.txt');
      _temperature = double.tryParse(tempStr.trim()) ?? 1.0;
    } catch (e) {
      _temperature = 0.4414; 
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${docDir.path}/tflite_models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      // Extract ensemble models and initialize IsolateInterpreters
      for (int seed = 42; seed <= 46; seed++) {
        try {
          final filePath = '${modelsDir.path}/coral_ensemble_seed$seed.tflite';
          final file = File(filePath);
          if (!await file.exists()) {
            final data = await rootBundle.load('assets/models/coral_ensemble_seed$seed.tflite');
            await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
          }
          final interpreter = Interpreter.fromFile(file);
          final isolateInterp = await IsolateInterpreter.create(address: interpreter.address);
          
          _ensembleInterpreters.add(interpreter);
          _ensembleIsolateInterpreters.add(isolateInterp);
        } catch (e) {
          debugPrint('Failed to extract/load ensemble model seed $seed: $e');
        }
      }

      // Extract base model and initialize IsolateInterpreter
      try {
        final filePath = '${modelsDir.path}/coral_base.tflite';
        final file = File(filePath);
        if (!await file.exists()) {
          final data = await rootBundle.load('assets/models/coral_base.tflite');
          await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
        }
        final interpreter = Interpreter.fromFile(file);
        final isolateInterp = await IsolateInterpreter.create(address: interpreter.address);
        
        _baseInterpreter = interpreter;
        _baseIsolateInterpreter = isolateInterp;
      } catch (e) {
        debugPrint('Failed to extract/load base model: $e');
      }
    } catch (e) {
      debugPrint('Failed to access documents directory: $e');
    }

    _isInitialized = true;
  }

  Future<PredictionResult> predict({
    required SelectedCoralImage image,
    required AssessmentConfig config,
  }) async {
    await _init();

    if (config.modelType == ModelType.ensemble && _ensembleIsolateInterpreters.isEmpty) {
      throw const PredictionServiceException(
          'No offline ensemble models could be loaded.');
    }
    if (config.modelType == ModelType.base && _baseIsolateInterpreter == null) {
      throw const PredictionServiceException(
          'Offline base model could not be loaded.');
    }

    // 1. Load image bytes
    final Uint8List imageBytes;
    if (image.filePath != null) {
      imageBytes = await File(image.filePath!).readAsBytes();
    } else if (image.assetPath != null) {
      final bytes = await rootBundle.load(image.assetPath!);
      imageBytes = bytes.buffer.asUint8List();
    } else {
      throw const PredictionServiceException('No valid image path provided.');
    }

    // 2. Preprocess image in background isolate to avoid UI lag
    final preprocessResult = await Isolate.run(() {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final resizedImage = img.copyResize(decoded,
          width: 224, height: 224, interpolation: img.Interpolation.linear);

      final inputTensor = List.generate(
        1,
        (i) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble()
              ];
            },
          ),
        ),
      );

      return {'tensor': inputTensor, 'image': resizedImage};
    });

    if (preprocessResult == null) {
      throw const PredictionServiceException('Could not decode image.');
    }

    final inputTensor = preprocessResult['tensor'] as List<List<List<List<double>>>>;
    final resizedImage = preprocessResult['image'] as img.Image;

    final models = config.modelType == ModelType.ensemble ? _ensembleInterpreters : [_baseInterpreter!];
    final isolateModels = config.modelType == ModelType.ensemble ? _ensembleIsolateInterpreters : [_baseIsolateInterpreter!];

    List<List<double>> allProbs = [];
    List<List<dynamic>> rawNestedActivations = [];
    List<IndividualModelResult> individualResults = [];
    int globalConvChannels = 1280;
    
    final labels = ['Healthy', 'Bleached', 'Dead'];

    Object createBuffer(List<int> s) {
      if (s.isEmpty) return [0.0];
      if (s.length == 1) return List.filled(s[0], 0.0);
      if (s.length == 2) return List.generate(s[0], (_) => List.filled(s[1], 0.0));
      if (s.length == 3) return List.generate(s[0], (_) => List.generate(s[1], (_) => List.filled(s[2], 0.0)));
      if (s.length == 4) return List.generate(s[0], (_) => List.generate(s[1], (_) => List.generate(s[2], (_) => List.filled(s[3], 0.0))));
      return [0.0];
    }

    // 3. Run Inference using IsolateInterpreters (safely runs C++ code in background)
    for (int i = 0; i < models.length; i++) {
      final interpreter = models[i];
      final isolateInterpreter = isolateModels[i];
      final outputTensors = interpreter.getOutputTensors();

      Map<int, Object> outputs = {};
      int denseIndex = -1;
      int convIndex = -1;

      for (int t = 0; t < outputTensors.length; t++) {
        final shape = outputTensors[t].shape;
        outputs[t] = createBuffer(shape);

        if (shape.length == 2 && shape[1] == 3) {
          denseIndex = t;
        } else if (shape.length == 4 && shape[1] == 7 && shape[2] == 7) {
          convIndex = t;
          globalConvChannels = shape[3];
        }
      }

      if (denseIndex == -1) {
        throw const PredictionServiceException('Could not find dense output in TFLite model.');
      }

      // Natively runs in background via tflite_flutter's official isolate support
      await isolateInterpreter.runForMultipleInputs([inputTensor], outputs);

      final rawProbs = (outputs[denseIndex] as List)[0] as List<double>;
      allProbs.add(rawProbs);

      if (config.gradcamEnabled && convIndex != -1) {
        // Just store the nested list. Parsing it is heavy, so we do it in a Dart isolate later.
        rawNestedActivations.add(outputs[convIndex] as List);
      }

      List<double> finalProbsForModel = rawProbs;
      if (config.modelType == ModelType.ensemble) {
        finalProbsForModel = _applyTemperatureScaling(rawProbs, _temperature);
      }

      final maxProb = finalProbsForModel.reduce((a, b) => a > b ? a : b);
      final maxIdx = finalProbsForModel.indexOf(maxProb);

      individualResults.add(
        IndividualModelResult(
          fold: i + 1,
          prediction: labels[maxIdx],
          confidence: maxProb * 100.0,
          probabilities: {
            'Healthy': finalProbsForModel[0] * 100.0,
            'Bleached': finalProbsForModel[1] * 100.0,
            'Dead': finalProbsForModel[2] * 100.0,
          },
        ),
      );
    }

    // 4. Average Probabilities
    List<double> avgProbs = List.filled(3, 0.0);
    for (int i = 0; i < models.length; i++) {
      final probs = config.modelType == ModelType.ensemble
          ? _applyTemperatureScaling(allProbs[i], _temperature)
          : allProbs[i];
      for (int c = 0; c < 3; c++) {
        avgProbs[c] += probs[c] / models.length;
      }
    }

    final maxAvgProb = avgProbs.reduce((a, b) => a > b ? a : b);
    final maxAvgIdx = avgProbs.indexOf(maxAvgProb);
    final finalPrediction = labels[maxAvgIdx];
    final isUncertain = maxAvgProb < 0.75;

    // 5. Run Heavy CAM extraction and image processing in a background Dart isolate
    final postProcessResult = await Isolate.run(() {
      String? heatmapB64;
      String? overlayB64;

      if (config.gradcamEnabled && rawNestedActivations.isNotEmpty) {
        try {
          final channels = globalConvChannels;
          const pixels = 7 * 7;
          final avgActivations = Float32List(pixels * channels);

          for (int m = 0; m < rawNestedActivations.length; m++) {
            final nestedCam = rawNestedActivations[m];
            int index = 0;
            for (int b = 0; b < 1; b++) {
              final batchList = nestedCam[b] as List;
              for (int h = 0; h < 7; h++) {
                final rowList = batchList[h] as List;
                for (int w = 0; w < 7; w++) {
                  final colList = rowList[w] as List;
                  for (int c = 0; c < channels; c++) {
                    final val = (colList[c] as num).toDouble();
                    avgActivations[index++] += val / rawNestedActivations.length;
                  }
                }
              }
            }
          }

          final heatmapData = OfflineCamUtils.computeCAM(avgActivations, 7, 7, channels);
          final heatmapImg = OfflineCamUtils.createJetHeatmap(heatmapData, 7, 224);
          final overlayImg = OfflineCamUtils.createOverlay(resizedImage, heatmapImg);

          heatmapB64 = OfflineCamUtils.encodeToBase64Png(heatmapImg);
          overlayB64 = OfflineCamUtils.encodeToBase64Png(overlayImg);
        } catch (e) {
          debugPrint('Offline CAM error: $e');
        }
      }

      return {
        'heatmap': heatmapB64,
        'overlay': overlayB64,
        'original': OfflineCamUtils.encodeToBase64Png(resizedImage),
      };
    });

    return PredictionResult(
      prediction: finalPrediction,
      confidence: maxAvgProb * 100.0,
      probabilities: {
        'Healthy': avgProbs[0] * 100.0,
        'Bleached': avgProbs[1] * 100.0,
        'Dead': avgProbs[2] * 100.0,
      },
      individualModels: individualResults,
      status: _getStatusForPrediction(finalPrediction, isUncertain),
      uncertainty: isUncertain,
      notes: ['Offline on-device inference using TFLite.'],
      modelUsed: config.modelType.displayName,
      isOffline: true,
      gradcamHeatmapBase64: postProcessResult['heatmap'],
      gradcamOverlayBase64: postProcessResult['overlay'],
      originalImageBase64: postProcessResult['original'],
      selectedImage: image,
    );
  }

  static List<double> _applyTemperatureScaling(List<double> softmaxProbs, double t) {
    if (t == 1.0) return softmaxProbs;
    List<double> logits = softmaxProbs.map<double>((p) => math.log(math.max(p, 1e-7))).toList();
    List<double> scaledLogits = logits.map<double>((l) => l / t).toList();
    double maxLogit = scaledLogits.reduce((a, b) => a > b ? a : b);
    List<double> exps = scaledLogits.map<double>((l) => math.exp(l - maxLogit)).toList();
    double sumExps = exps.reduce((a, b) => a + b);
    return exps.map<double>((e) => e / sumExps).toList();
  }

  PredictionStatus _getStatusForPrediction(String prediction, bool isUncertain) {
    if (isUncertain) {
      return const PredictionStatus(
        severity: 'Review Recommended',
        description: 'The model has low confidence. Results may be unreliable.',
        recommendation: 'Try capturing a clearer image with better lighting.',
      );
    }
    switch (prediction) {
      case 'Healthy':
        return const PredictionStatus(
          severity: 'Healthy',
          description: 'Coral tissue appears normal with rich pigmentation.',
          recommendation: 'Continue standard monitoring.',
        );
      case 'Bleached':
        return const PredictionStatus(
          severity: 'Warning',
          description: 'Coral shows signs of bleaching (loss of zooxanthellae).',
          recommendation: 'Monitor water temperature and log coordinates.',
        );
      case 'Dead':
        return const PredictionStatus(
          severity: 'Critical',
          description: 'Coral structure appears dead or covered in algae.',
          recommendation: 'Report location to reef management authorities.',
        );
      default:
        return const PredictionStatus(
          severity: 'Unknown',
          description: 'Status unknown.',
          recommendation: 'N/A',
        );
    }
  }
}

class PredictionServiceException implements Exception {
  const PredictionServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}
