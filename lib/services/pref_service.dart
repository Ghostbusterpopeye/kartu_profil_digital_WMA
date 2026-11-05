import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kartu_profil_digital/models/profile_data.dart';

class PrefService {
  PrefService._(this._prefs);
  final SharedPreferences _prefs;
  Set<String> get debugKeys => _prefs.getKeys();

  // Semua key dikumpulkan di sini.
  static const _kOpenCount = 'open_count';
  static const _kDarkMode = 'is_dark_mode';
  static const _kThemeMode = 'theme_mode';
  static const _kThemeColor = 'theme_color';
  static const _kProfile = 'profile_data';
  static const _kLastEdited = 'last_edited';
  static const _kHasSeenOnboarding = 'has_seen_onboarding';

  /// Dipanggil sekali saat aplikasi mulai.
  static Future<PrefService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefService._(prefs);
  }

  // ---------- Penghitung buka aplikasi ----------
  int get openCount => _prefs.getInt(_kOpenCount) ?? 0;

  Future<void> increaseOpenCount() => _prefs.setInt(_kOpenCount, openCount + 1);

  // ---------- Tema ----------
  ThemeMode get themeMode {
    final savedMode = _prefs.getInt(_kThemeMode);
    if (savedMode != null &&
        savedMode >= 0 &&
        savedMode < ThemeMode.values.length) {
      return ThemeMode.values[savedMode];
    }
    if (savedMode == null && (_prefs.getBool(_kDarkMode) ?? false)) {
      return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode value) =>
      _prefs.setInt(_kThemeMode, value.index);

  Color get themeColor => Color(_prefs.getInt(_kThemeColor) ?? 0xFF3F51B5);

  Future<void> setThemeColor(Color value) =>
      _prefs.setInt(_kThemeColor, value.toARGB32());

  // ---------- Onboarding ----------
  bool get hasSeenOnboarding => _prefs.getBool(_kHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(_kHasSeenOnboarding, value);

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

  String? get lastEdited => _prefs.getString(_kLastEdited);

  Future<void> saveProfile(ProfileData profile) async {
    await _prefs.setString(_kProfile, profile.toJson());
    await _prefs.setString(_kLastEdited, DateTime.now().toIso8601String());
  }

  Future<void> clearProfile() async {
    await _prefs.remove(_kProfile);
    await _prefs.remove(_kLastEdited);
  }
}
