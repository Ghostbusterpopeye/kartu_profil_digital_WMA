import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._(); // constructor private: tidak bisa dibuat sembarangan
  static final DbHelper instance = DbHelper._(); // satu-satunya objek

  static const _dbName = 'kartu_profil.db';
  static const _dbVersion = 3;

  static const tableProjects = 'projects';
  static const tableProjectTags = 'project_tags';

  Database? _db;

  /// Membuka database saat pertama kali dibutuhkan, lalu dipakai ulang.
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Dipanggil SEKALI, saat file database pertama kali dibuat.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        tech_stack TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'Umum'
      )
    ''');
    await _createProjectTags(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableProjects '
        'ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE $tableProjects "
        "ADD COLUMN category TEXT NOT NULL DEFAULT 'Umum'",
      );
      await _createProjectTags(db);
    }
  }

  Future<void> _createProjectTags(Database db) async {
    await db.execute('''
      CREATE TABLE $tableProjectTags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES $tableProjects(id) ON DELETE CASCADE,
        UNIQUE (project_id, tag)
      )
    ''');
  }
}
