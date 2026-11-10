import 'package:flutter/material.dart';
import 'data/project_repository.dart';
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
  const MyApp({super.key, required this.prefs, this.projectRepository});
  final PrefService prefs;
  final ProjectRepository? projectRepository;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(
    widget.prefs.themeMode,
  );
  late final ValueNotifier<Color> _themeColor = ValueNotifier(
    widget.prefs.themeColor,
  );
  late final ValueNotifier<bool> _hasSeenOnboarding = ValueNotifier(
    widget.prefs.hasSeenOnboarding,
  );

  Future<void> _changeThemeMode(ThemeMode value) async {
    await widget.prefs.setThemeMode(value);
    _themeMode.value = value;
  }

  Future<void> _changeThemeColor(Color value) async {
    await widget.prefs.setThemeColor(value);
    _themeColor.value = value;
  }

  Future<void> _completeOnboarding() async {
    await widget.prefs.setHasSeenOnboarding(true);
    _hasSeenOnboarding.value = true;
  }

  @override
  void dispose() {
    _themeMode.dispose();
    _themeColor.dispose();
    _hasSeenOnboarding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: _themeColor,
          builder: (context, themeColor, _) {
            return MaterialApp(
              title: 'Kartu Profil Digital',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(colorSchemeSeed: themeColor),
              darkTheme: ThemeData(
                colorSchemeSeed: themeColor,
                brightness: Brightness.dark,
              ),
              themeMode: themeMode,
              home: ValueListenableBuilder<bool>(
                valueListenable: _hasSeenOnboarding,
                builder: (context, hasSeenOnboarding, _) {
                  if (!hasSeenOnboarding) {
                    return OnboardingPage(onStart: _completeOnboarding);
                  }
                  return ProfilePage(
                    prefs: widget.prefs,
                    themeMode: themeMode,
                    onThemeModeChanged: _changeThemeMode,
                    themeColor: themeColor,
                    onThemeColorChanged: _changeThemeColor,
                    projectRepository: widget.projectRepository,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
