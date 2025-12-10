// lib/core/models/note.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum NoteCategory {
  personal('Personal'),
  work('Work'),
  study('Study'),
  ideas('Ideas'),
  tasks('Tasks'),
  appointments('Appointments'),
  expenses('Expenses'),
  quotes('Quotes');

  const NoteCategory(this.displayName);
  final String displayName;
}

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final NoteCategory category;
  final DateTime dateCreated;
  final DateTime dateModified;
  final List<String> tags;
  final bool isArchived;
  final String userId;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.dateCreated,
    required this.dateModified,
    this.tags = const [],
    this.isArchived = false,
    required this.userId,
  });

  // Copy with method for immutable updates
  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteCategory? category,
    DateTime? dateCreated,
    DateTime? dateModified,
    List<String>? tags,
    bool? isArchived,
    String? userId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? DateTime.now(),
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      userId: userId ?? this.userId,
    );
  }

  // Convert Note object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.name,
      'dateCreated': dateCreated.toUtc().toIso8601String(),
      'dateModified': dateModified.toUtc().toIso8601String(),
      'tags': tags,
      'isArchived': isArchived,
      'userId': userId,
    };
  }

  // Create Note object from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: _parseCategory(json['category']),
      dateCreated: _parseDateTime(json['dateCreated']),
      dateModified: _parseDateTime(json['dateModified']),
      tags: _parseTags(json['tags']),
      isArchived: json['isArchived'] as bool? ?? false,
      userId: json['userId'] as String? ?? '',
    );
  }

  // Create Note from Firestore Document
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  // Helper method to parse category
  static NoteCategory _parseCategory(dynamic category) {
    if (category is String) {
      try {
        return NoteCategory.values.firstWhere(
              (e) => e.name == category,
          orElse: () => NoteCategory.personal,
        );
      } catch (_) {
        return NoteCategory.personal;
      }
    }
    return NoteCategory.personal;
  }

  // Helper method to parse DateTime
  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString is String) {
      try {
        return DateTime.parse(dateString).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    } else if (dateString is Timestamp) {
      return dateString.toDate();
    }
    return DateTime.now();
  }

  // Helper method to parse tags
  static List<String> _parseTags(dynamic tags) {
    if (tags is List) {
      return tags.whereType<String>().toList();
    }
    return [];
  }

  // Validation methods
  bool get isValid => title.trim().isNotEmpty && content.trim().isNotEmpty;

  bool get hasTags => tags.isNotEmpty;

  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // Equatable props
  @override
  List<Object?> get props => [
    id,
    title,
    content,
    category,
    dateCreated,
    dateModified,
    tags,
    isArchived,
    userId,
  ];

  // String representation for debugging
  @override
  String toString() {
    return 'Note(id: $id, title: $title, category: $category, created: $dateCreated)';
  }
}

// Extension for additional functionality
extension NoteExtensions on Note {
  bool containsText(String searchText) {
    final lowerText = searchText.toLowerCase();
    return title.toLowerCase().contains(lowerText) ||
        content.toLowerCase().contains(lowerText) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerText));
  }

  bool isInCategory(NoteCategory noteCategory) => category == noteCategory;

  DateTime get displayDate => dateModified;
}
