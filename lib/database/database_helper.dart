import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'memora.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        time TEXT NOT NULL,
        is_taken INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        priority TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        phone TEXT NOT NULL,
        is_primary INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Users
  Future<int> insertUser(Map<String, Object?> user) async {
    final db = await database;
    return db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Map<String, Object?>?> findUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);
    return result.isNotEmpty;
  }

  Future<int> updateUserPassword(String email, String newPassword) async {
    final db = await database;
    return db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // Medications
  Future<int> insertMedication(Map<String, Object?> medication) async {
    final db = await database;
    return db.insert('medications', medication);
  }

  Future<List<Map<String, Object?>>> getMedications({int? userId}) async {
    final db = await database;
    return db.query('medications', where: userId == null ? null : 'user_id = ?', whereArgs: userId == null ? null : [userId], orderBy: 'id DESC');
  }

  Future<int> updateMedication(int id, Map<String, Object?> medication) async {
    final db = await database;
    return db.update('medications', medication, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // Tasks
  Future<int> insertTask(Map<String, Object?> task) async {
    final db = await database;
    return db.insert('tasks', task);
  }

  Future<List<Map<String, Object?>>> getTasks({int? userId}) async {
    final db = await database;
    return db.query('tasks', where: userId == null ? null : 'user_id = ?', whereArgs: userId == null ? null : [userId], orderBy: 'id DESC');
  }

  Future<int> updateTask(int id, Map<String, Object?> task) async {
    final db = await database;
    return db.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Contacts
  Future<int> insertContact(Map<String, Object?> contact) async {
    final db = await database;
    return db.insert('contacts', contact);
  }

  Future<List<Map<String, Object?>>> getContacts({int? userId}) async {
    final db = await database;
    return db.query('contacts', where: userId == null ? null : 'user_id = ?', whereArgs: userId == null ? null : [userId], orderBy: 'id DESC');
  }

  Future<int> updateContact(int id, Map<String, Object?> contact) async {
    final db = await database;
    return db.update('contacts', contact, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
