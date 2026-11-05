import 'package:shared_preferences/shared_preferences.dart';
import 'package:kartu_profil_digital/models/profile_data.dart';

class PrefService {
  PrefService._(this._prefs);
  final SharedPreferences _prefs;
  Set<String> get debugKeys => _prefs.getKeys();


  // Semua key dikumpulkan di sini.
  static const _kOpenCount = 'open_count';
  static const _kDarkMode = 'is_dark_mode';
  static const _kProfile = 'profile_data';


  /// Dipanggil sekali saat aplikasi mulai.
  static Future<PrefService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefService._(prefs);
  }

  // ---------- Penghitung buka aplikasi ----------
  int get openCount => _prefs.getInt(_kOpenCount) ?? 0;

  Future<void> increaseOpenCount() => _prefs.setInt(_kOpenCount, openCount + 1);

  // ---------- Tema ----------
  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;

  Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

  // ---------- Profil ----------
ProfileData get profile {
  final raw = _prefs.getString(_kProfile);
  if (raw == null) return ProfileData.defaults;
  try {
    return ProfileData.fromJson(raw);
  } catch (_) {
    // Data rusak? Jangan crash, kembali ke bawaan.
    return ProfileData.defaults;
  }
}

Future<void> saveProfile(ProfileData profile) =>
    _prefs.setString(_kProfile, profile.toJson());

Future<void> clearProfile() => _prefs.remove(_kProfile);
}
