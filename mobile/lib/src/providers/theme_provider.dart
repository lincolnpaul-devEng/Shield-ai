import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  late final SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _initialized;

  ThemeProvider(SharedPreferences prefs) : _prefs = prefs {
    _loadTheme();
  }

  void _loadTheme() {
    _isDarkMode = _prefs.getBool(_themeModeKey) ?? false;
    _initialized = true;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs.setBool(_themeModeKey, _isDarkMode);
    notifyListeners();
  }

  void setThemeMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _prefs.setBool(_themeModeKey, _isDarkMode);
      notifyListeners();
    }
  }
}
