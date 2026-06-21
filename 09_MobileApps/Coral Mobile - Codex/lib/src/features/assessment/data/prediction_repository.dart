import 'dart:async';

import '../../../core/settings_store.dart';
import '../models/assessment_models.dart';
import 'offline_prediction_service.dart' hide PredictionServiceException;
import 'online_prediction_service.dart';

class PredictionRepository {
  PredictionRepository({
    SettingsStore? settingsStore,
  }) : _settingsStore = settingsStore ?? SettingsStore();

  final SettingsStore _settingsStore;

  Future<PredictionResult> runPrediction(AssessmentRun run) async {
    final mode = run.config.runtimeMode;
    
    if (mode == ModelRuntimeMode.offline) {
      return _runOffline(run);
    } else if (mode == ModelRuntimeMode.online) {
      return _runOnline(run);
    } else {
      // Auto: Try online, fallback to offline
      try {
        return await _runOnline(run);
      } catch (e) {
        // Fallback
        return _runOffline(run);
      }
    }
  }

  Future<PredictionResult> _runOffline(AssessmentRun run) async {
    try {
      final service = OfflinePredictionService();
      return await service.predict(
        image: run.image,
        config: run.config,
      );
    } catch (error) {
      throw PredictionFailure(
        PredictionError(message: 'Offline prediction failed: $error'),
      );
    }
  }

  Future<PredictionResult> _runOnline(AssessmentRun run) async {
    try {
      final backendUrl = await _settingsStore.getBackendUrl();
      final service = OnlinePredictionService(
        backendBaseUrl: SettingsStore.normalizeBackendUrl(backendUrl),
      );

      final result = await service.predict(
        image: run.image,
        config: run.config,
      );
      return result.copyWith(selectedImage: run.image);
    } on TimeoutException {
      throw const PredictionFailure(
        PredictionError(message: 'Prediction timed out. Try disabling Grad-CAM or retrying when the backend is idle.'),
      );
    } on PredictionServiceException catch (error) {
      throw PredictionFailure(
        PredictionError(
          message: error.message,
          statusCode: error.statusCode,
        ),
      );
    } catch (error, stack) {
      print('Online prediction error: $error\n$stack');
      throw PredictionFailure(
        PredictionError(message: 'Could not reach the prediction backend: $error'),
      );
    }
  }
}

class PredictionFailure implements Exception {
  const PredictionFailure(this.error);

  final PredictionError error;
}
