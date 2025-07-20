import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _currentTheme = ThemeMode.light;

  ThemeMode get currentTheme => _currentTheme;

  void toggleTheme(bool isDarkMode) {
    _currentTheme = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
