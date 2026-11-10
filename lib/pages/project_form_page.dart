import 'package:flutter/material.dart';
import '../data/project_repository.dart';
import '../models/project.dart';

class ProjectFormPage extends StatefulWidget {
  const ProjectFormPage({super.key, this.project, this.repository});
  final Project? project; // null = mode tambah
  final ProjectRepository? repository; // null = mode tambah

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = widget.repository ?? ProjectRepository();

  late final _title = TextEditingController(text: widget.project?.title);
  late final _desc = TextEditingController(text: widget.project?.description);
  late final _tech = TextEditingController(text: widget.project?.techStack);

  bool _saving = false;
  bool get _isEdit => widget.project != null;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _tech.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final old = widget.project;
    final project = Project(
      id: old?.id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      techStack: _tech.text.trim(),
      createdAt: old?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEdit) {
        await _repo.update(project);
      } else {
        await _repo.insert(project);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan proyek: $error')));
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true); // true = ada perubahan, list perlu refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Proyek' : 'Tambah Proyek')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Judul proyek',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tech,
              decoration: const InputDecoration(
                labelText: 'Teknologi (contoh: Flutter, Dart)',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
