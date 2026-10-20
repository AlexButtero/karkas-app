import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/project.dart';

class ProjectRepository {
  ProjectRepository._();
  static final ProjectRepository instance = ProjectRepository._();

  static const _dbName = 'house_designer.db';
  static const _table = 'projects';
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            dimensions TEXT NOT NULL,
            frame_params TEXT NOT NULL,
            prices TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<Project>> getAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'updated_at DESC');
    return rows.map(Project.fromMap).toList();
  }

  // --- ВОТ ЭТОТ МЕТОД БЫЛ ПРОПУЩЕН ---
  Future<Project?> getById(int id) async {
    final db = await _database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }
  // -----------------------------------

  Future<int> insert(Project p) async {
    final db = await _database;
    return db.insert(_table, p.toMap());
  }

  Future<void> update(Project p) async {
    if (p.id == null) return;
    final db = await _database;
    await db.update(_table, p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
