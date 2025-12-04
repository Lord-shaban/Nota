import 'package:flutter/services.dart';

class TextProcessor {
  // Process text and extract meaningful information
  static Future<ProcessedText> processText(String rawText) async {
    // Clean and normalize text
    final cleanedText = _cleanText(rawText);

    // Generate title from first line or first 30 characters
    final title = _generateTitle(cleanedText);

    // Detect language
    final language = _detectLanguage(cleanedText);

    // Count words
    final wordCount = _countWords(cleanedText);

    // Extract any dates, times, amounts, etc.
    final extractedData = _extractData(cleanedText);

    return ProcessedText(
      content: cleanedText,
      title: title,
      wordCount: wordCount,
      detectedLanguage: language,
      extractedData: extractedData,
    );
  }

  static String _cleanText(String text) {
    // Remove extra whitespace
    String cleaned = text.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Remove dangerous characters
    cleaned = cleaned.replaceAll(RegExp(r'[<>]'), '');

    return cleaned;
  }

  static String _generateTitle(String text) {
    // Try to get first line as title
    final lines = text.split('\n');
    if (lines.isNotEmpty && lines[0].isNotEmpty) {
      final firstLine = lines[0];
      if (firstLine.length <= 50) {
        return firstLine;
      }
    }

    // Otherwise, use first 30 characters
    if (text.length <= 30) {
      return text;
    }
    return '${text.substring(0, 30)}...';
  }

  static String _detectLanguage(String text) {
    // Simple language detection based on characters
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    final englishRegex = RegExp(r'[a-zA-Z]');

    final arabicCount = arabicRegex.allMatches(text).length;
    final englishCount = englishRegex.allMatches(text).length;

    if (arabicCount > englishCount) {
      return 'ar';
    } else if (englishCount > arabicCount) {
      return 'en';
    }
    return 'mixed';
  }

  static int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  static Map<String, dynamic> _extractData(String text) {
    final extracted = <String, dynamic>{};

    // Extract dates (simple pattern)
    final datePattern = RegExp(r'\d{1,2}/\d{1,2}/\d{4}');
    final dates = datePattern
        .allMatches(text)
        .map((match) => match.group(0))
        .toList();
    if (dates.isNotEmpty) {
      extracted['dates'] = dates;
    }

    // Extract times
    final timePattern = RegExp(r'\d{1,2}:\d{2}');
    final times = timePattern
        .allMatches(text)
        .map((match) => match.group(0))
        .toList();
    if (times.isNotEmpty) {
      extracted['times'] = times;
    }

    // Extract amounts
    final amountPattern = RegExp(r'\d+\.?\d*\s*(ريال|ر\.س|SAR|\$)');
    final amounts = amountPattern
        .allMatches(text)
        .map((match) => match.group(0))
        .toList();
    if (amounts.isNotEmpty) {
      extracted['amounts'] = amounts;
    }

    // Extract phone numbers
    final phonePattern = RegExp(r'(\+966|05|5)\d{8}');
    final phones = phonePattern
        .allMatches(text)
        .map((match) => match.group(0))
        .toList();
    if (phones.isNotEmpty) {
      extracted['phoneNumbers'] = phones;
    }

    // Extract emails
    final emailPattern = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b');
    final emails = emailPattern
        .allMatches(text)
        .map((match) => match.group(0))
        .toList();
    if (emails.isNotEmpty) {
      extracted['emails'] = emails;
    }

    return extracted;
  }
}

// Processed text model
class ProcessedText {
  final String content;
  final String title;
  final int wordCount;
  final String detectedLanguage;
  final Map<String, dynamic> extractedData;

  ProcessedText({
    required this.content,
    required this.title,
    required this.wordCount,
    required this.detectedLanguage,
    required this.extractedData,
  });
}
