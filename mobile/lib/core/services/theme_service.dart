import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _currentTheme = ThemeMode.system;
  
  ThemeMode get currentTheme => _currentTheme;
  
  void setTheme(ThemeMode theme) {
    print('🎨 ThemeService: Setting theme from $_currentTheme to $theme');
    if (_currentTheme != theme) {
      _currentTheme = theme;
      print('🎨 ThemeService: Theme changed to $theme, notifying listeners');
      notifyListeners();
    } else {
      print('🎨 ThemeService: Theme is already $theme, no change needed');
    }
  }
  
  void setThemeFromString(String themeString) {
    print('🎨 ThemeService: setThemeFromString called with: $themeString');
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
    print('🎨 ThemeService: Converted $themeString to ThemeMode: $themeMode');
    setTheme(themeMode);
  }
}
