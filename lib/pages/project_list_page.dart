import 'package:flutter/material.dart';
import '../data/project_repository.dart';
import '../models/project.dart';
import 'project_form_page.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyek Saya')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: ProjectListSection(),
      ),
    );
  }
}

class ProjectListSection extends StatefulWidget {
  const ProjectListSection({super.key, this.repository});

  final ProjectRepository? repository;

  @override
  State<ProjectListSection> createState() => _ProjectListSectionState();
}

class _ProjectListSectionState extends State<ProjectListSection> {
  late final _repo = widget.repository ?? ProjectRepository();
  late Future<List<Project>> _future = _repo.getAll();

  void _reload() {
    setState(() {
      _future = _repo.getAll();
    });
  }

  Future<void> _openForm([Project? project]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectFormPage(project: project, repository: _repo),
      ),
    );
    if (changed == true) _reload();
  }

  Future<void> _confirmDelete(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus proyek?'),
        content: Text('"${project.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);

    final id = project.id;
    if (id == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Proyek tidak memiliki ID yang valid')),
      );
      return;
    }

    try {
      final deleted = await _repo.delete(id);
      if (!mounted) return;
      _reload();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleted > 0
                ? '"${project.title}" dihapus'
                : '"${project.title}" tidak ditemukan atau sudah dihapus',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus proyek: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Proyek Saya', style: Theme.of(context).textTheme.titleLarge),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Project>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Terjadi kesalahan: ${snapshot.error}');
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada proyek.\nTekan + untuk menambahkan.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: [
                for (final p in items)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(p.title),
                      subtitle: Text(
                        '${p.techStack}\n${p.description}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      onTap: () => _openForm(p),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus',
                        onPressed: () => _confirmDelete(p),
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
