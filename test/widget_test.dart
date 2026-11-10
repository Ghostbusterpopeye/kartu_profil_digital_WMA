import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kartu_profil_digital/main.dart';
import 'package:kartu_profil_digital/pages/project_form_page.dart';
import 'package:kartu_profil_digital/services/pref_service.dart';

void main() {
  testWidgets('project list is shown after onboarding', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
    await prefs.setHasSeenOnboarding(true);

    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Proyek Saya'), findsOneWidget);
    expect(prefs.hasSeenOnboarding, isTrue);
  });

  testWidgets('empty project form shows required field validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProjectFormPage()));

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(3));
  });

  testWidgets('onboarding is shown once and remembered', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();

    await tester.pumpWidget(MyApp(prefs: prefs));
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(prefs.hasSeenOnboarding, isFalse);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    expect(prefs.hasSeenOnboarding, isTrue);
    expect(find.text('Proyek Saya'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final reopenedPrefs = await PrefService.init();
    await tester.pumpWidget(MyApp(prefs: reopenedPrefs));
    await tester.pumpAndSettle();

    expect(reopenedPrefs.hasSeenOnboarding, isTrue);
    expect(find.text('Selamat Datang'), findsNothing);
    expect(find.text('Proyek Saya'), findsOneWidget);
  });
}
