import 'package:flutter/material.dart';

import '../../core/storage/theme_store.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._themeStore);

  final ThemeStore _themeStore;
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    _themeMode = await _themeStore.readThemeMode();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _themeStore.saveThemeMode(value);
    notifyListeners();
  }

  Future<void> toggle() async {
    await setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
