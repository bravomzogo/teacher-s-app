import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../models/session.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final DBHelper db = DBHelper();
  List<Session> sessions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    sessions = await db.getAllSessions();
    setState(() => loading = false);
  }

  Future<void> _showAddSession({Session? edit}) async {
    final titleCtrl = TextEditingController(text: edit?.title ?? '');
    final notesCtrl = TextEditingController(text: edit?.notes ?? '');
    DateTime chosenDate = edit != null && edit.date != null
        ? DateTime.tryParse(edit.date!) ?? DateTime.now()
        : DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          edit == null ? 'Create Session' : 'Edit Session',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Session Title *',
                      prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM dd, yyyy').format(chosenDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        FilledButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: chosenDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => chosenDate = picked);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Session Notes',
                      prefixIcon: const Icon(Icons.notes, color: Colors.deepPurple),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 4,
                  ),
                ],
              );
            },
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
              if (titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a session title')),
                );
                return;
              }

              final session = Session(
                id: edit?.id,
                title: titleCtrl.text.trim(),
                date: chosenDate.toIso8601String(),
                notes: notesCtrl.text.trim(),
              );

              if (edit == null) {
                await db.insertSession(session);
              } else {
                // Update logic would go here
              }

              Navigator.pop(context);
              await _load();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${edit == null ? 'Created' : 'Updated'} session "${session.title}"'),
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

  Future<void> _confirmDelete(Session s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete "${s.title}"? This action cannot be undone.'),
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
      await db.deleteSession(s.id!);
      await _load();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted session "${s.title}"'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                colors: [Colors.teal.shade600, Colors.green.shade600],
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
                        'Sessions',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your teaching sessions and track student progress',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : sessions.isEmpty
                ? _buildEmptyState()
                : _buildSessionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSession(),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No Sessions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first session to start tracking progress',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (_, index) {
          final session = sessions[index];
          final dateStr = session.date != null
              ? DateFormat('MMM dd, yyyy').format(DateTime.parse(session.date!))
              : 'No date';

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.book, color: Colors.teal.shade700),
              ),
              title: Text(
                session.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (session.notes != null && session.notes!.isNotEmpty)
                    Text(
                      session.notes!.length > 60
                          ? '${session.notes!.substring(0, 60)}...'
                          : session.notes!,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showAddSession(edit: session),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(session),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              onTap: () {
                _showSessionDetails(session);
              },
            ),
          );
        },
      ),
    );
  }

  void _showSessionDetails(Session session) {
    final dateStr = session.date != null
        ? DateFormat('MMMM dd, yyyy').format(DateTime.parse(session.date!))
        : 'Not set';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Date:', dateStr),
            if (session.notes != null && session.notes!.isNotEmpty)
              _buildDetailRow('Notes:', session.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}