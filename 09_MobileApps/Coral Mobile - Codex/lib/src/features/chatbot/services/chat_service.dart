import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/settings_store.dart';
import '../../assessment/models/assessment_models.dart';

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class ChatService {
  final SettingsStore _settings = SettingsStore();

  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
    PredictionResult? predictionContext,
  }) async {
    try {
      final backendUrl = await _settings.getBackendUrl();
      final uri = Uri.parse('$backendUrl/api/chat');

      Map<String, dynamic>? contextData;
      if (predictionContext != null) {
        contextData = {
          'prediction': predictionContext.prediction,
          'confidence': predictionContext.confidence,
          'probabilities': predictionContext.probabilities,
          'uncertainty': predictionContext.uncertainty,
          'notes': predictionContext.notes,
        };
      }

      final payload = {
        'message': message,
        'history': history.map((msg) => msg.toJson()).toList(),
        if (contextData != null) 'predictionContext': contextData,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply']?.toString() ?? 'Sorry, I received an empty response.';
      } else {
        return 'Server error (${response.statusCode}). Please check if the local AI server is running.';
      }
    } catch (e) {
      return 'Failed to connect to the AI server. Ensure Ollama and the Flask backend are running locally.\nError: $e';
    }
  }
}
