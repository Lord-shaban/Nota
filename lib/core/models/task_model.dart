import 'package:cloud_firestore/cloud_firestore.dart';

/// Task Model - Represents an individual task with enhanced features
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String userId;
  final String? groupId; // Reference to TaskGroup
  final List<String> tags;
  final String? notes;
  final int sortOrder; // For custom ordering within a group

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 'medium',
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    required this.userId,
    this.groupId,
    this.tags = const [],
    this.notes,
    this.sortOrder = 0,
  });

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  // Check if task is due this week
  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    return dueDate!.isBefore(endOfWeek) && dueDate!.isAfter(now);
  }

  // Get priority color
  String get priorityColor {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return '#FF3B30'; // Red
      case 'high':
        return '#FF9500'; // Orange
      case 'medium':
        return '#FFD900'; // Yellow
      case 'low':
        return '#58CC02'; // Green
      default:
        return '#8E8E93'; // Gray
    }
  }

  // Get priority icon
  String get priorityIcon {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return '🔴';
      case 'high':
        return '🟠';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  // Factory constructor from Firestore document
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId'] ?? '',
      groupId: data['groupId'],
      tags: List<String>.from(data['tags'] ?? []),
      notes: data['notes'],
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'type': 'task',
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'userId': userId,
      'groupId': groupId,
      'tags': tags,
      'notes': notes,
      'sortOrder': sortOrder,
    };
  }

  // CopyWith method for easy updates
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    String? userId,
    String? groupId,
    List<String>? tags,
    String? notes,
    int? sortOrder,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
