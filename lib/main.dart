import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/profile_page.dart';
import 'services/pref_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // wajib sebelum await di main
  final prefs = await PrefService.init();
  debugPrint('Isi prefs: ${prefs.debugKeys}');
  await prefs.increaseOpenCount();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.prefs});
  final PrefService prefs;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ValueNotifier<bool> _isDark = ValueNotifier(
    widget.prefs.isDarkMode,
  );
  late final ValueNotifier<bool> _hasSeenOnboarding = ValueNotifier(
    widget.prefs.hasSeenOnboarding,
  );

  Future<void> _changeTheme(bool value) async {
    await widget.prefs.setDarkMode(value);
    _isDark.value = value;
  }

  Future<void> _completeOnboarding() async {
    await widget.prefs.setHasSeenOnboarding(true);
    _hasSeenOnboarding.value = true;
  }

  @override
  void dispose() {
    _isDark.dispose();
    _hasSeenOnboarding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Kartu Profil Digital',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: ValueListenableBuilder<bool>(
            valueListenable: _hasSeenOnboarding,
            builder: (context, hasSeenOnboarding, _) {
              if (!hasSeenOnboarding) {
                return OnboardingPage(onStart: _completeOnboarding);
              }
              return ProfilePage(
                prefs: widget.prefs,
                isDark: isDark,
                onThemeChanged: _changeTheme,
              );
            },
          ),
        );
      },
    );
  }
}
