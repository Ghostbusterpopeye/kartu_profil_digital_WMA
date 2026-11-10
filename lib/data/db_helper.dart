import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  DbHelper._(); // constructor private: tidak bisa dibuat sembarangan
  static final DbHelper instance = DbHelper._(); // satu-satunya objek

  static const _dbName = 'kartu_profil.db';
  static const _dbVersion = 1;

  static const tableProjects = 'projects';

  Database? _db;

  /// Membuka database saat pertama kali dibutuhkan, lalu dipakai ulang.
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
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
        created_at TEXT NOT NULL
      )
    ''');
  }
}