import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/assessment_models.dart';
import 'circuit_breaker.dart';

/// Creates an [http.Client] with extended idle/connection timeouts so that
/// long-running ensemble predictions don't get killed by the default 15-second
/// idle timeout of Dart's `HttpClient`.
http.Client _createRobustClient() {
  if (kIsWeb) return http.Client();
  final inner = HttpClient()
    ..idleTimeout = const Duration(seconds: 180)
    ..connectionTimeout = const Duration(seconds: 30);
  return IOClient(inner);
}

class OnlinePredictionService {
  OnlinePredictionService({
    required String backendBaseUrl,
    http.Client? client,
    AssetBundle? assetBundle,
    CircuitBreaker? circuitBreaker,
  })  : _backendBaseUrl = backendBaseUrl,
        _client = client ?? _createRobustClient(),
        _assetBundle = assetBundle ?? rootBundle,
        _breaker = circuitBreaker ?? _sharedBreaker;

  /// Shared across the per-request service instances so failure state persists
  /// between calls. Tests can inject their own via [circuitBreaker].
  static final CircuitBreaker _sharedBreaker = CircuitBreaker();

  final String _backendBaseUrl;
  final http.Client _client;
  final AssetBundle _assetBundle;
  final CircuitBreaker _breaker;

  Uri _uri(String path) => Uri.parse('$_backendBaseUrl$path');

  Future<Map<String, dynamic>> health({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _client.get(
      _uri('/api/health'),
    ).timeout(timeout);
    final body = _decodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PredictionServiceException(
        body['error']?.toString() ?? 'Backend health check failed.',
        statusCode: response.statusCode,
      );
    }
    return body;
  }

  Future<PredictionResult> predict({
    required SelectedCoralImage image,
    required AssessmentConfig config,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    // Fail fast if the backend has been unreachable: queuing another request
    // that will just time out is exactly what freezes the flow.
    if (_breaker.isOpen) {
      throw PredictionServiceException(
        'Backend unreachable after repeated failures. Retry in '
        '${_breaker.remainingCooldown.inSeconds}s or switch to offline mode.',
      );
    }

    // Allow one automatic retry for transient connection errors (e.g. socket
    // closed by the emulator's virtual network adapter during a long inference).
    const maxAttempts = 2;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result =
            await _sendPrediction(image: image, config: config, timeout: timeout);
        _breaker.recordSuccess();
        return result;
      } on PredictionServiceException {
        // The backend responded (non-2xx with an error body). It is reachable,
        // so keep the circuit closed and surface the error to the caller.
        _breaker.recordSuccess();
        rethrow;
      } catch (e) {
        // No response: timeout / socket / client error — the failures the
        // breaker exists to short-circuit.
        final isTransient = e is http.ClientException || e is SocketException;
        if (attempt < maxAttempts && isTransient) {
          debugPrint('[OnlinePredictionService] Attempt $attempt failed ($e), retrying…');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        _breaker.recordFailure();
        rethrow;
      }
    }

    // Unreachable, but the compiler can't prove the loop always returns/throws.
    throw const PredictionServiceException('Prediction failed after retries.');
  }

  Future<PredictionResult> _sendPrediction({
    required SelectedCoralImage image,
    required AssessmentConfig config,
    required Duration timeout,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/predict'))
      ..fields['client'] = 'mobile'
      ..fields['model_type'] = config.modelType.requestValue
      ..fields['gradcam_enabled'] = config.gradcamEnabled.toString();

    if (image.filePath != null) {
      if (kIsWeb) {
        final fileResponse = await http.get(Uri.parse(image.filePath!));
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileResponse.bodyBytes,
            filename: image.fileName,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.filePath!,
            filename: image.fileName,
          ),
        );
      }
    } else {
      final bytes = await _assetBundle.load(image.assetPath!);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes.buffer.asUint8List(),
          filename: image.fileName,
        ),
      );
    }

    final streamedResponse = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 60));
    final body = _decodeJson(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PredictionServiceException(
        body['error']?.toString() ?? 'Prediction request failed.',
        statusCode: response.statusCode,
      );
    }

    if (body.containsKey('error')) {
      throw PredictionServiceException(body['error']?.toString() ?? 'Prediction failed.');
    }

    return PredictionResult.fromJson(body);
  }
}

class PredictionServiceException implements Exception {
  const PredictionServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Map<String, dynamic> _decodeJson(String source) {
  final decoded = jsonDecode(source);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
