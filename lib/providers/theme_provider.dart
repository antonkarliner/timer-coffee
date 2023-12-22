import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../visual/color_shemes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(this._themeMode);

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _lightTheme();
  ThemeData get darkTheme => _darkTheme();

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
    _saveThemeModePreference(themeMode);
  }

  Future<void> loadThemeModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString().split('.').last == themeModeString,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> _saveThemeModePreference(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString().split('.').last);
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
