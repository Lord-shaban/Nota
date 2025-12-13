import 'package:cloud_firestore/cloud_firestore.dart';

/// Task Group Model - Represents a collection of related tasks
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class TaskGroup {
  final String id;
  final String title;
  final String? description;
  final String color; // Hex color code
  final String icon; // Icon name or emoji
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final int totalTasks;
  final int completedTasks;
  final List<String> taskIds; // References to tasks in this group

  TaskGroup({
    required this.id,
    required this.title,
    this.description,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.taskIds = const [],
  });

  // Calculate completion percentage
  double get completionPercentage {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  // Check if all tasks are completed
  bool get isCompleted => totalTasks > 0 && completedTasks == totalTasks;

  // Factory constructor from Firestore document
  factory TaskGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskGroup(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      color: data['color'] ?? '#58CC02',
      icon: data['icon'] ?? '📋',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId'] ?? '',
      totalTasks: data['totalTasks'] ?? 0,
      completedTasks: data['completedTasks'] ?? 0,
      taskIds: List<String>.from(data['taskIds'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'userId': userId,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'taskIds': taskIds,
    };
  }

  // CopyWith method for easy updates
  TaskGroup copyWith({
    String? id,
    String? title,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? totalTasks,
    int? completedTasks,
    List<String>? taskIds,
  }) {
    return TaskGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      taskIds: taskIds ?? this.taskIds,
    );
  }
}
