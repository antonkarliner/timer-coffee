import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../visual/color_schemes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(this._themeMode);

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _lightTheme();
  ThemeData get darkTheme => _darkTheme();

  // Conditional glass colors for iOS Liquid Glass effect
  Brightness get _effectiveBrightness {
    if (_themeMode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  Color glassSurfaceFor(Brightness brightness) => Platform.isIOS
      ? (brightness == Brightness.dark ? darkGlassSurface : lightGlassSurface)
      : (brightness == Brightness.dark
          ? darkColorScheme.surface
          : lightColorScheme.surface);

  Color glassBorderFor(Brightness brightness) => Platform.isIOS
      ? (brightness == Brightness.dark ? darkGlassBorder : lightGlassBorder)
      : (brightness == Brightness.dark
          ? darkColorScheme.outline
          : lightColorScheme.outline);

  Color glassHighlightFor(Brightness brightness) => Platform.isIOS
      ? (brightness == Brightness.dark
          ? darkGlassHighlight
          : lightGlassHighlight)
      : (brightness == Brightness.dark
          ? Colors.white.withOpacity(0.28)
          : Colors.white.withOpacity(0.48));

  Color glassShadowFor(Brightness brightness) => Platform.isIOS
      ? (brightness == Brightness.dark ? darkGlassShadow : lightGlassShadow)
      : (brightness == Brightness.dark
          ? Colors.black.withOpacity(0.45)
          : Colors.black.withOpacity(0.12));

  Color glassTintFor(Brightness brightness) => Platform.isIOS
      ? (brightness == Brightness.dark ? darkGlassTint : lightGlassTint)
      : Colors.transparent;

  Color get glassSurface => glassSurfaceFor(_effectiveBrightness);

  Color get glassBorder => glassBorderFor(_effectiveBrightness);

  Color get glassHighlight => glassHighlightFor(_effectiveBrightness);

  Color get glassShadow => glassShadowFor(_effectiveBrightness);

  Color get glassTint => glassTintFor(_effectiveBrightness);

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
