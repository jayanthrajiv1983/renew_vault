import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../services/hive_encryption_service.dart';

enum AppThemeMode {
  light,
  dark,
  system;

  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static AppThemeMode fromName(String? value) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return AppThemeMode.system;
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();

  static final ThemeProvider instance = ThemeProvider._();

  static const _boxName = 'settings';
  static const themeModeKey = 'themeMode';

  Box? _box;
  AppThemeMode _appThemeMode = AppThemeMode.system;

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode => _appThemeMode.themeMode;

  Future<void> init() async {
    _box = await HiveEncryptionService.instance.openBox(_boxName);
    _loadFromBox();
  }

  void reload() {
    _loadFromBox();
    notifyListeners();
  }

  void _loadFromBox() {
    final value = _box?.get(themeModeKey);
    if (value is String) {
      _appThemeMode = AppThemeMode.fromName(value);
    } else {
      _appThemeMode = AppThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_appThemeMode == mode) {
      return;
    }

    _appThemeMode = mode;
    await _box?.put(themeModeKey, mode.name);
    notifyListeners();
  }
}
