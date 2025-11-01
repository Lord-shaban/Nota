// smart_categorizer.dart
// ------------------------------------------------------------
// This file is responsible for classifying analyzed text into
// logical categories (To-Do, Appointment, Expense, Note, etc.)
// Created by [Student Name / Student 4]
// ------------------------------------------------------------

class SmartCategorizer {
  /// Classifies input text into predefined logical categories
  Map<String, List<String>> categorizeText(String inputText) {
    final lowerText = inputText.toLowerCase();

    final Map<String, List<String>> categories = {
      "To-Do": [],
      "Appointment": [],
      "Expense": [],
      "Note": [],
    };

    // 🔹 Keyword-based logic
    if (lowerText.contains("buy") || lowerText.contains("task") || lowerText.contains("do")) {
      categories["To-Do"]!.add(inputText);
    } else if (lowerText.contains("meeting") ||
        lowerText.contains("call") ||
        lowerText.contains("appointment")) {
      categories["Appointment"]!.add(inputText);
    } else if (lowerText.contains("pay") ||
        lowerText.contains("spent") ||
        lowerText.contains("price") ||
        lowerText.contains("egp")) {
      categories["Expense"]!.add(inputText);
    } else {
      categories["Note"]!.add(inputText);
    }

    return categories;
  }

  /// Example: Run a simple test with sample inputs
  void testCategorizer() {
    final samples = [
      "Buy groceries tomorrow",
      "Meeting with team at 5 PM",
      "Paid 120 EGP for lunch",
      "Remember to study Flutter animations"
    ];

    for (final text in samples) {
      final result = categorizeText(text);
      print("Input: $text");
      print("→ Category: ${_extractCategory(result)}");
      print("--------------------------------");
    }
  }

  /// Helper to extract the matched category name
  String _extractCategory(Map<String, List<String>> result) {
    for (var entry in result.entries) {
      if (entry.value.isNotEmpty) {
        return entry.key;
      }
    }
    return "Uncategorized";
  }
}
