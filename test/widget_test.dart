import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kartu_profil_digital/main.dart';
import 'package:kartu_profil_digital/services/pref_service.dart';

void main() {
  testWidgets('profile and preferences persist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await PrefService.init();
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
}
