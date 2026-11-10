import 'package:sqflite/sqflite.dart';
import '../models/project.dart';
import 'db_helper.dart';

class ProjectRepository {
  ProjectRepository({DbHelper? helper}) : _helper = helper ?? DbHelper.instance;

  final DbHelper _helper;
  static const _table = DbHelper.tableProjects;
  static const _tagsTable = DbHelper.tableProjectTags;

  // ---------- CREATE ----------
  Future<int> insert(Project project) async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      final id = await txn.insert(_table, project.toMap());
      await _insertTags(txn, id, project.tags);
      return id;
    });
  }

  // ---------- READ ----------
  Future<List<Project>> getAll({
    String query = '',
    String? category,
    bool favoritesOnly = false,
  }) async {
    final db = await _helper.database;
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (query.isNotEmpty) {
      conditions.add('''
        (
          p.title LIKE ? OR p.description LIKE ? OR p.tech_stack LIKE ? OR
          p.category LIKE ? OR EXISTS (
            SELECT 1 FROM $_tagsTable search_tags
            WHERE search_tags.project_id = p.id AND search_tags.tag LIKE ?
          )
        )
      ''');
      final search = '%$query%';
      arguments.addAll([search, search, search, search, search]);
    }
    if (category != null) {
      conditions.add('p.category = ?');
      arguments.add(category);
    }
    if (favoritesOnly) conditions.add('p.is_favorite = 1');
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT p.*, project_tags.tag AS tag_value
      FROM $_table p
      LEFT JOIN $_tagsTable project_tags ON project_tags.project_id = p.id
      $where
      ORDER BY p.is_favorite DESC, p.created_at DESC, project_tags.id ASC
    ''', arguments);

    final projects = <int, Project>{};
    final tagsByProject = <int, List<String>>{};
    for (final row in rows) {
      final project = Project.fromMap(row);
      final id = project.id!;
      projects.putIfAbsent(id, () => project);
      final tag = row['tag_value'] as String?;
      if (tag != null) tagsByProject.putIfAbsent(id, () => []).add(tag);
    }
    return projects.entries
        .map(
          (entry) => entry.value.copyWith(tags: tagsByProject[entry.key] ?? []),
        )
        .toList();
  }

  Future<int> count() async {
    final db = await _helper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------- UPDATE ----------
  Future<int> update(Project project) async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      final updated = await txn.update(
        _table,
        project.toMap(),
        where: 'id = ?',
        whereArgs: [project.id],
      );
      if (updated > 0) {
        await txn.delete(
          _tagsTable,
          where: 'project_id = ?',
          whereArgs: [project.id],
        );
        await _insertTags(txn, project.id!, project.tags);
      }
      return updated;
    });
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

  Future<int> deleteAll() async {
    final db = await _helper.database;
    return db.delete(_table);
  }

  Future<void> _insertTags(
    DatabaseExecutor db,
    int projectId,
    List<String> tags,
  ) async {
    final uniqueTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    for (final tag in uniqueTags) {
      await db.insert(_tagsTable, {'project_id': projectId, 'tag': tag});
    }
  }
}
