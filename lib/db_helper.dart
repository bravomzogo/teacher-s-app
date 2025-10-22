import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/student.dart';
import 'models/session.dart';
import 'models/progress.dart';
import 'models/timetable.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  static const int _version = 5; // Updated to version 5 for end notifications

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'teacher_manager.db');
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Migration from version 1 to 2
      await _createTables(db);
    }

    if (oldVersion < 3) {
      // Migration from version 2 to 3 - Add new student columns
      await _migrateToV3(db);
    }

    if (oldVersion < 4) {
      // Migration from version 3 to 4 - Add timetable table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS timetable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL,
          dayOfWeek TEXT NOT NULL,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          classroom TEXT,
          notificationsEnabled INTEGER DEFAULT 1,
          notificationMinutesBefore INTEGER DEFAULT 15,
          createdAt TEXT DEFAULT (datetime('now'))
        )
      ''');
    }

    if (oldVersion < 5) {
      // Migration from version 4 to 5 - Add end notification columns
      try {
        await db.execute(
            'ALTER TABLE timetable ADD COLUMN endNotificationsEnabled INTEGER DEFAULT 0'
        );
        print('Added endNotificationsEnabled column');
      } catch (e) {
        print('Column endNotificationsEnabled might already exist: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE timetable ADD COLUMN endNotificationMinutesBefore INTEGER DEFAULT 0'
        );
        print('Added endNotificationMinutesBefore column');
      } catch (e) {
        print('Column endNotificationMinutesBefore might already exist: $e');
      }
    }
  }

  Future _migrateToV3(Database db) async {
    // Check if the old 'name' column exists
    final tableInfo = await db.rawQuery('PRAGMA table_info(students)');
    final hasNameColumn = tableInfo.any((column) => column['name'] == 'name');

    if (hasNameColumn) {
      // Migrate data from old schema to new schema
      await db.execute('''
        CREATE TABLE students_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firstName TEXT NOT NULL,
          middleName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          gender TEXT,
          grade TEXT,
          createdAt TEXT DEFAULT (datetime('now'))
        )
      ''');

      // Copy data from old table to new table
      final oldStudents = await db.query('students');
      for (var oldStudent in oldStudents) {
        // Split the old 'name' field into first, middle, last names
        final oldName = oldStudent['name'] as String? ?? '';
        final nameParts = oldName.split(' ');

        String firstName = '';
        String middleName = '';
        String lastName = '';

        if (nameParts.isNotEmpty) firstName = nameParts[0];
        if (nameParts.length > 1) lastName = nameParts.last;
        if (nameParts.length > 2) {
          middleName = nameParts.sublist(1, nameParts.length - 1).join(' ');
        }

        await db.insert('students_new', {
          'id': oldStudent['id'],
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'gender': oldStudent['gender'],
          'grade': oldStudent['grade'],
          'createdAt': oldStudent['createdAt'],
        });
      }

      // Drop old table and rename new table
      await db.execute('DROP TABLE students');
      await db.execute('ALTER TABLE students_new RENAME TO students');
    } else {
      // Fresh install - just create the table with new schema
      await db.execute('''
        CREATE TABLE IF NOT EXISTS students (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firstName TEXT NOT NULL,
          middleName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          gender TEXT,
          grade TEXT,
          createdAt TEXT DEFAULT (datetime('now'))
        )
      ''');
    }
  }

  Future _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        middleName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        gender TEXT,
        grade TEXT,
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT,
        notes TEXT,
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        sessionId INTEGER NOT NULL,
        score REAL,
        remarks TEXT,
        createdAt TEXT DEFAULT (datetime('now')),
        FOREIGN KEY(studentId) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY(sessionId) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');

    // Add timetable table with end notification columns
    await db.execute('''
      CREATE TABLE IF NOT EXISTS timetable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        dayOfWeek TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        classroom TEXT,
        notificationsEnabled INTEGER DEFAULT 1,
        notificationMinutesBefore INTEGER DEFAULT 15,
        endNotificationsEnabled INTEGER DEFAULT 0,
        endNotificationMinutesBefore INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');
  }

  // Students CRUD
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return await db.insert('students', s.toMap());
  }

  Future<int> updateStudent(Student s) async {
    final db = await database;
    return await db.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final rows = await db.query('students', orderBy: 'firstName COLLATE NOCASE');
    return rows.map((r) => Student.fromMap(r)).toList();
  }

  Future<void> bulkInsertStudents(List<Student> list) async {
    final db = await database;
    final batch = db.batch();
    for (var s in list) {
      batch.insert('students', s.toMap());
    }
    await batch.commit(noResult: true);
  }

  // Sessions CRUD
  Future<int> insertSession(Session s) async {
    final db = await database;
    return await db.insert('sessions', s.toMap());
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final rows = await db.query('sessions', orderBy: 'date DESC');
    return rows.map((r) => Session.fromMap(r)).toList();
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // Progress CRUD
  Future<int> insertProgress(Progress p) async {
    final db = await database;
    return await db.insert('progress', p.toMap());
  }

  Future<int> updateProgress(Progress p) async {
    final db = await database;
    return await db.update('progress', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deleteProgress(int id) async {
    final db = await database;
    return await db.delete('progress', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Progress>> getProgressForSession(int sessionId) async {
    final db = await database;
    final rows = await db.query('progress', where: 'sessionId = ?', whereArgs: [sessionId]);
    return rows.map((r) => Progress.fromMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getProgressJoined(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.id as progressId, p.score, p.remarks, s.id as studentId, s.firstName, s.middleName, s.lastName, s.grade
      FROM progress p
      JOIN students s ON s.id = p.studentId
      WHERE p.sessionId = ?
      ORDER BY s.firstName COLLATE NOCASE
    ''', [sessionId]);
    return result;
  }

  // Analytics
  Future<List<Map<String, dynamic>>> getStudentProgressSummary(int studentId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.title, p.score, p.remarks, p.createdAt
      FROM progress p
      JOIN sessions s ON s.id = p.sessionId
      WHERE p.studentId = ?
      ORDER BY p.createdAt DESC
    ''', [studentId]);
  }

  Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as totalStudents,
        AVG(score) as averageScore,
        MAX(score) as maxScore,
        MIN(score) as minScore
      FROM progress 
      WHERE sessionId = ?
    ''', [sessionId]);

    return result.isNotEmpty ? result.first : {};
  }

  // Timetable CRUD operations
  Future<int> insertTimetable(Timetable t) async {
    final db = await database;
    return await db.insert('timetable', t.toMap());
  }

  Future<int> updateTimetable(Timetable t) async {
    final db = await database;
    return await db.update('timetable', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTimetable(int id) async {
    final db = await database;
    return await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Timetable>> getAllTimetable() async {
    final db = await database;
    final rows = await db.query('timetable', orderBy: 'dayOfWeek, startTime');
    return rows.map((r) => Timetable.fromMap(r)).toList();
  }

  Future<List<Timetable>> getTimetableForDay(String day) async {
    final db = await database;
    final rows = await db.query(
        'timetable',
        where: 'dayOfWeek = ?',
        whereArgs: [day],
        orderBy: 'startTime'
    );
    return rows.map((r) => Timetable.fromMap(r)).toList();
  }
}