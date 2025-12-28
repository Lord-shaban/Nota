import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج بيانات الموعد
class AppointmentModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final String type;
  final String notes;
  final List<String> attendees;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.location = '',
    required this.dateTime,
    required this.type,
    this.notes = '',
    this.attendees = const [],
    this.isCompleted = false,
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
      type: data['type'] ?? 'general',
      notes: data['notes'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'type': type,
      'notes': notes,
      'attendees': attendees,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
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

  /// هل الموعد قريب (خلال ساعتين)؟
  bool get isUpcoming {
    final now = DateTime.now();
    final diff = dateTime.difference(now);
    return !isPast && diff.inHours <= 2;
  }

  /// نسخة معدّلة
  AppointmentModel copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? dateTime,
    String? type,
    String? notes,
    List<String>? attendees,
    bool? isCompleted,
  }) {
    return AppointmentModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      attendees: attendees ?? this.attendees,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// أنواع المواعيد
enum AppointmentType {
  meeting('meeting', 'اجتماع', '👥'),
  doctor('doctor', 'طبي', '🏥'),
  personal('personal', 'شخصي', '👤'),
  work('work', 'عمل', '💼'),
  event('event', 'حدث', '🎉'),
  reminder('reminder', 'تذكير', '🔔'),
  general('general', 'عام', '📅');

  final String value;
  final String label;
  final String emoji;

  const AppointmentType(this.value, this.label, this.emoji);

  static AppointmentType fromString(String value) {
    return AppointmentType.values.firstWhere(
      (t) => t.value == value.toLowerCase(),
      orElse: () => AppointmentType.general,
    );
  }
}
