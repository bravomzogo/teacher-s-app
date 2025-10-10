import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/timetable.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );

    print('Notification service initialized');
  }

  Future<void> scheduleTimetableNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleTime,
  }) async {
    try {
      // Simple vibration pattern (vibrate for 500ms)
      final vibrationPattern = Int64List(4);
      vibrationPattern[0] = 0; // Start immediately
      vibrationPattern[1] = 500; // Vibrate for 500ms
      vibrationPattern[2] = 500; // Pause for 500ms
      vibrationPattern[3] = 500; // Vibrate for 500ms

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'timetable_channel',
        'Timetable Reminders',
        channelDescription: 'Notifications for your class schedule',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        playSound: true,
        autoCancel: true,
      );

      const darwinPlatformChannelSpecifics = DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: darwinPlatformChannelSpecifics,
      );

      final scheduledTime = tz.TZDateTime.from(scheduleTime, tz.local);

      print('Scheduling notification:');
      print('  ID: $id');
      print('  Title: $title');
      print('  Body: $body');
      print('  Scheduled for: $scheduledTime');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        payload: 'timetable_$id',
      );

      print('Notification scheduled successfully!');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('Cancelled notification with id: $id');
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('Cancelled all notifications');
  }

  Future<void> rescheduleAllTimetableNotifications(List<Timetable> timetable) async {
    print('Rescheduling ${timetable.length} timetable notifications...');

    await cancelAllNotifications();

    for (var entry in timetable) {
      if (entry.notificationsEnabled && entry.id != null) {
        final notificationTime = entry.nextOccurrence.subtract(
            Duration(minutes: entry.notificationMinutesBefore)
        );

        if (notificationTime.isAfter(DateTime.now())) {
          await scheduleTimetableNotification(
            id: entry.id!,
            title: 'Class Reminder: ${entry.subject}',
            body: 'Your ${entry.subject} class starts at ${entry.startTime}${entry.classroom != null ? ' in ${entry.classroom}' : ''}',
            scheduleTime: notificationTime,
          );
        } else {
          print('Skipping past notification for ${entry.subject}');
        }
      }
    }

    print('Finished rescheduling notifications');
  }

  // Test method to check if notifications are working
  Future<void> testNotification() async {
    await scheduleTimetableNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification from EduTrack Pro',
      scheduleTime: DateTime.now().add(const Duration(seconds: 5)),
    );
  }
}