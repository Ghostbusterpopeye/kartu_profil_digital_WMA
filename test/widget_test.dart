import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kartu_profil_digital/main.dart';
import 'package:kartu_profil_digital/services/pref_service.dart';

void main() {
  testWidgets('profile and preferences persist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
    await prefs.setHasSeenOnboarding(true);
    await prefs.increaseOpenCount();

    await tester.pumpWidget(MyApp(prefs: prefs));

    expect(find.text('Kartu Profil Digital'), findsOneWidget);
    expect(find.text('Sultan Shalahuddin Al Ayubi'), findsOneWidget);
    expect(find.text('Kartu ini sudah dibuka 1 kali'), findsOneWidget);
    expect(prefs.isDarkMode, isFalse);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(prefs.isDarkMode, isTrue);
    expect(
      Theme.of(tester.element(find.byType(SwitchListTile))).brightness,
      Brightness.dark,
    );

    final reopenedPrefs = await PrefService.init();
    await tester.pumpWidget(const SizedBox.shrink());
    await reopenedPrefs.increaseOpenCount();
    await tester.pumpWidget(MyApp(prefs: reopenedPrefs));

    expect(find.text('Kartu ini sudah dibuka 2 kali'), findsOneWidget);
    expect(reopenedPrefs.openCount, 2);
    expect(reopenedPrefs.isDarkMode, isTrue);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SwitchListTile))).brightness,
      Brightness.dark,
    );
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

    await tester.pumpWidget(const SizedBox.shrink());
    final reopenedPrefs = await PrefService.init();
    await tester.pumpWidget(MyApp(prefs: reopenedPrefs));

    expect(reopenedPrefs.hasSeenOnboarding, isTrue);
    expect(find.text('Selamat Datang'), findsNothing);
    expect(find.text('Kartu Profil Digital'), findsOneWidget);
  });
}
