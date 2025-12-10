// lib/components/ai_brain/models/ai_models.dart
// تم إزالة equatable وإضافة جميع الـ getters المطلوبة

// ==================== ENUMS ====================

enum ExtractionStatus {
  success('success'),
  partial('partial'),
  failed('failed'),
  processing('processing');

  const ExtractionStatus(this.value);
  final String value;

  static ExtractionStatus fromString(String value) {
    return ExtractionStatus.values.firstWhere(
          (e) => e.value == value,
      orElse: () => ExtractionStatus.failed,
    );
  }
}

enum ItemType {
  task('task', 'Tasks', '📝'),
  appointment('appointment', 'Appointments', '📅'),
  expense('expense', 'Expenses', '💰'),
  quote('quote', 'Quotes', '💬'),
  note('note', 'Notes', '📄'),
  reminder('reminder', 'Reminders', '⏰'),
  contact('contact', 'Contacts', '👤'),
  unknown('unknown', 'Unknown', '❓');

  const ItemType(this.value, this.displayName, this.emoji);
  final String value;
  final String displayName;
  final String emoji;

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => ItemType.unknown,
    );
  }
}

// ==================== MAIN AI MODELS ====================

class ExtractedItem {
  final ItemType type;
  final List<String> items;
  final double confidence;
  final DateTime extractedAt;
  final Map<String, dynamic> metadata;

  const ExtractedItem({
    required this.type,
    required this.items,
    this.confidence = 1.0,
    required this.extractedAt,
    this.metadata = const {},
  });

  // Copy with method for immutable updates
  ExtractedItem copyWith({
    ItemType? type,
    List<String>? items,
    double? confidence,
    DateTime? extractedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ExtractedItem(
      type: type ?? this.type,
      items: items ?? this.items,
      confidence: confidence ?? this.confidence,
      extractedAt: extractedAt ?? this.extractedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'items': items,
      'confidence': confidence,
      'extractedAt': extractedAt.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory ExtractedItem.fromJson(Map<String, dynamic> json) {
    return ExtractedItem(
      type: ItemType.fromString(json['type'] as String? ?? 'unknown'),
      items: List<String>.from(json['items'] as List<dynamic>? ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      extractedAt: _parseDateTime(json['extractedAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map<dynamic, dynamic>? ?? {}),
    );
  }

  // Helper method to parse DateTime
  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString is String) {
      try {
        return DateTime.parse(dateString).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Validation methods
  bool get isValid => items.isNotEmpty && confidence > 0.1;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;

  // Get display properties
  String get displayName => type.displayName;
  String get emoji => type.emoji;

  // Filter items by keyword
  List<String> filterItems(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return items.where((item) => item.toLowerCase().contains(lowerKeyword)).toList();
  }

  // Manual equality check (بدل Equatable)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ExtractedItem &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              items == other.items &&
              confidence == other.confidence &&
              extractedAt == other.extractedAt &&
              metadata == other.metadata;

  @override
  int get hashCode =>
      type.hashCode ^
      items.hashCode ^
      confidence.hashCode ^
      extractedAt.hashCode ^
      metadata.hashCode;

  @override
  String toString() {
    return 'ExtractedItem(type: $type, items: ${items.length}, confidence: $confidence)';
  }
}

class AIResponse {
  final ExtractionStatus status;
  final String input;
  final List<ExtractedItem> categories;
  final String? errorMessage;
  final String modelVersion;
  final DateTime processedAt;
  final int processingTimeMs;
  final Map<String, dynamic> analysisMetadata;

  const AIResponse({
    required this.status,
    required this.input,
    required this.categories,
    this.errorMessage,
    this.modelVersion = '1.0.0',
    required this.processedAt,
    this.processingTimeMs = 0,
    this.analysisMetadata = const {},
  });

  // Copy with method for immutable updates
  AIResponse copyWith({
    ExtractionStatus? status,
    String? input,
    List<ExtractedItem>? categories,
    String? errorMessage,
    String? modelVersion,
    DateTime? processedAt,
    int? processingTimeMs,
    Map<String, dynamic>? analysisMetadata,
  }) {
    return AIResponse(
      status: status ?? this.status,
      input: input ?? this.input,
      categories: categories ?? this.categories,
      errorMessage: errorMessage ?? this.errorMessage,
      modelVersion: modelVersion ?? this.modelVersion,
      processedAt: processedAt ?? this.processedAt,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      analysisMetadata: analysisMetadata ?? this.analysisMetadata,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'input': input,
      'categories': categories.map((category) => category.toJson()).toList(),
      'errorMessage': errorMessage,
      'modelVersion': modelVersion,
      'processedAt': processedAt.toUtc().toIso8601String(),
      'processingTimeMs': processingTimeMs,
      'analysisMetadata': analysisMetadata,
    };
  }

  // Create from JSON
  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      status: ExtractionStatus.fromString(json['status'] as String? ?? 'failed'),
      input: json['input'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => ExtractedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorMessage: json['errorMessage'] as String?,
      modelVersion: json['modelVersion'] as String? ?? '1.0.0',
      processedAt: _parseDateTime(json['processedAt']),
      processingTimeMs: json['processingTimeMs'] as int? ?? 0,
      analysisMetadata: Map<String, dynamic>.from(json['analysisMetadata'] as Map<dynamic, dynamic>? ?? {}),
    );
  }

  // Helper method to parse DateTime
  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString is String) {
      try {
        return DateTime.parse(dateString).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Validation and utility methods
  bool get isSuccess => status == ExtractionStatus.success;
  bool get isPartial => status == ExtractionStatus.partial;
  bool get isFailed => status == ExtractionStatus.failed;
  bool get isProcessing => status == ExtractionStatus.processing;

  bool get hasErrors => errorMessage != null && errorMessage!.isNotEmpty;
  bool get hasExtractedItems => categories.any((category) => category.isValid);

  // Get total extracted items count
  int get totalItems {
    return categories.fold(0, (sum, category) => sum + category.items.length);
  }

  // Get items by type
  List<String> getItemsByType(ItemType type) {
    final category = categories.firstWhere(
          (cat) => cat.type == type,
      orElse: () => ExtractedItem(
        type: type,
        items: const [],
        extractedAt: DateTime.now(),
      ),
    );
    return category.items;
  }

  // Get all valid categories
  List<ExtractedItem> get validCategories {
    return categories.where((category) => category.isValid).toList();
  }

  // Get confidence score (average of all categories)
  double get overallConfidence {
    if (categories.isEmpty) return 0.0;
    final total = categories.fold(0.0, (sum, category) => sum + category.confidence);
    return total / categories.length;
  }

  // Manual equality check (بدل Equatable)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AIResponse &&
              runtimeType == other.runtimeType &&
              status == other.status &&
              input == other.input &&
              categories == other.categories &&
              errorMessage == other.errorMessage &&
              modelVersion == other.modelVersion &&
              processedAt == other.processedAt &&
              processingTimeMs == other.processingTimeMs &&
              analysisMetadata == other.analysisMetadata;

  @override
  int get hashCode =>
      status.hashCode ^
      input.hashCode ^
      categories.hashCode ^
      errorMessage.hashCode ^
      modelVersion.hashCode ^
      processedAt.hashCode ^
      processingTimeMs.hashCode ^
      analysisMetadata.hashCode;

  @override
  String toString() {
    return 'AIResponse(status: $status, items: $totalItems, confidence: ${overallConfidence.toStringAsFixed(2)})';
  }
}

// ==================== GEMINI SERVICE MODELS ====================

class CategoryResult {
  final String category;
  final double confidence;
  final String originalText;
  final String reason;

  const CategoryResult({
    required this.category,
    required this.confidence,
    required this.originalText,
    required this.reason,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'confidence': confidence,
      'originalText': originalText,
      'reason': reason,
    };
  }

  // Create from JSON
  factory CategoryResult.fromJson(Map<String, dynamic> json) {
    return CategoryResult(
      category: json['category'] ?? 'note',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      originalText: json['originalText'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  // Add the missing getters for ai_results_dialog.dart
  String get categoryEmoji {
    switch (category.toLowerCase()) {
      case 'task':
      case 'todo':
      case 'to-do':
        return '📝';
      case 'appointment':
        return '📅';
      case 'expense':
        return '💰';
      case 'quote':
        return '💬';
      case 'note':
        return '📄';
      case 'reminder':
        return '⏰';
      case 'contact':
        return '👤';
      default:
        return '❓';
    }
  }

  // Add display category name
  String get displayCategory {
    switch (category.toLowerCase()) {
      case 'task':
      case 'todo':
      case 'to-do':
        return 'مهمة';
      case 'appointment':
        return 'موعد';
      case 'expense':
        return 'مصروف';
      case 'quote':
        return 'اقتباس';
      case 'note':
        return 'ملاحظة';
      case 'reminder':
        return 'تذكير';
      case 'contact':
        return 'جهة اتصال';
      default:
        return 'غير معروف';
    }
  }

  // Add confidence validation
  bool get isConfident => confidence >= 70.0;

  // Add validation
  bool get isValid => category.isNotEmpty && confidence > 0;

  @override
  String toString() {
    return 'CategoryResult(category: $category, confidence: $confidence)';
  }
}

class ActionSuggestion {
  final String action;
  final String category;
  final String priority;
  final String reason;

  const ActionSuggestion({
    required this.action,
    required this.category,
    required this.priority,
    required this.reason,
  });

  factory ActionSuggestion.fromJson(Map<String, dynamic> json) {
    return ActionSuggestion(
      action: json['action'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'medium',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'category': category,
      'priority': priority,
      'reason': reason,
    };
  }

  @override
  String toString() {
    return 'ActionSuggestion(action: $action, category: $category)';
  }
}

// ==================== EXTENSIONS ====================

extension AIResponseExtensions on AIResponse {
  // Create a successful response
  static AIResponse success({
    required String input,
    required List<ExtractedItem> categories,
    String modelVersion = '1.0.0',
    int processingTimeMs = 0,
    Map<String, dynamic> analysisMetadata = const {},
  }) {
    return AIResponse(
      status: ExtractionStatus.success,
      input: input,
      categories: categories,
      modelVersion: modelVersion,
      processedAt: DateTime.now(),
      processingTimeMs: processingTimeMs,
      analysisMetadata: analysisMetadata,
    );
  }

  // Create a failed response
  static AIResponse failed({
    required String input,
    String errorMessage = 'Processing failed',
    String modelVersion = '1.0.0',
  }) {
    return AIResponse(
      status: ExtractionStatus.failed,
      input: input,
      categories: const [],
      errorMessage: errorMessage,
      modelVersion: modelVersion,
      processedAt: DateTime.now(),
    );
  }

  // Create a processing response
  static AIResponse processing({
    required String input,
    String modelVersion = '1.0.0',
  }) {
    return AIResponse(
      status: ExtractionStatus.processing,
      input: input,
      categories: const [],
      modelVersion: modelVersion,
      processedAt: DateTime.now(),
    );
  }
}
