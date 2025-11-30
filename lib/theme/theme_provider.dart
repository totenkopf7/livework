// theme_provider.dart
import 'package:flutter/material.dart';
import 'theme.dart';

enum AppTheme { system, light, dark }

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;
  AppTheme _currentTheme = AppTheme.system;

  ThemeData get themeData => _themeData;
  AppTheme get currentTheme => _currentTheme;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;

    switch (theme) {
      case AppTheme.light:
        _themeData = lightMode;
        break;
      case AppTheme.dark:
        _themeData = darkMode;
        break;
      case AppTheme.system:
        // Use system brightness
        final brightness = WidgetsBinding.instance.window.platformBrightness;
        _themeData = brightness == Brightness.dark ? darkMode : lightMode;
        break;
    }

    notifyListeners();
  }

  void toggleTheme() {
    if (_currentTheme == AppTheme.light) {
      setTheme(AppTheme.dark);
    } else {
      setTheme(AppTheme.light);
    }
  }
}
