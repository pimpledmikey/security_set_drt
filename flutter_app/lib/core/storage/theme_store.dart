import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStore {
  static const _themeKey = 'runway_theme_mode';

  Future<ThemeMode> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);
    if (raw == 'light') {
      return ThemeMode.light;
    }
    return ThemeMode.dark;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      themeMode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}
