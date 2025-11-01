// ===============================
// 📦 gemini_service.dart
// -------------------------------
// Handles communication with Gemini API
// - Uses official Google Generative AI SDK
// - Central place for model config and text generation
// ===============================

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;

  // Constructor — initialize model with API key and model version
  GeminiService(String apiKey)
      : _model = GenerativeModel(
    model: 'gemini-1.5-pro', // You can change to 'gemini-1.5-flash' for faster results
    apiKey: apiKey,
  );

  /// Generate text completion for a given prompt
  Future<String> generateText(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // Return generated text or a fallback message
      return response.text ?? 'No response generated.';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
