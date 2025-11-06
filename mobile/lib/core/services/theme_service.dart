import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _currentTheme = ThemeMode.system;
  
  ThemeMode get currentTheme => _currentTheme;
  
  void setTheme(ThemeMode theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    } else {
    }
  }
  
  void setThemeFromString(String themeString) {
    ThemeMode themeMode;
    switch (themeString) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }
    setTheme(themeMode);
  }
}
