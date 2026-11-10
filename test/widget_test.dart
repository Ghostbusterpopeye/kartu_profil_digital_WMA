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
  Future<List<Project>> getAll({String query = ''}) async =>
      List<Project>.of(projects);

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
}

void main() {
  testWidgets('profile, projects, and preferences are available', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
    await prefs.setHasSeenOnboarding(true);
    await prefs.increaseOpenCount();

    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Kartu Profil Digital'), findsOneWidget);
    expect(find.text('Sultan Shalahuddin Al Ayubi'), findsOneWidget);
    expect(find.text('Proyek Saya'), findsOneWidget);
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

  testWidgets('tapping a project edits it and refreshes the list', (
    WidgetTester tester,
  ) async {
    final project = Project(
      id: 1,
      title: 'Proyek Lama',
      description: 'Deskripsi lama',
      techStack: 'Flutter',
      createdAt: DateTime(2026),
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
    expect(find.text('Proyek Baru'), findsOneWidget);
  });

  testWidgets('project deletion requires confirmation', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProjectRepository([
      Project(
        id: 1,
        title: 'Proyek Uji',
        description: 'Deskripsi',
        techStack: 'Dart',
        createdAt: DateTime(2026),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProjectListSection(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('"Proyek Uji" akan dihapus permanen.'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repository.projects, hasLength(1));
    expect(find.text('Proyek Uji'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repository.projects, isEmpty);
    expect(
      find.text('Belum ada proyek.\nTekan + untuk menambahkan.'),
      findsOneWidget,
    );
    expect(find.text('"Proyek Uji" dihapus'), findsOneWidget);
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
