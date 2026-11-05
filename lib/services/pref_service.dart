import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  PrefService._(this._prefs);
  final SharedPreferences _prefs;

  static const _kDarkMode = 'is_dark_mode';

// ---------- Tema ----------
bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;

Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

  // Semua key dikumpulkan di sini.
  static const _kOpenCount = 'open_count';

  /// Dipanggil sekali saat aplikasi mulai.
  static Future<PrefService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefService._(prefs);
  }

  // ---------- Penghitung buka aplikasi ----------
  int get openCount => _prefs.getInt(_kOpenCount) ?? 0;

  Future<void> increaseOpenCount() =>
      _prefs.setInt(_kOpenCount, openCount + 1);
}