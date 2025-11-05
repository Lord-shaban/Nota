import 'package:cloud_firestore/cloud_firestore.dart';

// ================== ENUMS ==================

/// Types of input methods available
enum InputType { text, voice, camera, gallery }

/// Priority levels for items
enum Priority { low, medium, high }

/// Note types for categorization
enum NoteType { note, task, appointment, expense, quote }

/// Processing status
enum ProcessingStatus { pending, processing, completed, failed }

// ================== MAIN MODELS ==================

/// Main input data model
class InputData {
  final String? id;
  final InputType type;
  final String content;
  final String? title;
  final String rawInput;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? imageUrl;
  final ProcessingStatus status;
  final String? userId;
  final List<String>? tags;

  InputData({
    this.id,
    required this.type,
    required this.content,
    this.title,
    required this.rawInput,
    required this.timestamp,
    this.metadata,
    this.imageUrl,
    this.status = ProcessingStatus.pending,
    this.userId,
    this.tags,
  });

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'title': title,
      'rawInput': rawInput,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'userId': userId,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from JSON (Firebase)
  factory InputData.fromJson(Map<String, dynamic> json, {String? id}) {
    return InputData(
      id: id ?? json['id'],
      type: InputType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => InputType.text,
      ),
      content: json['content'] ?? '',
      title: json['title'],
      rawInput: json['rawInput'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
      imageUrl: json['imageUrl'],
      status: ProcessingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProcessingStatus.completed,
      ),
      userId: json['userId'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  /// Create a copy with modifications
  InputData copyWith({
    String? id,
    InputType? type,
    String? content,
    String? title,
    String? rawInput,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    ProcessingStatus? status,
    String? userId,
    List<String>? tags,
  }) {
    return InputData(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      rawInput: rawInput ?? this.rawInput,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
    );
  }
}

/// Processed text model from text processor
class ProcessedText {
  final String content;
  final String title;
  final int wordCount;
  final String detectedLanguage;
  final Map<String, dynamic> extractedData;
  final List<String> suggestedTags;
  final NoteType? suggestedType;
  final Priority? suggestedPriority;

  ProcessedText({
    required this.content,
    required this.title,
    required this.wordCount,
    required this.detectedLanguage,
    required this.extractedData,
    this.suggestedTags = const [],
    this.suggestedType,
    this.suggestedPriority,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'title': title,
      'wordCount': wordCount,
      'detectedLanguage': detectedLanguage,
      'extractedData': extractedData,
      'suggestedTags': suggestedTags,
      'suggestedType': suggestedType?.toString().split('.').last,
      'suggestedPriority': suggestedPriority?.toString().split('.').last,
    };
  }

  /// Create from JSON
  factory ProcessedText.fromJson(Map<String, dynamic> json) {
    return ProcessedText(
      content: json['content'],
      title: json['title'],
      wordCount: json['wordCount'],
      detectedLanguage: json['detectedLanguage'],
      extractedData: json['extractedData'],
      suggestedTags: List<String>.from(json['suggestedTags'] ?? []),
      suggestedType: json['suggestedType'] != null
          ? NoteType.values.firstWhere(
              (e) => e.toString().split('.').last == json['suggestedType'],
            )
          : null,
      suggestedPriority: json['suggestedPriority'] != null
          ? Priority.values.firstWhere(
              (e) => e.toString().split('.').last == json['suggestedPriority'],
            )
          : null,
    );
  }
}

/// Extracted item from AI processing
class ExtractedItem {
  final String id;
  final NoteType type;
  final String title;
  final String content;
  final DateTime? date;
  final String? time;
  final double? amount;
  final String? currency;
  final String? location;
  final Priority priority;
  final List<String> tags;
  final Map<String, dynamic>? additionalData;
  final String? imageUrl;
  final bool isCompleted;

  ExtractedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.date,
    this.time,
    this.amount,
    this.currency,
    this.location,
    this.priority = Priority.medium,
    this.tags = const [],
    this.additionalData,
    this.imageUrl,
    this.isCompleted = false,
  });

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'content': content,
      'date': date?.toIso8601String(),
      'time': time,
      'amount': amount,
      'currency': currency,
      'location': location,
      'priority': priority.toString().split('.').last,
      'tags': tags,
      'additionalData': additionalData,
      'imageUrl': imageUrl,
      'completed': isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from JSON (Firebase or AI response)
  factory ExtractedItem.fromJson(Map<String, dynamic> json) {
    return ExtractedItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: NoteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NoteType.note,
      ),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      time: json['time'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      location: json['location'],
      priority: Priority.values.firstWhere(
        (e) => e.toString().split('.').last == (json['priority'] ?? 'medium'),
        orElse: () => Priority.medium,
      ),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      additionalData: json['additionalData'],
      imageUrl: json['imageUrl'],
      isCompleted: json['completed'] ?? false,
    );
  }

  /// Create a copy with modifications
  ExtractedItem copyWith({
    String? id,
    NoteType? type,
    String? title,
    String? content,
    DateTime? date,
    String? time,
    double? amount,
    String? currency,
    String? location,
    Priority? priority,
    List<String>? tags,
    Map<String, dynamic>? additionalData,
    String? imageUrl,
    bool? isCompleted,
  }) {
    return ExtractedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      additionalData: additionalData ?? this.additionalData,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Voice recording metadata
class VoiceMetadata {
  final Duration duration;
  final String language;
  final double averageSoundLevel;
  final int wordCount;
  final double confidence;

  VoiceMetadata({
    required this.duration,
    required this.language,
    required this.averageSoundLevel,
    required this.wordCount,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'duration': duration.inSeconds,
      'language': language,
      'averageSoundLevel': averageSoundLevel,
      'wordCount': wordCount,
      'confidence': confidence,
    };
  }

  factory VoiceMetadata.fromJson(Map<String, dynamic> json) {
    return VoiceMetadata(
      duration: Duration(seconds: json['duration']),
      language: json['language'],
      averageSoundLevel: json['averageSoundLevel'].toDouble(),
      wordCount: json['wordCount'],
      confidence: json['confidence'].toDouble(),
    );
  }
}

/// Image metadata
class ImageMetadata {
  final String fileName;
  final int fileSize;
  final String mimeType;
  final int? width;
  final int? height;
  final String source; // camera, gallery
  final DateTime captureDate;
  final Map<String, dynamic>? exifData;

  ImageMetadata({
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.width,
    this.height,
    required this.source,
    required this.captureDate,
    this.exifData,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'source': source,
      'captureDate': captureDate.toIso8601String(),
      'exifData': exifData,
    };
  }

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      width: json['width'],
      height: json['height'],
      source: json['source'],
      captureDate: DateTime.parse(json['captureDate']),
      exifData: json['exifData'],
    );
  }
}

/// AI Processing result
class AIProcessingResult {
  final String id;
  final bool success;
  final List<ExtractedItem> items;
  final String? summary;
  final Map<String, dynamic>? analysis;
  final String? error;
  final DateTime processedAt;
  final Duration processingTime;

  AIProcessingResult({
    required this.id,
    required this.success,
    required this.items,
    this.summary,
    this.analysis,
    this.error,
    required this.processedAt,
    required this.processingTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'success': success,
      'items': items.map((e) => e.toJson()).toList(),
      'summary': summary,
      'analysis': analysis,
      'error': error,
      'processedAt': processedAt.toIso8601String(),
      'processingTime': processingTime.inMilliseconds,
    };
  }

  factory AIProcessingResult.fromJson(Map<String, dynamic> json) {
    return AIProcessingResult(
      id: json['id'],
      success: json['success'],
      items: (json['items'] as List)
          .map((e) => ExtractedItem.fromJson(e))
          .toList(),
      summary: json['summary'],
      analysis: json['analysis'],
      error: json['error'],
      processedAt: DateTime.parse(json['processedAt']),
      processingTime: Duration(milliseconds: json['processingTime']),
    );
  }
}

/// Input validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.valid() {
    return ValidationResult(isValid: true);
  }

  factory ValidationResult.invalid(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}

/// Settings for input processing
class InputProcessingSettings {
  final bool autoDetectLanguage;
  final bool extractDates;
  final bool extractAmounts;
  final bool extractLocations;
  final bool extractPhoneNumbers;
  final bool extractEmails;
  final bool autoGenerateTags;
  final bool autoDetectType;
  final String defaultLanguage;
  final String defaultCurrency;

  InputProcessingSettings({
    this.autoDetectLanguage = true,
    this.extractDates = true,
    this.extractAmounts = true,
    this.extractLocations = true,
    this.extractPhoneNumbers = true,
    this.extractEmails = true,
    this.autoGenerateTags = true,
    this.autoDetectType = true,
    this.defaultLanguage = 'ar',
    this.defaultCurrency = 'SAR',
  });

  Map<String, dynamic> toJson() {
    return {
      'autoDetectLanguage': autoDetectLanguage,
      'extractDates': extractDates,
      'extractAmounts': extractAmounts,
      'extractLocations': extractLocations,
      'extractPhoneNumbers': extractPhoneNumbers,
      'extractEmails': extractEmails,
      'autoGenerateTags': autoGenerateTags,
      'autoDetectType': autoDetectType,
      'defaultLanguage': defaultLanguage,
      'defaultCurrency': defaultCurrency,
    };
  }

  factory InputProcessingSettings.fromJson(Map<String, dynamic> json) {
    return InputProcessingSettings(
      autoDetectLanguage: json['autoDetectLanguage'] ?? true,
      extractDates: json['extractDates'] ?? true,
      extractAmounts: json['extractAmounts'] ?? true,
      extractLocations: json['extractLocations'] ?? true,
      extractPhoneNumbers: json['extractPhoneNumbers'] ?? true,
      extractEmails: json['extractEmails'] ?? true,
      autoGenerateTags: json['autoGenerateTags'] ?? true,
      autoDetectType: json['autoDetectType'] ?? true,
      defaultLanguage: json['defaultLanguage'] ?? 'ar',
      defaultCurrency: json['defaultCurrency'] ?? 'SAR',
    );
  }
}

// ================== HELPER EXTENSIONS ==================

extension InputTypeExtension on InputType {
  String get displayName {
    switch (this) {
      case InputType.text:
        return 'نص';
      case InputType.voice:
        return 'صوت';
      case InputType.camera:
        return 'كاميرا';
      case InputType.gallery:
        return 'معرض';
    }
  }

  String get icon {
    switch (this) {
      case InputType.text:
        return '📝';
      case InputType.voice:
        return '🎤';
      case InputType.camera:
        return '📷';
      case InputType.gallery:
        return '🖼️';
    }
  }
}

extension NoteTypeExtension on NoteType {
  String get displayName {
    switch (this) {
      case NoteType.note:
        return 'ملاحظة';
      case NoteType.task:
        return 'مهمة';
      case NoteType.appointment:
        return 'موعد';
      case NoteType.expense:
        return 'مصروف';
      case NoteType.quote:
        return 'اقتباس';
    }
  }

  String get icon {
    switch (this) {
      case NoteType.note:
        return '📝';
      case NoteType.task:
        return '✅';
      case NoteType.appointment:
        return '📅';
      case NoteType.expense:
        return '💰';
      case NoteType.quote:
        return '💭';
    }
  }
}

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'منخفض';
      case Priority.medium:
        return 'متوسط';
      case Priority.high:
        return 'مرتفع';
    }
  }

  String get colorHex {
    switch (this) {
      case Priority.low:
        return '#4CAF50';
      case Priority.medium:
        return '#FF9800';
      case Priority.high:
        return '#F44336';
    }
  }
}

// ================== UTILITY FUNCTIONS ==================

class InputValidator {
  static ValidationResult validateTextInput(String text) {
    final errors = <String>[];
    final warnings = <String>[];

    if (text.trim().isEmpty) {
      errors.add('النص فارغ');
    }

    if (text.trim().length < 3) {
      errors.add('النص قصير جداً (3 أحرف على الأقل)');
    }

    if (text.trim().length > 5000) {
      errors.add('النص طويل جداً (الحد الأقصى 5000 حرف)');
    }

    if (text.contains(RegExp(r'[<>]'))) {
      warnings.add('يحتوي النص على رموز خاصة قد تسبب مشاكل');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  static ValidationResult validateImageFile(String path, int size) {
    final errors = <String>[];
    final warnings = <String>[];

    if (!path.endsWith('.jpg') &&
        !path.endsWith('.jpeg') &&
        !path.endsWith('.png')) {
      errors.add('صيغة الملف غير مدعومة');
    }

    if (size > 10 * 1024 * 1024) {
      // 10MB
      errors.add('حجم الصورة كبير جداً (الحد الأقصى 10MB)');
    }

    if (size > 5 * 1024 * 1024) {
      // 5MB
      warnings.add('حجم الصورة كبير، قد يستغرق الرفع وقتاً طويلاً');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

// ================== CONSTANTS ==================

class InputConstants {
  static const int maxTextLength = 5000;
  static const int minTextLength = 3;
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const Duration maxVoiceDuration = Duration(minutes: 5);
  static const Duration voicePauseDuration = Duration(seconds: 5);

  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  static const List<String> supportedLanguages = [
    'ar-SA', // Arabic
    'en-US', // English
    'ar-EG', // Egyptian Arabic
    'ar-AE', // UAE Arabic
  ];

  static const Map<String, String> currencySymbols = {
    'SAR': 'ر.س',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
  };
}
