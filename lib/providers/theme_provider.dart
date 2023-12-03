import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../visual/color_shemes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider(this._themeData);

  ThemeData get themeData => _themeData;

  // Method to toggle the theme
  void toggleTheme(bool isDark) {
    _themeData = isDark ? _darkTheme() : _lightTheme();
    notifyListeners();
    _saveThemePreference(isDark);
  }

  // Method to load theme preference
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('isDarkTheme') ?? false;
    _themeData = isDark ? _darkTheme() : _lightTheme();
    notifyListeners();
  }

  // Method to save theme preference
  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: kIsWeb ? 'Lato' : null,
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, foregroundColor: Colors.black),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: kIsWeb ? 'Lato' : null,
      appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(48, 48, 48, 1),
          foregroundColor: Colors.white),
    );
  }
}
