import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cookbook_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
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

  Future<int> insertTask(Task task) async {
    Database db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getAllTasks() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

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

  Future<int> updateTask(Task task) async {
    Database db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTasks() async {
    Database db = await instance.database;
    return await db.delete('tasks');
  }

  Future<void> exportDatabase() async {
    final db = await database;

    final tempDir = await getTemporaryDirectory();

    final exportFile = File(
      '${tempDir.path}/cookbook_backup.db',
    );

    if (await exportFile.exists()) {
      await exportFile.delete();
    }

    await File(db.path).copy(exportFile.path);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(exportFile.path)],
        text: 'cookbook database backup',
        title: 'export database',
      ),
    );
  }

  Future<void> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final selectedPath = result.files.single.path!;

    final importedDb = await openDatabase(
      selectedPath,
      readOnly: true,
    );

    final currentDb = await database;

    try {
      final tables = await importedDb.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type='table' AND name='tasks'",
      );

      if (tables.isEmpty) {
        throw Exception('Invalid cookbook database.');
      }

      final importedRecipes = await importedDb.query('tasks');

      await currentDb.transaction((txn) async {
        for (final recipe in importedRecipes) {
          final exists = await txn.query(
            'tasks',
            where: '''
              recipeName = ?
              AND ingredients = ?
              AND instruction = ?
              AND createdAt = ?
            ''',
            whereArgs: [
              recipe['recipeName'],
              recipe['ingredients'],
              recipe['instruction'],
              recipe['createdAt'],
            ],
            limit: 1,
          );

          if (exists.isNotEmpty) {
            continue;
          }

          final newRecipe = Map<String, dynamic>.from(recipe);
          newRecipe.remove('id');

          await txn.insert(
            'tasks',
            newRecipe,
          );
        }
      });
    } finally {
      await importedDb.close();
    }
  }
}