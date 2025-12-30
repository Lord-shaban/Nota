import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// نموذج بيانات الموعد المحسّن
class AppointmentModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final DateTime? endTime;
  final String type;
  final String notes;
  final List<String> attendees;
  final String priority; // high, medium, low
  final String status; // pending, confirmed, cancelled, completed
  final bool hasReminder;
  final int? reminderMinutes;
  final String? repeatType; // none, daily, weekly, monthly
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.location = '',
    required this.dateTime,
    this.endTime,
    required this.type,
    this.notes = '',
    this.attendees = const [],
    this.priority = 'medium',
    this.status = 'pending',
    this.hasReminder = false,
    this.reminderMinutes,
    this.repeatType,
    required this.createdAt,
    this.updatedAt,
  });

  /// إنشاء من Firestore
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      type: data['type'] ?? 'general',
      notes: data['notes'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      hasReminder: data['hasReminder'] ?? false,
      reminderMinutes: data['reminderMinutes'],
      repeatType: data['repeatType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// إنشاء من Map مع ID
  factory AppointmentModel.fromMap(Map<String, dynamic> data, String id) {
    return AppointmentModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      type: data['type'] ?? 'general',
      notes: data['notes'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      hasReminder: data['hasReminder'] ?? false,
      reminderMinutes: data['reminderMinutes'],
      repeatType: data['repeatType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  /// تحويل إلى Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'type': type,
      'notes': notes,
      'attendees': attendees,
      'priority': priority,
      'status': status,
      'hasReminder': hasReminder,
      'reminderMinutes': reminderMinutes,
      'repeatType': repeatType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// حساب مدة الموعد
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(dateTime);
  }

  /// هل الموعد في الماضي؟
  bool get isPast => dateTime.isBefore(DateTime.now());

  /// هل الموعد اليوم؟
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// هل الموعد غداً؟
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  /// هل الموعد قريب (خلال ساعتين)؟
  bool get isUpcoming {
    final now = DateTime.now();
    final diff = dateTime.difference(now);
    return !isPast && diff.inHours <= 2 && diff.inMinutes > 0;
  }

  /// هل الموعد جاري الآن؟
  bool get isOngoing {
    final now = DateTime.now();
    if (endTime == null) return false;
    return now.isAfter(dateTime) && now.isBefore(endTime!);
  }

  /// عدد الأيام حتى الموعد
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return appointmentDate.difference(today).inDays;
  }

  /// نسخة معدّلة
  AppointmentModel copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? dateTime,
    DateTime? endTime,
    String? type,
    String? notes,
    List<String>? attendees,
    String? priority,
    String? status,
    bool? hasReminder,
    int? reminderMinutes,
    String? repeatType,
  }) {
    return AppointmentModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      attendees: attendees ?? this.attendees,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      repeatType: repeatType ?? this.repeatType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// أنواع المواعيد
enum AppointmentType {
  meeting('meeting', 'اجتماع', Icons.groups, Color(0xFF3B82F6)),
  doctor('doctor', 'طبي', Icons.local_hospital, Color(0xFFEF4444)),
  personal('personal', 'شخصي', Icons.person, Color(0xFF10B981)),
  work('work', 'عمل', Icons.work, Color(0xFFF59E0B)),
  event('event', 'مناسبة', Icons.celebration, Color(0xFF8B5CF6)),
  reminder('reminder', 'تذكير', Icons.notifications_active, Color(0xFFEC4899)),
  study('study', 'دراسة', Icons.school, Color(0xFF06B6D4)),
  sport('sport', 'رياضة', Icons.fitness_center, Color(0xFF84CC16)),
  travel('travel', 'سفر', Icons.flight, Color(0xFF0EA5E9)),
  general('general', 'عام', Icons.event, Color(0xFF6366F1));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const AppointmentType(this.value, this.label, this.icon, this.color);

  static AppointmentType fromString(String value) {
    return AppointmentType.values.firstWhere(
      (t) => t.value == value.toLowerCase(),
      orElse: () => AppointmentType.general,
    );
  }
}

/// أولوية الموعد
enum AppointmentPriority {
  high('high', 'عالية', Icons.priority_high, Color(0xFFEF4444)),
  medium('medium', 'متوسطة', Icons.remove, Color(0xFFF59E0B)),
  low('low', 'منخفضة', Icons.arrow_downward, Color(0xFF10B981));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const AppointmentPriority(this.value, this.label, this.icon, this.color);

  static AppointmentPriority fromString(String value) {
    return AppointmentPriority.values.firstWhere(
      (p) => p.value == value.toLowerCase(),
      orElse: () => AppointmentPriority.medium,
    );
  }
}

/// حالة الموعد
enum AppointmentStatus {
  pending('pending', 'قيد الانتظار', Icons.schedule, Color(0xFFF59E0B)),
  confirmed('confirmed', 'مؤكد', Icons.check_circle, Color(0xFF10B981)),
  cancelled('cancelled', 'ملغي', Icons.cancel, Color(0xFFEF4444)),
  completed('completed', 'مكتمل', Icons.task_alt, Color(0xFF6366F1));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const AppointmentStatus(this.value, this.label, this.icon, this.color);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (s) => s.value == value.toLowerCase(),
      orElse: () => AppointmentStatus.pending,
    );
  }
}
