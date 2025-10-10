import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../db_helper.dart';
import '../models/student.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final DBHelper db = DBHelper();
  List<Student> students = [];
  bool loading = true;
  final TextEditingController searchController = TextEditingController();
  List<Student> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _load();
    searchController.addListener(_filterStudents);
  }

  Future<void> _load() async {
    setState(() => loading = true);
    students = await db.getAllStudents();
    filteredStudents = students;
    setState(() => loading = false);
  }

  void _filterStudents() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredStudents = students.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.firstName.toLowerCase().contains(query) ||
            student.lastName.toLowerCase().contains(query) ||
            (student.grade?.toLowerCase() ?? '').contains(query) ||
            (student.gender?.toLowerCase() ?? '').contains(query);
      }).toList();
    });
  }

  Future<void> _showAddDialog({Student? edit}) async {
    final firstNameCtrl = TextEditingController(text: edit?.firstName ?? '');
    final middleNameCtrl = TextEditingController(text: edit?.middleName ?? '');
    final lastNameCtrl = TextEditingController(text: edit?.lastName ?? '');
    final gradeCtrl = TextEditingController(text: edit?.grade ?? '');
    String? selectedGender = edit?.gender;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          edit == null ? 'Add Student' : 'Edit Student',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(firstNameCtrl, 'First Name *', Icons.person, true),
                const SizedBox(height: 12),
                _buildTextField(middleNameCtrl, 'Middle Name', Icons.person_outline, false),
                const SizedBox(height: 12),
                _buildTextField(lastNameCtrl, 'Last Name *', Icons.person_outline, true),
                const SizedBox(height: 12),
                _buildTextField(gradeCtrl, 'Grade', Icons.school, false),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.transgender, color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => selectedGender = value,
                ),
              ],
            ),
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
              if (formKey.currentState!.validate()) {
                final student = Student(
                  id: edit?.id,
                  firstName: firstNameCtrl.text.trim(),
                  middleName: middleNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  gender: selectedGender,
                  grade: gradeCtrl.text.trim(),
                );

                if (edit == null) {
                  await db.insertStudent(student);
                } else {
                  await db.updateStudent(student);
                }

                Navigator.pop(context);
                await _load();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${edit == null ? 'Added' : 'Updated'} ${student.fullName}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      } : null,
    );
  }

  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final csvString = await File(filePath).readAsString();

        List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

        if (csvData.length < 2) {
          throw Exception('CSV file is empty or has only headers');
        }

        List<Student> studentsToImport = [];
        int successCount = 0;
        int errorCount = 0;

        for (int i = 1; i < csvData.length; i++) {
          try {
            final row = csvData[i];
            if (row.length >= 2) {
              String firstName = '';
              String middleName = '';
              String lastName = '';
              String? gender;
              String? grade;

              // Detect format: if 3+ columns, assume first,middle,last format
              if (row.length >= 3) {
                firstName = row[0].toString().trim();
                middleName = row[1].toString().trim();
                lastName = row[2].toString().trim();
                if (row.length > 3) gender = row[3].toString().trim();
                if (row.length > 4) grade = row[4].toString().trim();
              } else {
                // Fallback: first and last name only
                firstName = row[0].toString().trim();
                lastName = row[1].toString().trim();
                if (row.length > 2) gender = row[2].toString().trim();
                if (row.length > 3) grade = row[3].toString().trim();
              }

              if (firstName.isNotEmpty && lastName.isNotEmpty) {
                final student = Student(
                  firstName: firstName,
                  middleName: middleName,
                  lastName: lastName,
                  gender: gender,
                  grade: grade,
                );
                studentsToImport.add(student);
                successCount++;
              } else {
                errorCount++;
              }
            }
          } catch (e) {
            errorCount++;
          }
        }

        if (studentsToImport.isNotEmpty) {
          await db.bulkInsertStudents(studentsToImport);
          await _load();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $successCount students${errorCount > 0 ? ', $errorCount failed' : ''}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid student data found in CSV'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing CSV: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCSVTemplate() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('CSV Format Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Required format for CSV import:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'First Name, Middle Name, Last Name, Gender, Grade\n'
                      'John,Michael,Smith,Male,Grade 10\n'
                      'Sarah,,Johnson,Female,Grade 9\n'
                      'James,Robert,Wilson,Male,Grade 11',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Alternative format (without middle name):'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'First Name, Last Name, Gender, Grade\n'
                      'John,Smith,Male,Grade 10\n'
                      'Sarah,Johnson,Female,Grade 9',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Note:'),
              const Text('• First Name and Last Name are required'),
              const Text('• Middle Name is optional'),
              const Text('• Gender and Grade are optional'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete ${s.fullName}? This action cannot be undone.'),
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
      await db.deleteStudent(s.id!);
      await _load();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${s.fullName}'),
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
                colors: [Colors.deepPurple.shade600, Colors.purple.shade600],
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
                        'Students',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _showCSVTemplate,
                            icon: const Icon(Icons.help_outline, color: Colors.white),
                            tooltip: 'CSV Format Guide',
                          ),
                          IconButton(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search students...',
                        prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _importCSV,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import CSV'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : filteredStudents.isEmpty
                ? _buildEmptyState()
                : _buildStudentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.deepPurple,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No Students Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            searchController.text.isEmpty
                ? 'Add your first student using the + button'
                : 'Try adjusting your search terms',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: filteredStudents.length,
        itemBuilder: (_, index) {
          final student = filteredStudents[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: student.avatarColor,
                child: Text(
                  student.avatarText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                student.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (student.grade != null && student.grade!.isNotEmpty)
                    Text('Grade: ${student.grade}'),
                  if (student.gender != null && student.gender!.isNotEmpty)
                    Text('Gender: ${student.gender}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showAddDialog(edit: student),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(student),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              onTap: () {
                _showStudentDetails(student);
              },
            ),
          );
        },
      ),
    );
  }

  void _showStudentDetails(Student student) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('First Name:', student.firstName),
            if (student.middleName.isNotEmpty) _buildDetailRow('Middle Name:', student.middleName),
            _buildDetailRow('Last Name:', student.lastName),
            if (student.gender != null) _buildDetailRow('Gender:', student.gender!),
            if (student.grade != null) _buildDetailRow('Grade:', student.grade!),
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
            width: 80,
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}