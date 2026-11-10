import 'package:flutter/material.dart';
import '../data/project_repository.dart';
import '../models/project.dart';
import 'project_form_page.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key, this.repository});

  final ProjectRepository? repository;

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  late final _repo = widget.repository ?? ProjectRepository();
  final _sectionKey = GlobalKey<ProjectListSectionState>();

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus semua proyek?'),
        content: const Text(
          'Semua proyek dan tag terkait akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final deleted = await _repo.deleteAll();
      if (!mounted) return;
      _sectionKey.currentState?.reload();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleted == 0
                ? 'Tidak ada proyek untuk dihapus'
                : '$deleted proyek dihapus',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus semua proyek: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyek Saya'),
        actions: [
          IconButton(
            onPressed: _confirmDeleteAll,
            tooltip: 'Hapus Semua',
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ProjectListSection(key: _sectionKey, repository: _repo),
    );
  }
}

class ProjectListSection extends StatefulWidget {
  const ProjectListSection({super.key, this.repository});

  final ProjectRepository? repository;

  @override
  ProjectListSectionState createState() => ProjectListSectionState();
}

class ProjectListSectionState extends State<ProjectListSection> {
  late final _repo = widget.repository ?? ProjectRepository();
  late Future<List<Project>> _future = _repo.getAll();
  String _query = '';
  String? _category;
  bool _favoritesOnly = false;

  void reload() {
    if (!mounted) return;
    setState(() {
      _future = _repo.getAll(
        query: _query,
        category: _category,
        favoritesOnly: _favoritesOnly,
      );
    });
  }

  Future<void> _openForm([Project? project]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectFormPage(project: project, repository: _repo),
      ),
    );
    if (changed == true) reload();
  }

  Future<void> _toggleFavorite(Project project) async {
    final id = project.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyek tidak memiliki ID yang valid')),
      );
      return;
    }

    try {
      await _repo.update(project.copyWith(isFavorite: !project.isFavorite));
      reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah favorit: $error')));
    }
  }

  Future<void> _deleteProject(Project project) async {
    final id = project.id;
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyek tidak memiliki ID yang valid')),
      );
      reload();
      return;
    }

    try {
      final deleted = await _repo.delete(id);
      if (!mounted) return;
      reload();
      if (deleted == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyek tidak ditemukan atau sudah dihapus'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${project.title}" dihapus'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => _undoDelete(project),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      reload();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus proyek: $error')));
    }
  }

  Future<void> _undoDelete(Project project) async {
    try {
      await _repo.insert(project);
      reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengurungkan penghapusan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
          style: FilledButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Cari proyek atau tag',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _query = '';
                      reload();
                    },
                  ),
          ),
          onChanged: (value) {
            _query = value.trim();
            reload();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Favorit'),
              selected: _favoritesOnly,
              onSelected: (selected) {
                _favoritesOnly = selected;
                reload();
              },
            ),
            FilterChip(
              label: const Text('Semua kategori'),
              selected: _category == null,
              onSelected: (_) {
                _category = null;
                reload();
              },
            ),
            for (final category in Project.categories)
              FilterChip(
                label: Text(category),
                selected: _category == category,
                onSelected: (_) {
                  _category = category;
                  reload();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Project>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text('Terjadi kesalahan: ${snapshot.error}');
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada proyek yang cocok dengan filter.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: [
                for (final project in items)
                  Dismissible(
                    key: ValueKey(project.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Theme.of(context).colorScheme.error,
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    onDismissed: (_) => _deleteProject(project),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(project.title),
                        subtitle: Text(
                          '${project.techStack} • ${project.category}\n'
                          '${project.description}'
                          '${project.tags.isEmpty ? '' : '\nTag: ${project.tags.join(', ')}'}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        onTap: () => _openForm(project),
                        trailing: IconButton(
                          icon: Icon(
                            project.isFavorite ? Icons.star : Icons.star_border,
                          ),
                          tooltip: 'Favorit',
                          onPressed: () => _toggleFavorite(project),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
