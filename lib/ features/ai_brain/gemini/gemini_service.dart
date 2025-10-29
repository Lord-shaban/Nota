// gemini_service.dart
// Mock integration for Gemini API - created by [Student 4]
// -------------------------------------------------------
// This file simulates Gemini AI responses for testing and development.
// Later, real API calls can replace these mock functions.

import 'dart:async';

class GeminiService {
  // Simulate analyzing user input (text, voice, or image)
  Future<Map<String, dynamic>> analyzeInput(String inputText) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay

    // Mock categorized data (as if returned from Gemini API)
    final mockResponse = {
      "status": "success",
      "input": inputText,
      "categories": [
        {
          "type": "To-Do",
          "items": ["Buy groceries", "Finish report"],
        },
        {
          "type": "Appointment",
          "items": ["Meeting with Ahmed at 5 PM"],
        },
        {
          "type": "Expense",
          "items": ["Paid 150 EGP for transportation"],
        },
        {
          "type": "Note",
          "items": ["Remember to read Flutter docs"],
        }
      ]
    };

    return mockResponse;
  }

  // Example: get mock response for debugging or UI testing
  Map<String, dynamic> getSampleData() {
    return {
      "categories": [
        {"type": "To-Do", "items": ["Sample task 1", "Sample task 2"]},
        {"type": "Expense", "items": ["Sample expense 1", "Sample expense 2"]},
      ]
    };
  }
}
