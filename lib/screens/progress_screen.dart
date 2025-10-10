import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../models/progress.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final DBHelper db = DBHelper();
  List<Session> sessions = [];
  List<Student> students = [];
  int? selectedSessionId;
  List<Map<String, dynamic>> progressEntries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    sessions = await db.getAllSessions();
    students = await db.getAllStudents();
    if (sessions.isNotEmpty && selectedSessionId == null) {
      selectedSessionId = sessions.first.id;
    }
    await _loadProgress();
    setState(() => loading = false);
  }

  Future<void> _loadProgress() async {
    if (selectedSessionId == null) {
      progressEntries = [];
      setState(() {});
      return;
    }
    progressEntries = await db.getProgressJoined(selectedSessionId!);
    setState(() {});
  }

  Future<void> _openAddProgressDialog() async {
    if (selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create or select a session first')),
      );
      return;
    }

    int? chosenStudentId;
    double? score;
    final remarksCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Record Progress',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: chosenStudentId,
                    decoration: InputDecoration(
                      labelText: 'Select Student *',
                      prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: students.map((student) {
                      return DropdownMenuItem(
                        value: student.id,
                        child: Text(student.fullName),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => chosenStudentId = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Score',
                      prefixIcon: const Icon(Icons.score, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => setState(() => score = double.tryParse(value)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: remarksCtrl,
                    decoration: InputDecoration(
                      labelText: 'Remarks',
                      prefixIcon: const Icon(Icons.comment, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            );
          },
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
              if (chosenStudentId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a student')),
                );
                return;
              }

              await db.insertProgress(Progress(
                studentId: chosenStudentId!,
                sessionId: selectedSessionId!,
                score: score,
                remarks: remarksCtrl.text.trim(),
              ));

              Navigator.pop(context);
              await _loadProgress();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress recorded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _editProgress(int progressId, int studentId, String studentName, double? currentScore, String? currentRemarks) async {
    double? score = currentScore;
    final remarksCtrl = TextEditingController(text: currentRemarks);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Progress for $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: score?.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Score'),
              onChanged: (value) => score = double.tryParse(value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(labelText: 'Remarks'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await db.updateProgress(Progress(
                id: progressId,
                studentId: studentId,
                sessionId: selectedSessionId!,
                score: score,
                remarks: remarksCtrl.text.trim(),
              ));
              Navigator.pop(context);
              await _loadProgress();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProgress(int id) async {
    await db.deleteProgress(id);
    await _loadProgress();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress record deleted'),
        backgroundColor: Colors.red,
      ),
    );
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
                colors: [Colors.orange.shade600, Colors.red.shade600],
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
                        'Progress Tracking',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadAll,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track and manage student progress across sessions',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : _buildProgressContent(),
          ),
        ],
      ),
      floatingActionButton: sessions.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _openAddProgressDialog,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.assignment_add),
        label: const Text('Record Progress'),
        elevation: 4,
      )
          : null,
    );
  }

  Widget _buildProgressContent() {
    if (sessions.isEmpty) {
      return _buildEmptySessionsState();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Session Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.book, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedSessionId,
                    decoration: const InputDecoration(
                      labelText: 'Select Session',
                      border: InputBorder.none,
                    ),
                    items: sessions.map((session) {
                      return DropdownMenuItem(
                        value: session.id,
                        child: Text(session.title),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() => selectedSessionId = value);
                      await _loadProgress();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress List
          Expanded(
            child: progressEntries.isEmpty
                ? _buildEmptyProgressState()
                : _buildProgressList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySessionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No Sessions Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create sessions first to track student progress',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProgressState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No Progress Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add progress records for this session using the + button',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: progressEntries.length,
        itemBuilder: (_, index) {
          final entry = progressEntries[index];
          final progressId = entry['progressId'] as int;
          final studentId = entry['studentId'] as int;
          final firstName = entry['firstName'] as String;
          final lastName = entry['lastName'] as String;
          final fullName = '$firstName $lastName';
          final score = entry['score'];
          final remarks = entry['remarks'] ?? '';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(score),
                  child: Text(
                    score != null ? score.toString() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (score != null) Text('Score: $score'),
                    if (remarks.isNotEmpty)
                      Text(
                        remarks.length > 50 ? '${remarks.substring(0, 50)}...' : remarks,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editProgress(
                        progressId,
                        studentId,
                        fullName,
                        score != null ? (score as num).toDouble() : null,
                        remarks,
                      ),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteProgress(progressId),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    if (score == null) return Colors.grey;
    final numScore = (score as num).toDouble();
    if (numScore >= 80) return Colors.green;
    if (numScore >= 60) return Colors.orange;
    return Colors.red;
  }
}