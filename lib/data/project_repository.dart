import 'package:sqflite/sqflite.dart';
import '../models/project.dart';
import 'db_helper.dart';

class ProjectRepository {
  ProjectRepository({DbHelper? helper})
      : _helper = helper ?? DbHelper.instance;

  final DbHelper _helper;
  static const _table = DbHelper.tableProjects;

  // ---------- CREATE ----------
  Future<int> insert(Project project) async {
    final db = await _helper.database;
    return db.insert(_table, project.toMap()); // mengembalikan id baru
  }

  // ---------- READ ----------
  Future<List<Project>> getAll({String query = ''}) async {
    final db = await _helper.database;
    final rows = await db.query(
      _table,
      where: query.isEmpty ? null : 'title LIKE ?',
      whereArgs: query.isEmpty ? null : ['%$query%'],
      orderBy: 'created_at DESC', // terbaru di atas
    );
    return rows.map(Project.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _helper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------- UPDATE ----------
  Future<int> update(Project project) async {
    final db = await _helper.database;
    return db.update(
      _table,
      project.toMap(),
      where: 'id = ?', // ⚠️ jangan pernah dihilangkan
      whereArgs: [project.id],
    );
  }

  // ---------- DELETE ----------
  Future<int> delete(int id) async {
    final db = await _helper.database;
    return db.delete(
      _table,
      where: 'id = ?', // ⚠️ jangan pernah dihilangkan
      whereArgs: [id],
    );
  }
}