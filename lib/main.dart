import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/project_list_page.dart';
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
  late final ValueNotifier<bool> _hasSeenOnboarding = ValueNotifier(
    widget.prefs.hasSeenOnboarding,
  );

  Future<void> _completeOnboarding() async {
    await widget.prefs.setHasSeenOnboarding(true);
    _hasSeenOnboarding.value = true;
  }

  @override
  void dispose() {
    _hasSeenOnboarding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.prefs.themeColor;
    return MaterialApp(
      title: 'Kartu Profil Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: themeColor),
      darkTheme: ThemeData(
        colorSchemeSeed: themeColor,
        brightness: Brightness.dark,
      ),
      themeMode: widget.prefs.themeMode,
      home: ValueListenableBuilder<bool>(
        valueListenable: _hasSeenOnboarding,
        builder: (context, hasSeenOnboarding, _) {
          if (!hasSeenOnboarding) {
            return OnboardingPage(onStart: _completeOnboarding);
          }
          return const ProjectListPage();
        },
      ),
    );
  }
}
