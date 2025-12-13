// smart_categorizer.dart
// ------------------------------------------------------------
// Enhanced text classification system with improved accuracy
// and pattern matching capabilities
// Created by [Student Name / Student 4]
// ------------------------------------------------------------

class SmartCategorizer {
  // Category definitions with weighted keywords
  static const Map<String, Map<String, int>> _categoryKeywords = {
    "To-Do": {
      // Action verbs (high weight)
      "buy": 3,
      "get": 3,
      "pick up": 3,
      "purchase": 3,
      "order": 3,
      "schedule": 2,
      "book": 2,
      "reserve": 2,

      // Task indicators
      "task": 2,
      "todo": 3,
      "to-do": 3,
      "do": 1,
      "need to": 2,
      "must": 2,
      "should": 1,
      "have to": 2,
      "remember to": 2,
      "don't forget": 2,

      // Common tasks
      "clean": 2,
      "call": 1,
      "email": 1,
      "submit": 2,
      "finish": 2,
      "complete": 2,
    },

    "Appointment": {
      // Meeting types (high weight)
      "meeting": 3,
      "appointment": 3,
      "conference": 3,
      "session": 2,
      "interview": 3,
      "consultation": 3,

      // Time-based indicators
      "at": 1,
      "pm": 2,
      "am": 2,
      "o'clock": 2,
      "tomorrow": 1,
      "next week": 2,
      "scheduled": 2,

      // Actions
      "meet": 2,
      "visit": 2,
      "see": 1,
      "attend": 2,
    },

    "Expense": {
      // Money indicators (high weight)
      "paid": 3,
      "spent": 3,
      "cost": 3,
      "price": 3,
      "bought": 2,
      "purchased": 2,

      // Currency
      "egp": 3,
      "usd": 3,
      "eur": 3,
      "\$": 3,
      "£": 3,
      "€": 3,

      // Financial terms
      "bill": 2,
      "invoice": 2,
      "payment": 2,
      "expense": 3,
      "total": 2,
    },
  };

  // Pattern matching for better accuracy
  static final RegExp _timePattern = RegExp(
    r'\b(\d{1,2})\s*(am|pm|:\d{2})',
    caseSensitive: false,
  );

  static final RegExp _datePattern = RegExp(
    r'\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|next week|next month)',
    caseSensitive: false,
  );

  static final RegExp _moneyPattern = RegExp(
    r'\b(\d+\.?\d*)\s*(egp|usd|eur|dollars?|pounds?|euros?|\$|£|€)',
    caseSensitive: false,
  );

  /// Main categorization method with improved logic
  Map<String, dynamic> categorizeText(String inputText) {
    final lowerText = inputText.toLowerCase();

    // Calculate scores for each category
    final scores = <String, int>{};
    for (final category in _categoryKeywords.keys) {
      scores[category] = _calculateScore(lowerText, category);
    }

    // Apply pattern bonuses
    _applyPatternBonuses(lowerText, scores);

    // Determine best category
    final bestCategory = _getBestCategory(scores);
    final confidence = _calculateConfidence(scores, bestCategory);

    return {
      "category": bestCategory,
      "confidence": confidence,
      "text": inputText,
      "scores": scores,
    };
  }

  /// Calculate keyword-based score for a category
  int _calculateScore(String text, String category) {
    int score = 0;
    final keywords = _categoryKeywords[category]!;

    for (final entry in keywords.entries) {
      if (text.contains(entry.key)) {
        score += entry.value;
      }
    }

    return score;
  }

  /// Apply bonus scores based on pattern matching
  void _applyPatternBonuses(String text, Map<String, int> scores) {
    // Time pattern bonus for appointments
    if (_timePattern.hasMatch(text)) {
      scores["Appointment"] = (scores["Appointment"] ?? 0) + 3;
    }

    // Date pattern bonus for appointments and todos
    if (_datePattern.hasMatch(text)) {
      scores["Appointment"] = (scores["Appointment"] ?? 0) + 2;
      scores["To-Do"] = (scores["To-Do"] ?? 0) + 1;
    }

    // Money pattern bonus for expenses
    if (_moneyPattern.hasMatch(text)) {
      scores["Expense"] = (scores["Expense"] ?? 0) + 4;
    }
  }

  /// Get the category with highest score
  String _getBestCategory(Map<String, int> scores) {
    if (scores.values.every((score) => score == 0)) {
      return "Note";
    }

    return scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculate confidence percentage
  double _calculateConfidence(Map<String, int> scores, String category) {
    final maxScore = scores[category] ?? 0;
    if (maxScore == 0) return 0.5; // Default confidence for "Note"

    final totalScore = scores.values.reduce((a, b) => a + b);
    if (totalScore == 0) return 0.5;

    return (maxScore / totalScore * 100).clamp(0, 100);
  }

  /// Batch categorization for multiple texts
  List<Map<String, dynamic>> categorizeMultiple(List<String> texts) {
    return texts.map((text) => categorizeText(text)).toList();
  }

  /// Test the categorizer with sample inputs
  void testCategorizer() {
    final samples = [
      "Buy groceries tomorrow",
      "Meeting with team at 5 PM",
      "Paid 120 EGP for lunch",
      "Remember to study Flutter animations",
      "Doctor appointment next Tuesday at 3:30 PM",
      "Spent \$50 on books",
      "Call mom tonight",
      "Conference call scheduled for Monday 10 AM",
      "Just a random thought about life",
      "Need to finish project by Friday",
    ];

    print("=== Smart Categorizer Test Results ===\n");

    for (final text in samples) {
      final result = categorizeText(text);
      print("📝 Input: $text");
      print("✅ Category: ${result['category']}");
      print("🎯 Confidence: ${result['confidence'].toStringAsFixed(1)}%");
      print("📊 Scores: ${result['scores']}");
      print("${"─" * 50}\n");
    }
  }

  /// Get category statistics from a list of results
  Map<String, int> getCategoryStats(List<Map<String, dynamic>> results) {
    final stats = <String, int>{};

    for (final result in results) {
      final category = result['category'] as String;
      stats[category] = (stats[category] ?? 0) + 1;
    }

    return stats;
  }
}

// Example usage
void main() {
  final categorizer = SmartCategorizer();
  categorizer.testCategorizer();
}
