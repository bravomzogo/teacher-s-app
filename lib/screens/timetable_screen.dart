import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/timetable.dart';
import '../services/notification_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final DBHelper db = DBHelper();
  final NotificationService notifications = NotificationService();
  List<Timetable> timetable = [];
  bool loading = true;
  String selectedDay = 'Monday';

  final List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTimetable();
  }

  Future<void> _initializeNotifications() async {
    await notifications.initialize();
  }

  Future<void> _loadTimetable() async {
    setState(() => loading = true);
    timetable = await db.getAllTimetable();
    setState(() => loading = false);
  }

  Future<void> _showAddTimetableDialog({Timetable? edit}) async {
    final subjectCtrl = TextEditingController(text: edit?.subject ?? '');
    final classroomCtrl = TextEditingController(text: edit?.classroom ?? '');
    TimeOfDay startTime = edit != null
        ? _parseTime(edit.startTime)
        : const TimeOfDay(hour: 9, minute: 0); // Changed to non-nullable
    TimeOfDay endTime = edit != null
        ? _parseTime(edit.endTime)
        : const TimeOfDay(hour: 10, minute: 0); // Changed to non-nullable
    String selectedDayValue = edit?.dayOfWeek ?? 'Monday';
    bool notificationsEnabled = edit?.notificationsEnabled ?? true;
    int notificationMinutes = edit?.notificationMinutesBefore ?? 15;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              edit == null ? 'Add Class' : 'Edit Class',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectCtrl,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      prefixIcon: const Icon(Icons.subject, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDayValue,
                    decoration: InputDecoration(
                      labelText: 'Day of Week',
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: daysOfWeek.map((day) {
                      return DropdownMenuItem(value: day, child: Text(day));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDayValue = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 12)),
                            ListTile(
                              leading: const Icon(Icons.access_time, color: Colors.deepPurple),
                              title: Text(startTime.format(context)),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                );
                                if (time != null) setState(() => startTime = time);
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 12)),
                            ListTile(
                              leading: const Icon(Icons.access_time, color: Colors.deepPurple),
                              title: Text(endTime.format(context)),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                );
                                if (time != null) setState(() => endTime = time);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: classroomCtrl,
                    decoration: InputDecoration(
                      labelText: 'Classroom',
                      prefixIcon: const Icon(Icons.room, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: notificationsEnabled,
                    onChanged: (value) => setState(() => notificationsEnabled = value),
                    secondary: const Icon(Icons.notifications, color: Colors.deepPurple),
                  ),
                  if (notificationsEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Notify me'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: notificationMinutes,
                          items: [5, 10, 15, 30, 60].map((minutes) {
                            return DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes minutes before'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => notificationMinutes = value);
                            }
                          },
                        ),
                        const Text('class'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (subjectCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  // Now startTime and endTime are guaranteed to be non-null
                  final startTimeString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                  final endTimeString = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                  final timetableEntry = Timetable(
                    id: edit?.id,
                    subject: subjectCtrl.text.trim(),
                    dayOfWeek: selectedDayValue,
                    startTime: startTimeString,
                    endTime: endTimeString,
                    classroom: classroomCtrl.text.trim().isEmpty ? null : classroomCtrl.text.trim(),
                    notificationsEnabled: notificationsEnabled,
                    notificationMinutesBefore: notificationMinutes,
                  );

                  if (edit == null) {
                    await db.insertTimetable(timetableEntry);
                  } else {
                    await db.updateTimetable(timetableEntry);
                  }

                  Navigator.pop(context);
                  await _loadTimetable();
                  await _rescheduleNotifications();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${edit == null ? 'Added' : 'Updated'} ${timetableEntry.subject}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _rescheduleNotifications() async {
    final allTimetable = await db.getAllTimetable();
    await notifications.rescheduleAllTimetableNotifications(allTimetable);
  }

  Future<void> _confirmDelete(Timetable t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Class?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete ${t.subject} on ${t.dayOfWeek}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await db.deleteTimetable(t.id!);
      await notifications.cancelNotification(t.id!);
      await _loadTimetable();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${t.subject}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Timetable> _getTimetableForSelectedDay() {
    return timetable.where((entry) => entry.dayOfWeek == selectedDay).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade600, Colors.deepOrange.shade600],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Timetable',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadTimetable,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your class schedule and get reminders',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Day Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.9),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: daysOfWeek.map((day) {
                  final isSelected = day == selectedDay;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (_) => setState(() => selectedDay = day),
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: Colors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : _getTimetableForSelectedDay().isEmpty
                ? _buildEmptyState()
                : _buildTimetableList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTimetableDialog(),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No Classes Scheduled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first class using the + button',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Text(
            'Selected day: $selectedDay',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableList() {
    final dayTimetable = _getTimetableForSelectedDay();

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: dayTimetable.length,
        itemBuilder: (_, index) {
          final entry = dayTimetable[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                entry.subject,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.classroom != null && entry.classroom!.isNotEmpty)
                    Text(
                      'Room: ${entry.classroom}',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  if (entry.notificationsEnabled)
                    Text(
                      '🔔 ${entry.notificationMinutesBefore}min before',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showAddTimetableDialog(edit: entry),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(entry),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}