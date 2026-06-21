import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coral_health_ai/src/features/assessment/data/online_prediction_service.dart';
import 'package:coral_health_ai/src/features/assessment/models/assessment_models.dart';
import 'package:coral_health_ai/src/shared/coral_visuals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('PredictionResult parses backend predict response', () {
    final result = PredictionResult.fromJson(const {
      'prediction': 'Healthy',
      'confidence': 97.4,
      'probabilities': {
        'Healthy': 97.4,
        'Bleached': 2.3,
        'Dead': 0.3,
      },
      'individual_models': [
        {
          'fold': 42,
          'prediction': 'Healthy',
          'confidence': 96.0,
          'probabilities': {'Healthy': 96.0, 'Bleached': 3.0, 'Dead': 1.0},
        }
      ],
      'gradcam': {'heatmap': 'heatmap64', 'overlay': 'overlay64'},
      'original_image': 'original64',
      'status': {
        'severity': 'Good',
        'description': 'Coral appears healthy.',
        'recommendation': 'Maintain monitoring schedule.',
      },
      'uncertainty': false,
      'notes': ['Model agreement is high.'],
      'model_used': 'EfficientNetB0 SWA Ensemble (5-seed)',
    });

    expect(result.prediction, 'Healthy');
    expect(result.confidence, 97.4);
    expect(result.probabilities['Bleached'], 2.3);
    expect(result.individualModels.single.fold, 42);
    expect(result.gradcamOverlayBase64, 'overlay64');
    expect(result.originalImageBase64, 'original64');
    expect(result.status.severity, 'Good');
    expect(result.notes.single, 'Model agreement is high.');
  });

  test('OnlinePredictionService sends multipart predict request fields', () async {
    final tempDir = await Directory.systemTemp.createTemp('coral_predict_test');
    final imageFile = File('${tempDir.path}${Platform.pathSeparator}sample.jpg');
    await imageFile.writeAsBytes([1, 2, 3, 4]);

    final client = _CapturingClient();
    final service = OnlinePredictionService(
      backendBaseUrl: 'http://localhost:5000',
      client: client,
    );

    await service.predict(
      image: SelectedCoralImage(
        fileName: 'sample.jpg',
        fileSize: '0.1 MB',
        assessmentDate: DateTime(2026, 6, 5),
        previewVariant: CoralVariant.healthy,
        filePath: imageFile.path,
      ),
      config: const AssessmentConfig(
        modelType: ModelType.ensemble,
        gradcamEnabled: true,
      ),
    );

    final request = client.request;
    expect(request, isA<http.MultipartRequest>());
    final multipart = request as http.MultipartRequest;
    expect(multipart.method, 'POST');
    expect(multipart.url.toString(), 'http://localhost:5000/api/predict');
    expect(multipart.fields['client'], 'mobile');
    expect(multipart.fields['model_type'], 'ensemble');
    expect(multipart.fields['gradcam_enabled'], 'true');
    expect(multipart.files.single.field, 'file');
    expect(multipart.files.single.filename, 'sample.jpg');

    await tempDir.delete(recursive: true);
  });
}

class _CapturingClient extends http.BaseClient {
  late http.BaseRequest request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    final body = jsonEncode({
      'prediction': 'Healthy',
      'confidence': 97.4,
      'probabilities': {'Healthy': 97.4, 'Bleached': 2.3, 'Dead': 0.3},
      'individual_models': [],
      'gradcam': null,
      'original_image': null,
      'status': {
        'severity': 'Good',
        'description': 'Coral appears healthy.',
        'recommendation': 'Maintain monitoring schedule.',
      },
      'uncertainty': false,
      'notes': [],
      'model_used': 'EfficientNetB0 SWA Ensemble (5-seed)',
    });

    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
