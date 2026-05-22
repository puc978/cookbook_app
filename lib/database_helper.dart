import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  // Singleton pattern
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the path to the database file
    String path = join(await getDatabasesPath(), 'cookbook_database.db');

    // await deleteDatabase(path); // TODO: TEMPORARY DELETE DB
    // Open/create the database
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create the tables
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeName TEXT NOT NULL,
        ingredients TEXT,
        instruction TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }


  // CREATE - Insert a new task
  Future<int> insertTask(Task task) async {
    Database db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  // READ - Get all tasks
  Future<List<Task>> getAllTasks() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // READ - Get task by ID
  Future<Task?> getTask(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Update a task
  Future<int> updateTask(Task task) async {
    Database db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // DELETE - Delete a task
  Future<int> deleteTask(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Delete all tasks
  Future<int> deleteAllTasks() async {
    Database db = await instance.database;
    return await db.delete('tasks');
  }

}