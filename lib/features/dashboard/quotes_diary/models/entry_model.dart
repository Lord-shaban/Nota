import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// نوع المدخل - اقتباس أو يومية
enum EntryType {
  quote,
  diary,
}

extension EntryTypeExtension on EntryType {
  String get arabicName {
    switch (this) {
      case EntryType.quote:
        return 'اقتباس';
      case EntryType.diary:
        return 'يومية';
    }
  }

  IconData get icon {
    switch (this) {
      case EntryType.quote:
        return Icons.format_quote;
      case EntryType.diary:
        return Icons.book;
    }
  }

  Color get color {
    switch (this) {
      case EntryType.quote:
        return const Color(0xFF9C27B0);
      case EntryType.diary:
        return const Color(0xFF3F51B5);
    }
  }
}

/// فئة الاقتباس
enum QuoteCategory {
  motivation,
  wisdom,
  love,
  success,
  life,
  happiness,
  faith,
  friendship,
  knowledge,
  other,
}

extension QuoteCategoryExtension on QuoteCategory {
  String get arabicName {
    switch (this) {
      case QuoteCategory.motivation:
        return 'تحفيز';
      case QuoteCategory.wisdom:
        return 'حكمة';
      case QuoteCategory.love:
        return 'حب';
      case QuoteCategory.success:
        return 'نجاح';
      case QuoteCategory.life:
        return 'حياة';
      case QuoteCategory.happiness:
        return 'سعادة';
      case QuoteCategory.faith:
        return 'إيمان';
      case QuoteCategory.friendship:
        return 'صداقة';
      case QuoteCategory.knowledge:
        return 'معرفة';
      case QuoteCategory.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case QuoteCategory.motivation:
        return Icons.rocket_launch;
      case QuoteCategory.wisdom:
        return Icons.psychology;
      case QuoteCategory.love:
        return Icons.favorite;
      case QuoteCategory.success:
        return Icons.emoji_events;
      case QuoteCategory.life:
        return Icons.nature_people;
      case QuoteCategory.happiness:
        return Icons.sentiment_very_satisfied;
      case QuoteCategory.faith:
        return Icons.auto_awesome;
      case QuoteCategory.friendship:
        return Icons.people;
      case QuoteCategory.knowledge:
        return Icons.school;
      case QuoteCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case QuoteCategory.motivation:
        return Colors.orange;
      case QuoteCategory.wisdom:
        return Colors.purple;
      case QuoteCategory.love:
        return Colors.pink;
      case QuoteCategory.success:
        return Colors.green;
      case QuoteCategory.life:
        return Colors.blue;
      case QuoteCategory.happiness:
        return Colors.amber;
      case QuoteCategory.faith:
        return Colors.teal;
      case QuoteCategory.friendship:
        return Colors.indigo;
      case QuoteCategory.knowledge:
        return Colors.brown;
      case QuoteCategory.other:
        return Colors.grey;
    }
  }
}

/// الحالة المزاجية لليومية
enum DiaryMood {
  amazing,
  happy,
  neutral,
  sad,
  terrible,
}

extension DiaryMoodExtension on DiaryMood {
  String get arabicName {
    switch (this) {
      case DiaryMood.amazing:
        return 'رائع';
      case DiaryMood.happy:
        return 'سعيد';
      case DiaryMood.neutral:
        return 'عادي';
      case DiaryMood.sad:
        return 'حزين';
      case DiaryMood.terrible:
        return 'سيء';
    }
  }

  IconData get icon {
    switch (this) {
      case DiaryMood.amazing:
        return Icons.sentiment_very_satisfied;
      case DiaryMood.happy:
        return Icons.sentiment_satisfied;
      case DiaryMood.neutral:
        return Icons.sentiment_neutral;
      case DiaryMood.sad:
        return Icons.sentiment_dissatisfied;
      case DiaryMood.terrible:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Color get color {
    switch (this) {
      case DiaryMood.amazing:
        return const Color(0xFF4CAF50);
      case DiaryMood.happy:
        return const Color(0xFF8BC34A);
      case DiaryMood.neutral:
        return const Color(0xFFFFEB3B);
      case DiaryMood.sad:
        return const Color(0xFFFF9800);
      case DiaryMood.terrible:
        return const Color(0xFFF44336);
    }
  }

  String get emoji {
    switch (this) {
      case DiaryMood.amazing:
        return '🤩';
      case DiaryMood.happy:
        return '😊';
      case DiaryMood.neutral:
        return '😐';
      case DiaryMood.sad:
        return '😢';
      case DiaryMood.terrible:
        return '😭';
    }
  }
}

/// موديل المدخل (اقتباس أو يومية)
class EntryModel {
  final String? id;
  final String userId;
  final EntryType type;
  final String content;
  final String? title; // لليوميات
  final String? author; // للاقتباسات
  final String? source; // مصدر الاقتباس
  final QuoteCategory? quoteCategory;
  final DiaryMood? mood;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final bool isPrivate;
  final List<String> tags;
  final String? imageUrl;
  final String? backgroundColor;
  final int? fontStyle; // 0: normal, 1: italic, 2: handwritten

  EntryModel({
    this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.title,
    this.author,
    this.source,
    this.quoteCategory,
    this.mood,
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.isPrivate = true,
    this.tags = const [],
    this.imageUrl,
    this.backgroundColor,
    this.fontStyle,
  });

  /// تحويل من Firestore
  factory EntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EntryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: EntryType.values.firstWhere(
        (e) => e.name == data['entryType'],
        orElse: () => EntryType.quote,
      ),
      content: data['content'] ?? data['text'] ?? '',
      title: data['title'],
      author: data['author'],
      source: data['source'],
      quoteCategory: data['quoteCategory'] != null
          ? QuoteCategory.values.firstWhere(
              (e) => e.name == data['quoteCategory'],
              orElse: () => QuoteCategory.other,
            )
          : null,
      mood: data['mood'] != null
          ? DiaryMood.values.firstWhere(
              (e) => e.name == data['mood'],
              orElse: () => DiaryMood.neutral,
            )
          : null,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isFavorite: data['isFavorite'] ?? false,
      isPrivate: data['isPrivate'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      backgroundColor: data['backgroundColor'],
      fontStyle: data['fontStyle'],
    );
  }

  /// تحويل إلى Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': 'quote_diary', // نوع الـ note في Firebase
      'entryType': type.name,
      'content': content,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (source != null) 'source': source,
      if (quoteCategory != null) 'quoteCategory': quoteCategory!.name,
      if (mood != null) 'mood': mood!.name,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'isFavorite': isFavorite,
      'isPrivate': isPrivate,
      'tags': tags,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (fontStyle != null) 'fontStyle': fontStyle,
    };
  }

  /// نسخة معدلة
  EntryModel copyWith({
    String? id,
    String? userId,
    EntryType? type,
    String? content,
    String? title,
    String? author,
    String? source,
    QuoteCategory? quoteCategory,
    DiaryMood? mood,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isPrivate,
    List<String>? tags,
    String? imageUrl,
    String? backgroundColor,
    int? fontStyle,
  }) {
    return EntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      author: author ?? this.author,
      source: source ?? this.source,
      quoteCategory: quoteCategory ?? this.quoteCategory,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isPrivate: isPrivate ?? this.isPrivate,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontStyle: fontStyle ?? this.fontStyle,
    );
  }

  /// هل هو اقتباس؟
  bool get isQuote => type == EntryType.quote;

  /// هل هو يومية؟
  bool get isDiary => type == EntryType.diary;

  /// الوصف المختصر
  String get shortContent {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }
}
