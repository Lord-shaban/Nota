// local_notifications_service.dart
// ------------------------------------------------------------
// Local Notifications Service
// Inspired by alNota's notification system
// Handles reminders and scheduled notifications
// ------------------------------------------------------------

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Local Notifications Service
/// Manages all local push notifications for tasks and appointments
class LocalNotificationsService {
  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();

  factory LocalNotificationsService() => _instance;

  LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notifications service
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // Combined settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = initialized ?? false;
      return _initialized;
    } catch (e) {
      print('❌ Notifications Init Error: $e');
      return false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on payload
  }

  /// Request permissions (iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Android doesn't need runtime permission
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'nota_channel',
      'Nota Notifications',
      channelDescription: 'Notifications for tasks and appointments',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'nota_channel',
      'Nota Notifications',
      channelDescription: 'Scheduled notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule reminder for task
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    final id = taskId.hashCode;
    await scheduleNotification(
      id: id,
      title: '⏰ تذكير بمهمة',
      body: taskTitle,
      scheduledTime: reminderTime,
      payload: 'task:$taskId',
    );
  }

  /// Schedule appointment reminder
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String appointmentTitle,
    required DateTime appointmentTime,
    int minutesBefore = 15,
  }) async {
    final id = appointmentId.hashCode;
    final reminderTime =
        appointmentTime.subtract(Duration(minutes: minutesBefore));

    await scheduleNotification(
      id: id,
      title: '📅 تذكير بموعد',
      body: '$appointmentTitle - بعد $minutesBefore دقيقة',
      scheduledTime: reminderTime,
      payload: 'appointment:$appointmentId',
    );
  }

  /// Schedule daily reminder (alNota feature)
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'nota_daily_channel',
      'Daily Reminders',
      channelDescription: 'Daily repeating notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel notification by item ID
  Future<void> cancelTaskNotification(String taskId) async {
    final id = taskId.hashCode;
    await cancelNotification(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if initialized
  bool get isInitialized => _initialized;
}

/// Notification Helper Methods
extension NotificationHelpers on LocalNotificationsService {
  /// Quick task reminder (15 minutes from now)
  Future<void> quickTaskReminder(String taskId, String taskTitle) async {
    final reminderTime = DateTime.now().add(const Duration(minutes: 15));
    await scheduleTaskReminder(
      taskId: taskId,
      taskTitle: taskTitle,
      reminderTime: reminderTime,
    );
  }

  /// Morning reminder (9 AM daily)
  Future<void> morningReminder() async {
    await scheduleDailyReminder(
      id: 1000,
      title: '☀️ صباح الخير!',
      body: 'لديك مهام جديدة اليوم',
      hour: 9,
      minute: 0,
    );
  }

  /// Evening reminder (6 PM daily)
  Future<void> eveningReminder() async {
    await scheduleDailyReminder(
      id: 1001,
      title: '🌙 تذكير مسائي',
      body: 'راجع مهامك قبل نهاية اليوم',
      hour: 18,
      minute: 0,
    );
  }
}
