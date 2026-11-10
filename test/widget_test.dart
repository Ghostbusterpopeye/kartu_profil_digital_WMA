import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kartu_profil_digital/main.dart';
import 'package:kartu_profil_digital/data/project_repository.dart';
import 'package:kartu_profil_digital/pages/project_form_page.dart';
import 'package:kartu_profil_digital/pages/project_list_page.dart';
import 'package:kartu_profil_digital/models/project.dart';
import 'package:kartu_profil_digital/services/pref_service.dart';

class _FakeProjectRepository extends ProjectRepository {
  _FakeProjectRepository(this.projects);

  final List<Project> projects;

  @override
  Future<int> count() async => projects.length;

  @override
  Future<int> insert(Project project) async {
    final id =
        project.id ??
        (projects.fold<int>(0, (maxId, item) {
              final itemId = item.id ?? 0;
              return itemId > maxId ? itemId : maxId;
            }) +
            1);
    projects.add(
      Project(
        id: id,
        title: project.title,
        description: project.description,
        techStack: project.techStack,
        createdAt: project.createdAt,
        isFavorite: project.isFavorite,
        category: project.category,
        tags: project.tags,
      ),
    );
    return id;
  }

  @override
  Future<List<Project>> getAll({
    String query = '',
    String? category,
    bool favoritesOnly = false,
  }) async {
    final normalizedQuery = query.toLowerCase();
    return projects.where((project) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          [
            project.title,
            project.description,
            project.techStack,
            project.category,
            ...project.tags,
          ].any((value) => value.toLowerCase().contains(normalizedQuery));
      return matchesQuery &&
          (category == null || project.category == category) &&
          (!favoritesOnly || project.isFavorite);
    }).toList()..sort((a, b) {
      final favoriteOrder = (b.isFavorite ? 1 : 0).compareTo(
        a.isFavorite ? 1 : 0,
      );
      return favoriteOrder != 0
          ? favoriteOrder
          : b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Future<int> update(Project project) async {
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index == -1) return 0;
    projects[index] = project;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    final count = projects.length;
    projects.removeWhere((project) => project.id == id);
    return count - projects.length;
  }

  @override
  Future<int> deleteAll() async {
    final count = projects.length;
    projects.clear();
    return count;
  }
}

void main() {
  test('project favorite values round-trip through SQLite maps', () {
    final project = Project(
      id: 1,
      title: 'Proyek Favorit',
      description: 'Deskripsi',
      techStack: 'Flutter',
      createdAt: DateTime(2026),
      isFavorite: true,
    );

    expect(project.toMap()['is_favorite'], 1);
    expect(Project.fromMap(project.toMap()).isFavorite, isTrue);
    final legacyMap = project.toMap()..remove('is_favorite');
    expect(Project.fromMap(legacyMap).isFavorite, isFalse);
    expect(project.copyWith(isFavorite: false).isFavorite, isFalse);
  });

  test('project category defaults for records without the migrated column', () {
    final project = Project(
      id: 2,
      title: 'Proyek Web',
      description: 'Deskripsi',
      techStack: 'Flutter',
      createdAt: DateTime(2026),
      category: 'Web',
      tags: ['api'],
    );
    expect(project.toMap()['category'], 'Web');
    expect(project.toMap().containsKey('tags'), isFalse);

    final oldProject = Project.fromMap({
      'id': 1,
      'title': 'Proyek Lama',
      'description': 'Deskripsi',
      'tech_stack': 'Dart',
      'created_at': DateTime(2026).toIso8601String(),
      'is_favorite': 0,
    });

    expect(oldProject.category, 'Umum');
    expect(oldProject.tags, isEmpty);
  });

  testWidgets('profile, projects, and preferences are available', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
    final projectRepository = _FakeProjectRepository([]);
    await prefs.setHasSeenOnboarding(true);
    await prefs.increaseOpenCount();

    await tester.pumpWidget(
      MyApp(prefs: prefs, projectRepository: projectRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kartu Profil Digital'), findsOneWidget);
    expect(find.text('Sultan Shalahuddin Al Ayubi'), findsOneWidget);
    expect(find.text('Proyek Saya'), findsOneWidget);
    expect(find.text('0 proyek'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kartu ini sudah dibuka 1 kali'),
      300,
    );
    expect(find.text('Kartu ini sudah dibuka 1 kali'), findsOneWidget);
    expect(prefs.themeMode, ThemeMode.system);

    await tester.scrollUntilVisible(
      find.byType(DropdownButton<ThemeMode>),
      300,
    );
    await tester.tap(find.byType(DropdownButton<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Teal'),
      300,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Teal'));
    await tester.pumpAndSettle();

    expect(prefs.themeMode, ThemeMode.dark);
    expect(prefs.themeColor, const Color(0xFF009688));

    final reopenedPrefs = await PrefService.init();
    await tester.pumpWidget(const SizedBox.shrink());
    await reopenedPrefs.increaseOpenCount();
    await tester.pumpWidget(MyApp(prefs: reopenedPrefs));

    await tester.scrollUntilVisible(
      find.text('Kartu ini sudah dibuka 2 kali'),
      300,
    );
    expect(find.text('Kartu ini sudah dibuka 2 kali'), findsOneWidget);
    expect(reopenedPrefs.openCount, 2);
    expect(reopenedPrefs.themeMode, ThemeMode.dark);
    expect(reopenedPrefs.themeColor, const Color(0xFF009688));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.theme!.colorScheme.primary, isNot(const Color(0xFF3F51B5)));
  });

  testWidgets('profile edit date is saved as ISO 8601', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
    await prefs.setHasSeenOnboarding(true);
    await tester.pumpWidget(MyApp(prefs: prefs));

    await tester.tap(find.byTooltip('Edit profil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Bio baru');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final lastEdited = prefs.lastEdited!;
    expect(() => DateTime.parse(lastEdited), returnsNormally);
    expect(find.text('Terakhir diedit: $lastEdited'), findsOneWidget);

    final reopenedPrefs = await PrefService.init();
    expect(reopenedPrefs.lastEdited, lastEdited);
  });

  testWidgets('empty project form shows required field validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProjectFormPage()));

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(3));
  });

  testWidgets('project count refreshes after returning to profile', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
    await prefs.setHasSeenOnboarding(true);
    final projectRepository = _FakeProjectRepository([]);

    await tester.pumpWidget(
      MyApp(prefs: prefs, projectRepository: projectRepository),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 proyek'), findsOneWidget);

    await tester.tap(find.text('Proyek Saya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Proyek Baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'Flutter');
    await tester.enterText(find.byType(TextFormField).at(2), 'Deskripsi');
    await tester.enterText(find.byType(TextFormField).at(3), 'api, kampus');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Web').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Proyek Baru'), findsOneWidget);
    expect(projectRepository.projects.single.category, 'Web');
    expect(projectRepository.projects.single.tags, ['api', 'kampus']);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 proyek'), findsOneWidget);
  });

  testWidgets('search and chips filter by text, category, and favorite', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProjectRepository([
      Project(
        id: 1,
        title: 'API Kampus',
        description: 'Portal akademik',
        techStack: 'Flutter',
        createdAt: DateTime(2026, 1),
        isFavorite: true,
        category: 'Web',
        tags: ['rest'],
      ),
      Project(
        id: 2,
        title: 'Aplikasi Mobile',
        description: 'Aplikasi catatan',
        techStack: 'Dart',
        createdAt: DateTime(2026, 2),
        category: 'Mobile',
        tags: ['offline'],
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: ProjectListPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'rest');
    await tester.pumpAndSettle();
    expect(find.text('API Kampus'), findsOneWidget);
    expect(find.text('Aplikasi Mobile'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Mobile'));
    await tester.pumpAndSettle();
    expect(find.text('Aplikasi Mobile'), findsOneWidget);
    expect(find.text('API Kampus'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Semua kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Favorit'));
    await tester.pumpAndSettle();
    expect(find.text('API Kampus'), findsOneWidget);
    expect(find.text('Aplikasi Mobile'), findsNothing);
  });

  testWidgets('swiping a project away allows undo', (
    WidgetTester tester,
  ) async {
    final project = Project(
      id: 7,
      title: 'Proyek Urungkan',
      description: 'Deskripsi',
      techStack: 'Dart',
      createdAt: DateTime(2026),
      category: 'Web',
      tags: ['undo-tag'],
    );
    final repository = _FakeProjectRepository([project]);
    await tester.pumpWidget(
      MaterialApp(home: ProjectListPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('Proyek Urungkan'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(repository.projects, isEmpty);
    expect(find.text('"Proyek Urungkan" dihapus'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(repository.projects.single.id, 7);
    expect(repository.projects.single.category, 'Web');
    expect(repository.projects.single.tags, ['undo-tag']);
  });

  testWidgets('delete all requires confirmation and clears projects', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProjectRepository([
      Project(
        id: 1,
        title: 'Pertama',
        description: 'Deskripsi',
        techStack: 'Dart',
        createdAt: DateTime(2026),
      ),
      Project(
        id: 2,
        title: 'Kedua',
        description: 'Deskripsi',
        techStack: 'Flutter',
        createdAt: DateTime(2026, 2),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: ProjectListPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus Semua'));
    await tester.pumpAndSettle();
    expect(
      find.text('Semua proyek dan tag terkait akan dihapus permanen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repository.projects, hasLength(2));

    await tester.tap(find.byTooltip('Hapus Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus Semua'));
    await tester.pumpAndSettle();
    expect(repository.projects, isEmpty);
    expect(find.text('2 proyek dihapus'), findsOneWidget);
  });

  testWidgets('tapping a project edits it and refreshes the list', (
    WidgetTester tester,
  ) async {
    final project = Project(
      id: 1,
      title: 'Proyek Lama',
      description: 'Deskripsi lama',
      techStack: 'Flutter',
      createdAt: DateTime(2026),
      isFavorite: true,
    );
    final repository = _FakeProjectRepository([project]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectListSection(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proyek Lama'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Proyek'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Proyek Baru');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repository.projects.single.title, 'Proyek Baru');
    expect(repository.projects.single.isFavorite, isTrue);
    expect(find.text('Proyek Baru'), findsOneWidget);
  });

  testWidgets('favoriting a project moves it to the top of the list', (
    WidgetTester tester,
  ) async {
    final olderProject = Project(
      id: 1,
      title: 'Proyek Lama',
      description: 'Deskripsi lama',
      techStack: 'Dart',
      createdAt: DateTime(2026, 1),
    );
    final newerProject = Project(
      id: 2,
      title: 'Proyek Baru',
      description: 'Deskripsi baru',
      techStack: 'Flutter',
      createdAt: DateTime(2026, 2),
    );
    final repository = _FakeProjectRepository([olderProject, newerProject]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectListSection(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Favorit').first);
    await tester.pumpAndSettle();

    expect(repository.projects.last.isFavorite, isTrue);
    expect(repository.projects.last.title, 'Proyek Baru');
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Proyek Baru')).dy,
      lessThan(tester.getTopLeft(find.text('Proyek Lama')).dy),
    );
  });

  testWidgets('onboarding is shown once and remembered', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();

    await tester.pumpWidget(MyApp(prefs: prefs));
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Kartu Profil Digital'), findsNothing);
    expect(prefs.hasSeenOnboarding, isFalse);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    expect(prefs.hasSeenOnboarding, isTrue);
    expect(find.text('Kartu Profil Digital'), findsOneWidget);
    expect(find.text('Proyek Saya'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final reopenedPrefs = await PrefService.init();
    await tester.pumpWidget(MyApp(prefs: reopenedPrefs));
    await tester.pumpAndSettle();

    expect(reopenedPrefs.hasSeenOnboarding, isTrue);
    expect(find.text('Selamat Datang'), findsNothing);
    expect(find.text('Kartu Profil Digital'), findsOneWidget);
    expect(find.text('Proyek Saya'), findsOneWidget);
  });
}
