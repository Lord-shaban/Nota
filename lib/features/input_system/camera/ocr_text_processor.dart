// ocr_text_processor.dart
// ------------------------------------------------------------
// OCR Text Processing Service
// Inspired by alNota's image-to-text processing
// Handles text extraction cleanup and enhancement using Gemini AI
// ------------------------------------------------------------

import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

/// OCR Text Processor
/// Uses Gemini Vision API to extract and enhance text from images
class OcrTextProcessor {
  final GenerativeModel? _model;
  final bool _useMockData;

  OcrTextProcessor(String apiKey, {bool useMockData = false})
      : _useMockData = useMockData,
        _model = useMockData
            ? null
            : GenerativeModel(
                model: 'gemini-2.5-flash', // Upgraded to 2.5 Flash for better performance
                apiKey: apiKey,
                generationConfig: GenerationConfig(
                  temperature: 0.4, // Lower temp for accuracy
                  topK: 32,
                  topP: 0.95,
                  maxOutputTokens: 2048,
                ),
              );

  /// Extract text from image file
  /// Returns cleaned and structured text
  Future<OcrResult> extractTextFromImage(File imageFile) async {
    if (_useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return OcrResult(
        rawText: 'نص تجريبي من الصورة',
        cleanedText: 'نص تجريبي من الصورة',
        confidence: 85.0,
        language: 'ar',
        hasMultipleItems: false,
      );
    }

    try {
      // Read image as bytes
      final imageBytes = await imageFile.readAsBytes();

      // Create content with image and prompt
      final prompt = TextPart(_buildOcrPrompt());
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model!.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final extractedText = response.text ?? '';

      // Parse the response
      return _parseOcrResponse(extractedText);
    } catch (e) {
      print('❌ OCR Error: $e');
      return OcrResult(
        rawText: '',
        cleanedText: '',
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Enhanced OCR with categorization (alNota feature)
  /// Not only extracts text but also suggests category
  Future<EnhancedOcrResult> extractAndCategorize(File imageFile) async {
    if (_useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return EnhancedOcrResult(
        rawText: 'اشتري حليب',
        cleanedText: 'اشتري حليب',
        confidence: 90.0,
        suggestedCategory: 'todo',
        categoryConfidence: 85.0,
        extractedItems: [
          {'type': 'todo', 'title': 'اشتري حليب'}
        ],
      );
    }

    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart(_buildEnhancedOcrPrompt());
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model!.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return _parseEnhancedOcrResponse(response.text ?? '');
    } catch (e) {
      print('❌ Enhanced OCR Error: $e');
      return EnhancedOcrResult(
        rawText: '',
        cleanedText: '',
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Build standard OCR prompt
  String _buildOcrPrompt() {
    return '''
استخرج كل النصوص من هذه الصورة.
إرشادات:
- احتفظ بالتنسيق والترتيب الأصلي
- أصلح أي أخطاء إملائية واضحة
- احذف أي نصوص غير مفهومة
- إذا كان النص بلغات متعددة، احتفظ بها جميعاً
- ضع علامات ترقيم مناسبة

أعد النص المستخرج فقط، بدون أي تفسيرات إضافية.
''';
  }

  /// Build enhanced OCR prompt with categorization
  String _buildEnhancedOcrPrompt() {
    return '''
قم بتحليل هذه الصورة واستخراج النص منها مع التصنيف الذكي.

أعد JSON بالصيغة التالية:
{
  "rawText": "النص المستخرج كما هو",
  "cleanedText": "النص بعد التنظيف والتحسين",
  "confidence": نسبة الثقة في الاستخراج (0-100),
  "language": "اللغة المكتشفة",
  "suggestedCategory": "todo/appointment/expense/note",
  "categoryConfidence": نسبة الثقة في التصنيف,
  "extractedItems": [
    {
      "type": "النوع",
      "title": "العنوان",
      "details": {}
    }
  ],
  "hasMultipleItems": true/false
}

أمثلة:
- صورة فاتورة → expense + استخراج المبلغ
- صورة قائمة مشتريات → multiple todos
- صورة تقويم → appointment
- صورة ملاحظات → note
''';
  }

  /// Parse standard OCR response
  OcrResult _parseOcrResponse(String response) {
    try {
      // Check if it looks like structured text vs JSON
      final trimmed = response.trim();

      return OcrResult(
        rawText: trimmed,
        cleanedText: trimmed,
        confidence: 80.0, // Default confidence
        language: _detectLanguage(trimmed),
        hasMultipleItems: _checkMultipleItems(trimmed),
      );
    } catch (e) {
      return OcrResult(
        rawText: response,
        cleanedText: response,
        confidence: 50.0,
        error: 'Parse error: $e',
      );
    }
  }

  /// Parse enhanced OCR response
  EnhancedOcrResult _parseEnhancedOcrResponse(String response) {
    try {
      // Try to parse as JSON first
      final cleanJson = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // For simplicity, return a basic result
      // In production, you'd parse the JSON properly
      return EnhancedOcrResult(
        rawText: cleanJson,
        cleanedText: cleanJson,
        confidence: 75.0,
        suggestedCategory: 'note',
        categoryConfidence: 60.0,
      );
    } catch (e) {
      return EnhancedOcrResult(
        rawText: response,
        cleanedText: response,
        confidence: 50.0,
        error: 'Parse error: $e',
      );
    }
  }

  /// Detect language from text
  String _detectLanguage(String text) {
    // Simple detection: check for Arabic characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    if (arabicRegex.hasMatch(text)) return 'ar';
    return 'en';
  }

  /// Check if text contains multiple items
  bool _checkMultipleItems(String text) {
    // Look for list indicators
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length > 3) return true;

    // Look for bullet points or numbers
    final listRegex = RegExp(r'^[\d\-\*\•]');
    final listLines = lines.where((l) => listRegex.hasMatch(l.trim())).length;

    return listLines >= 2;
  }
}

/// OCR Result Model
class OcrResult {
  final String rawText;
  final String cleanedText;
  final double confidence;
  final String? language;
  final bool hasMultipleItems;
  final String? error;

  OcrResult({
    required this.rawText,
    required this.cleanedText,
    required this.confidence,
    this.language,
    this.hasMultipleItems = false,
    this.error,
  });

  bool get isSuccess => error == null && cleanedText.isNotEmpty;
}

/// Enhanced OCR Result with Categorization
class EnhancedOcrResult {
  final String rawText;
  final String cleanedText;
  final double confidence;
  final String? suggestedCategory;
  final double? categoryConfidence;
  final List<Map<String, dynamic>>? extractedItems;
  final String? error;

  EnhancedOcrResult({
    required this.rawText,
    required this.cleanedText,
    required this.confidence,
    this.suggestedCategory,
    this.categoryConfidence,
    this.extractedItems,
    this.error,
  });

  bool get isSuccess => error == null && cleanedText.isNotEmpty;
  bool get hasCategory => suggestedCategory != null;
  bool get hasMultipleItems =>
      extractedItems != null && extractedItems!.length > 1;
}
