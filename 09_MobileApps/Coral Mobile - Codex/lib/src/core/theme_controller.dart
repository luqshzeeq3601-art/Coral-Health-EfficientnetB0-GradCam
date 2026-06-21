import 'package:flutter/material.dart';
import 'settings_store.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._internal() {
    _loadTheme();
  }

  static final ThemeController instance = ThemeController._internal();

  final SettingsStore _settingsStore = SettingsStore();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadTheme() async {
    final pref = await _settingsStore.getThemePreference();
    _themeMode = _parseThemeMode(pref);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _settingsStore.saveThemePreference(mode.name);
  }

  ThemeMode _parseThemeMode(String value) {
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
