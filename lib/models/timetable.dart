import 'package:flutter/material.dart'; // Add this import

class Timetable {
  final int? id;
  final String subject;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? classroom;
  final bool notificationsEnabled;
  final int notificationMinutesBefore;
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
    'createdAt': createdAt,
  };

  factory Timetable.fromMap(Map<String, dynamic> m) => Timetable(
    id: m['id'],
    subject: m['subject'],
    dayOfWeek: m['dayOfWeek'],
    startTime: m['startTime'],
    endTime: m['endTime'],
    classroom: m['classroom'],
    notificationsEnabled: m['notificationsEnabled'] == 1,
    notificationMinutesBefore: m['notificationMinutesBefore'],
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

  DateTime get nextOccurrence {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _daysOfWeek.indexOf(dayOfWeek);
    var nextDate = today.add(Duration(days: (days - today.weekday + 7) % 7));

    // If it's today but time has passed, schedule for next week
    final timeParts = startTime.split(':');
    final classTime = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1])
    );

    if (classTime.isBefore(now)) {
      nextDate = nextDate.add(const Duration(days: 7));
    }

    return nextDate;
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