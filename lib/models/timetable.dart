import 'package:flutter/material.dart';

class Timetable {
  final int? id;
  final String subject;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? classroom;
  final bool notificationsEnabled;
  final int notificationMinutesBefore;
  final bool endNotificationsEnabled;
  final int endNotificationMinutesBefore;
  final String? createdAt;

  Timetable({
    this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroom,
    this.notificationsEnabled = true,
    this.notificationMinutesBefore = 15,
    this.endNotificationsEnabled = false,
    this.endNotificationMinutesBefore = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject': subject,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'classroom': classroom,
    'notificationsEnabled': notificationsEnabled ? 1 : 0,
    'notificationMinutesBefore': notificationMinutesBefore,
    'endNotificationsEnabled': endNotificationsEnabled ? 1 : 0,
    'endNotificationMinutesBefore': endNotificationMinutesBefore,
    'createdAt': createdAt,
  };

  factory Timetable.fromMap(Map<String, dynamic> m) => Timetable(
    id: m['id'],
    subject: m['subject'],
    dayOfWeek: m['dayOfWeek'],
    startTime: m['startTime'],
    endTime: m['endTime'],
    classroom: m['classroom'],
    notificationsEnabled: (m['notificationsEnabled'] ?? 1) == 1,
    notificationMinutesBefore: m['notificationMinutesBefore'] ?? 15,
    endNotificationsEnabled: (m['endNotificationsEnabled'] ?? 0) == 1,
    endNotificationMinutesBefore: m['endNotificationMinutesBefore'] ?? 0,
    createdAt: m['createdAt'],
  );

  String get displayTime => '$startTime - $endTime';

  Color get color {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];
    final index = subject.hashCode % colors.length;
    return colors[index.abs()];
  }

  int get dayOfWeekIndex {
    return _daysOfWeek.indexOf(dayOfWeek) + 1; // 1=Monday, 7=Sunday
  }

  DateTime get nextOccurrence {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayIndex = _daysOfWeek.indexOf(dayOfWeek);
    if (dayIndex == -1) {
      throw ArgumentError('Invalid dayOfWeek: $dayOfWeek');
    }
    final targetWeekday = dayIndex + 1; // Adjust to 1=Monday, 7=Sunday
    final currentWeekday = today.weekday;
    var daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
    var nextDate = today.add(Duration(days: daysToAdd));

    // Parse startTime, handling possible 12-hour format with AM/PM
    String timeStr = startTime.trim();
    bool isPM = false;
    if (timeStr.endsWith(' PM')) {
      timeStr = timeStr.substring(0, timeStr.length - 3).trim();
      isPM = true;
    } else if (timeStr.endsWith(' AM')) {
      timeStr = timeStr.substring(0, timeStr.length - 3).trim();
    }
    final timeParts = timeStr.split(':');
    if (timeParts.length < 2) {
      throw ArgumentError('Invalid startTime format: $startTime');
    }
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1].split(' ')[0]); // In case extra space

    // Convert 12-hour to 24-hour if necessary
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    DateTime classTime = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      hour,
      minute,
    );

    // If the class time has already passed, schedule for next week
    if (classTime.isBefore(now)) {
      final futureDate = nextDate.add(const Duration(days: 7));
      classTime = DateTime(
        futureDate.year,
        futureDate.month,
        futureDate.day,
        hour,
        minute,
      );
    }

    return classTime;
  }

  DateTime get nextEndOccurrence {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayIndex = _daysOfWeek.indexOf(dayOfWeek);
    if (dayIndex == -1) {
      throw ArgumentError('Invalid dayOfWeek: $dayOfWeek');
    }
    final targetWeekday = dayIndex + 1;
    final currentWeekday = today.weekday;
    var daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
    var nextDate = today.add(Duration(days: daysToAdd));

    // Parse endTime
    String timeStr = endTime.trim();
    bool isPM = false;
    if (timeStr.endsWith(' PM')) {
      timeStr = timeStr.substring(0, timeStr.length - 3).trim();
      isPM = true;
    } else if (timeStr.endsWith(' AM')) {
      timeStr = timeStr.substring(0, timeStr.length - 3).trim();
    }
    final timeParts = timeStr.split(':');
    if (timeParts.length < 2) {
      throw ArgumentError('Invalid endTime format: $endTime');
    }
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1].split(' ')[0]);

    // Convert 12-hour to 24-hour if necessary
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    DateTime classEndTime = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      hour,
      minute,
    );

    // If the class end time has already passed, schedule for next week
    if (classEndTime.isBefore(now)) {
      final futureDate = nextDate.add(const Duration(days: 7));
      classEndTime = DateTime(
        futureDate.year,
        futureDate.month,
        futureDate.day,
        hour,
        minute,
      );
    }

    return classEndTime;
  }

  static final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
}