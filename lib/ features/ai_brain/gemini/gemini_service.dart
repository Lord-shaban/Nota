// gemini_service.dart
// ------------------------------------------------------------
// Path: lib/components/ai_brain/gemini/gemini_service.dart
// Handles Gemini API integration with mock fallback for testing
// Manages AI text generation and response parsing
// Created by Student 4
// ------------------------------------------------------------

import 'dart:convert';
import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_prompts.dart';
import '../models/ai_models.dart';

/// Main service for Gemini AI integration
/// Supports both real API calls and mock responses for development
class GeminiService {
  final GenerativeModel? _model;
  final bool _useMockData;
  final Random _random = Random();

  // ════════════════════════════════════════════════════════════
  // 🔧 INITIALIZATION
  // ════════════════════════════════════════════════════════════

  /// Constructor - Initialize with API key or use mock mode
  ///
  /// Parameters:
  /// - apiKey: Your Gemini API key (get from Google AI Studio)
  /// - useMockData: Set to true for testing without API calls
  ///
  /// Example:
  /// ```dart
  /// // Real API mode
  /// final service = GeminiService('your-api-key-here');
  ///
  /// // Mock mode for testing
  /// final service = GeminiService('', useMockData: true);
  /// ```
  GeminiService(String apiKey, {bool useMockData = false})
      : _useMockData = useMockData,
        _model = useMockData
            ? null
            : GenerativeModel(
          model: 'gemini-1.5-pro', // Or 'gemini-1.5-flash' for faster results
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7, // Creativity level (0.0-1.0)
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          ),
        );

  // ════════════════════════════════════════════════════════════
  // 🎯 MAIN API METHODS
  // ════════════════════════════════════════════════════════════

  /// Generate text response from Gemini AI
  ///
  /// This is the core method that sends prompts to Gemini
  /// Falls back to mock data if useMockData is true
  Future<String> generateText(String prompt) async {
    if (_useMockData) {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
      return _getMockResponse(prompt);
    }

    try {
      if (_model == null) {
        throw Exception('Gemini model not initialized. Check API key.');
      }

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'No response generated.';
    } catch (e) {
      // Log error for debugging
      print('❌ Gemini API Error: $e');
      return 'Error: $e';
    }
  }

  /// Generate text with streaming (real-time response)
  ///
  /// Useful for showing AI "thinking" animation to users
  Stream<String> generateTextStream(String prompt) async* {
    if (_useMockData) {
      await Future.delayed(Duration(milliseconds: 500));
      yield _getMockResponse(prompt);
      return;
    }

    try {
      if (_model == null) {
        throw Exception('Gemini model not initialized.');
      }

      final content = [Content.text(prompt)];
      final stream = _model.generateContentStream(content);

      await for (final chunk in stream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  // ════════════════════════════════════════════════════════════
  // 📊 CATEGORIZATION METHODS
  // ════════════════════════════════════════════════════════════

  /// Categorize user input and return structured result
  ///
  /// This combines the prompt from GeminiPrompts with AI analysis
  /// Returns a parsed CategoryResult object
  Future<CategoryResult> categorizeContent(String userInput) async {
    if (_useMockData) {
      return _getMockCategoryResult(userInput);
    }

    try {
      final prompt = GeminiPrompts.buildPrompt(
        GeminiPrompts.categorizeContent,
        userInput,
      );

      final response = await generateText(prompt);
      return _parseCategoryResponse(response, userInput);
    } catch (e) {
      print('❌ Categorization Error: $e');
      // Fallback to basic categorization
      return CategoryResult(
        category: 'note',
        confidence: 50.0,
        originalText: userInput,
        reason: 'Fallback due to error',
      );
    }
  }

  /// Extract detailed information based on category
  ///
  /// After categorization, this extracts specific fields
  /// (e.g., amount for expenses, time for appointments)
  Future<Map<String, dynamic>> extractDetails({
    required String category,
    required String userInput,
  }) async {
    if (_useMockData) {
      return _getMockExtractedDetails(category, userInput);
    }

    try {
      final prompt = GeminiPrompts.buildExtractionPrompt(category, userInput);
      final response = await generateText(prompt);
      return _parseJsonResponse(response);
    } catch (e) {
      print('❌ Extraction Error: $e');
      return {};
    }
  }

  /// Process voice input (clean transcription)
  Future<String> processVoiceInput(String transcription) async {
    final prompt = GeminiPrompts.buildPrompt(
      GeminiPrompts.processVoiceInput,
      transcription,
    );
    return await generateText(prompt);
  }

  /// Process image text (OCR cleanup)
  Future<String> processImageText(String extractedText) async {
    final prompt = GeminiPrompts.buildPrompt(
      GeminiPrompts.processImageText,
      extractedText,
    );
    return await generateText(prompt);
  }

  /// Generate smart suggestions based on content
  Future<List<ActionSuggestion>> getSuggestions(String content) async {
    if (_useMockData) {
      return _getMockSuggestions(content);
    }

    try {
      final prompt = GeminiPrompts.buildPrompt(
        GeminiPrompts.suggestActions,
        content,
      );
      final response = await generateText(prompt);
      final json = _parseJsonResponse(response);

      if (json['suggestions'] is List) {
        return (json['suggestions'] as List)
            .map((s) => ActionSuggestion.fromJson(s))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Suggestions Error: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🎯 MULTI-ITEM EXTRACTION (ALNOTA FEATURE)
  // ════════════════════════════════════════════════════════════

  /// Extract multiple items from single input
  ///
  /// This is inspired by alNota's ability to extract multiple
  /// tasks, appointments, or expenses from a single text input.
  ///
  /// Example:
  /// "اشتري لبن وخبز وجبنة" → 3 separate todo items
  /// "عندي اجتماع الساعة 2 وموعد مع دكتور الساعة 5" → 2 appointments
  Future<List<Map<String, dynamic>>> extractMultipleItems(String userInput) async {
    if (_useMockData) {
      return _getMockMultipleItems(userInput);
    }

    try {
      final prompt = GeminiPrompts.buildPrompt(
        GeminiPrompts.extractMultipleItems,
        userInput,
      );

      final response = await generateText(prompt);
      final json = _parseJsonResponse(response);

      if (json['items'] is List) {
        return (json['items'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Multi-Item Extraction Error: $e');
      return [];
    }
  }

  /// Smart categorization with confidence scoring
  ///
  /// Enhanced version that provides more detailed analysis
  /// including secondary category suggestions and reasoning
  Future<Map<String, dynamic>> smartCategorize(String userInput) async {
    if (_useMockData) {
      return _getMockSmartCategorization(userInput);
    }

    try {
      final prompt = '''
قم بتحليل النص التالي وتصنيفه بذكاء:

النص: "$userInput"

أعد JSON يحتوي على:
1. category: التصنيف الأساسي (todo/appointment/expense/quote/note)
2. confidence: نسبة الثقة (0-100)
3. secondaryCategory: تصنيف ثانوي محتمل (أو null)
4. secondaryConfidence: نسبة ثقة التصنيف الثانوي
5. keywords: كلمات مفتاحية تم اكتشافها
6. sentiment: المشاعر (positive/negative/neutral)
7. urgency: مستوى الأهمية (low/medium/high/urgent)
8. reason: سبب التصنيف
9. suggestedTags: تاجات مقترحة

مثال:
{
  "category": "todo",
  "confidence": 95,
  "secondaryCategory": "expense",
  "secondaryConfidence": 30,
  "keywords": ["اشتري", "حليب"],
  "sentiment": "neutral",
  "urgency": "medium",
  "reason": "يحتوي على فعل أمر يتطلب شراء",
  "suggestedTags": ["shopping", "groceries"]
}
''';

      final response = await generateText(prompt);
      return _parseJsonResponse(response);
    } catch (e) {
      print('❌ Smart Categorization Error: $e');
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🔍 RESPONSE PARSING HELPERS
  // ════════════════════════════════════════════════════════════

  /// Parse JSON response from Gemini
  /// Handles both clean JSON and JSON wrapped in markdown code blocks
  Map<String, dynamic> _parseJsonResponse(String response) {
    try {
      // Remove markdown code blocks if present
      String cleanJson = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      print('❌ JSON Parse Error: $e');
      print('Response was: $response');
      return {};
    }
  }

  /// Parse category response and create CategoryResult
  CategoryResult _parseCategoryResponse(String response, String originalText) {
    try {
      final json = _parseJsonResponse(response);

      return CategoryResult(
        category: json['category']?.toString().toLowerCase() ?? 'note',
        confidence: (json['confidence'] ?? 70.0).toDouble(),
        originalText: originalText,
        reason: json['reason']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Category Parse Error: $e');
      return CategoryResult(
        category: 'note',
        confidence: 50.0,
        originalText: originalText,
        reason: 'Parse error',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // 🎭 MOCK DATA FOR TESTING (NO API NEEDED)
  // ════════════════════════════════════════════════════════════

  /// Generate mock response based on prompt keywords
  String _getMockResponse(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('categorize') || lower.contains('تصنيف')) {
      return _generateMockCategoryJson(prompt);
    } else if (lower.contains('extract') || lower.contains('استخرج')) {
      return _generateMockExtractionJson(prompt);
    } else if (lower.contains('suggest') || lower.contains('اقترح')) {
      return _generateMockSuggestionsJson();
    }

    return 'Mock response for: ${prompt.substring(0, min(50, prompt.length))}...';
  }

  /// Generate mock categorization JSON
  String _generateMockCategoryJson(String prompt) {
    final lower = prompt.toLowerCase();

    String category = 'note';
    double confidence = 75.0;
    String reason = 'تصنيف تلقائي';

    if (lower.contains('buy') || lower.contains('اشتري') || lower.contains('task')) {
      category = 'todo';
      confidence = 85.0;
      reason = 'يحتوي على فعل أمر يتطلب إجراء';
    } else if (lower.contains('meeting') || lower.contains('اجتماع') || lower.contains('pm') || lower.contains('am')) {
      category = 'appointment';
      confidence = 90.0;
      reason = 'يحتوي على موعد أو وقت محدد';
    } else if (lower.contains('paid') || lower.contains('دفعت') || lower.contains('egp') || lower.contains('جنيه')) {
      category = 'expense';
      confidence = 95.0;
      reason = 'يحتوي على مبلغ مالي';
    } else if (lower.contains('"') || lower.contains('quote') || lower.contains('اقتباس')) {
      category = 'quote';
      confidence = 80.0;
      reason = 'نص ملهم أو اقتباس';
    }

    return jsonEncode({
      'category': category,
      'confidence': confidence,
      'reason': reason,
    });
  }

  /// Generate mock extraction JSON based on category
  String _generateMockExtractionJson(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('task') || lower.contains('مهمة')) {
      return jsonEncode({
        'title': 'مهمة تم استخراجها',
        'priority': 'medium',
        'deadline': 'غداً',
        'category': 'personal',
        'description': 'تفاصيل المهمة',
      });
    } else if (lower.contains('appointment') || lower.contains('موعد')) {
      return jsonEncode({
        'title': 'موعد مهم',
        'date': 'غداً',
        'time': '5:00 PM',
        'location': 'المكتب',
        'type': 'meeting',
        'notes': 'ملاحظات إضافية',
      });
    } else if (lower.contains('expense') || lower.contains('مصروف')) {
      return jsonEncode({
        'description': 'مشتريات',
        'amount': 150.0,
        'currency': 'EGP',
        'category': 'shopping',
        'payment_method': 'cash',
        'date': 'اليوم',
      });
    }

    return jsonEncode({
      'title': 'ملاحظة',
      'summary': 'ملخص الملاحظة',
      'tags': ['general', 'note'],
      'type': 'general',
      'sentiment': 'neutral',
    });
  }

  /// Generate mock suggestions JSON
  String _generateMockSuggestionsJson() {
    return jsonEncode({
      'suggestions': [
        {
          'action': 'إضافة تذكير',
          'category': 'todo',
          'priority': 'medium',
          'reason': 'لضمان عدم النسيان',
        },
        {
          'action': 'تحديد موعد نهائي',
          'category': 'appointment',
          'priority': 'high',
          'reason': 'للالتزام بالجدول الزمني',
        },
      ],
    });
  }

  /// Get mock category result
  CategoryResult _getMockCategoryResult(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('buy') || lower.contains('اشتري') || lower.contains('task')) {
      return CategoryResult(
        category: 'todo',
        confidence: 85.0,
        originalText: input,
        reason: 'يحتوي على فعل يتطلب إجراء',
      );
    } else if (lower.contains('meeting') || lower.contains('اجتماع')) {
      return CategoryResult(
        category: 'appointment',
        confidence: 90.0,
        originalText: input,
        reason: 'يحتوي على موعد',
      );
    } else if (lower.contains('paid') || lower.contains('دفعت') || lower.contains('egp')) {
      return CategoryResult(
        category: 'expense',
        confidence: 95.0,
        originalText: input,
        reason: 'يحتوي على مبلغ مالي',
      );
    }

    return CategoryResult(
      category: 'note',
      confidence: 70.0,
      originalText: input,
      reason: 'تصنيف افتراضي',
    );
  }

  /// Get mock extracted details
  Map<String, dynamic> _getMockExtractedDetails(String category, String input) {
    switch (category) {
      case 'todo':
        return {
          'title': 'مهمة: ${input.substring(0, min(30, input.length))}',
          'priority': 'medium',
          'deadline': 'غداً',
          'category': 'personal',
        };
      case 'appointment':
        return {
          'title': 'موعد: ${input.substring(0, min(30, input.length))}',
          'date': 'غداً',
          'time': '5:00 PM',
          'location': null,
        };
      case 'expense':
        return {
          'description': input.substring(0, min(50, input.length)),
          'amount': 100.0,
          'currency': 'EGP',
          'category': 'general',
        };
      default:
        return {
          'title': input.substring(0, min(50, input.length)),
          'summary': 'ملخص تلقائي',
          'tags': ['general'],
        };
    }
  }

  /// Get mock suggestions
  List<ActionSuggestion> _getMockSuggestions(String content) {
    return [
      ActionSuggestion(
        action: 'إضافة تذكير',
        category: 'todo',
        priority: 'medium',
        reason: 'للمتابعة',
      ),
      ActionSuggestion(
        action: 'تحديد موعد',
        category: 'appointment',
        priority: 'high',
        reason: 'للتنظيم',
      ),
    ];
  }

  /// Get mock multiple items extraction
  List<Map<String, dynamic>> _getMockMultipleItems(String input) {
    final lower = input.toLowerCase();

    // Check for multiple shopping items
    if (lower.contains('و') || lower.contains('and')) {
      // Split by Arabic 'و' or English 'and'
      final items = input
          .split(RegExp(r'\s+و\s+|and'))
          .where((s) => s.trim().isNotEmpty)
          .map((item) => {
                'type': 'todo',
                'title': item.trim(),
                'priority': 'medium',
                'category': 'shopping',
              })
          .toList();

      if (items.isNotEmpty) return items;
    }

    // Single item fallback
    return [
      {
        'type': _detectType(input),
        'title': input.substring(0, min(50, input.length)),
        'priority': 'medium',
      }
    ];
  }

  /// Detect item type from text
  String _detectType(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('اشتري') ||
        lower.contains('buy') ||
        lower.contains('task')) return 'todo';
    if (lower.contains('اجتماع') ||
        lower.contains('meeting') ||
        lower.contains('موعد')) return 'appointment';
    if (lower.contains('دفعت') ||
        lower.contains('paid') ||
        lower.contains('egp')) return 'expense';
    return 'note';
  }

  /// Get mock smart categorization
  Map<String, dynamic> _getMockSmartCategorization(String input) {
    final lower = input.toLowerCase();
    String category = 'note';
    double confidence = 70.0;
    String? secondaryCategory;
    double secondaryConfidence = 0.0;
    List<String> keywords = [];
    String sentiment = 'neutral';
    String urgency = 'medium';

    // Detect category
    if (lower.contains('اشتري') || lower.contains('buy')) {
      category = 'todo';
      confidence = 90.0;
      secondaryCategory = 'expense';
      secondaryConfidence = 40.0;
      keywords = ['اشتري', 'shopping'];
      urgency = 'medium';
    } else if (lower.contains('اجتماع') || lower.contains('meeting')) {
      category = 'appointment';
      confidence = 95.0;
      keywords = ['اجتماع', 'meeting'];
      urgency = 'high';
    } else if (lower.contains('دفعت') || lower.contains('paid')) {
      category = 'expense';
      confidence = 98.0;
      keywords = ['دفعت', 'payment'];
      urgency = 'low';
    } else if (lower.contains('مهم') || lower.contains('urgent')) {
      urgency = 'urgent';
      confidence = 85.0;
    }

    // Detect sentiment
    if (lower.contains('سعيد') || lower.contains('happy') || lower.contains('رائع')) {
      sentiment = 'positive';
    } else if (lower.contains('حزين') || lower.contains('sad') || lower.contains('مشكلة')) {
      sentiment = 'negative';
    }

    return {
      'category': category,
      'confidence': confidence,
      'secondaryCategory': secondaryCategory,
      'secondaryConfidence': secondaryConfidence,
      'keywords': keywords,
      'sentiment': sentiment,
      'urgency': urgency,
      'reason': 'تحليل تلقائي بناءً على الكلمات المفتاحية',
      'suggestedTags': keywords,
    };
  }

  // ════════════════════════════════════════════════════════════
  // 🔧 UTILITY METHODS
  // ════════════════════════════════════════════════════════════

  /// Check if service is in mock mode
  bool get isMockMode => _useMockData;

  /// Check if API is properly configured
  bool get isConfigured => _model != null || _useMockData;
}