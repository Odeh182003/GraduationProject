import 'package:bzu_leads/themes/light_theme.dart';
import 'package:bzu_leads/themes/dark_theme.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode; // Default theme

  ThemeData get themeData => _themeData; // Getter for themeData
  bool get isDarkMode => _themeData == darkMode; // Check if dark mode is enabled

  set themeData(ThemeData theme) { // Setter for themeData
    _themeData = theme;
    notifyListeners();
  }

  void toggleTheme() {
    _themeData = (_themeData == lightMode) ? darkMode : lightMode;
    notifyListeners();
  }
}
