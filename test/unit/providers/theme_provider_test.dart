import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/providers/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('constructed theme mode is exposed via getter', () {
    final provider = ThemeProvider(ThemeMode.dark);
    expect(provider.themeMode, ThemeMode.dark);
  });

  group('setThemeMode', () {
    test('updates themeMode immediately', () {
      final provider = ThemeProvider(ThemeMode.system);
      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('notifies listeners on change', () {
      final provider = ThemeProvider(ThemeMode.system);
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setThemeMode(ThemeMode.light);

      expect(notified, isTrue);
    });

    test('persists value to SharedPreferences', () async {
      final provider = ThemeProvider(ThemeMode.system);
      provider.setThemeMode(ThemeMode.light);
      // Allow async save to complete
      await Future.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'light');
    });

    test('persists dark mode correctly', () async {
      final provider = ThemeProvider(ThemeMode.system);
      provider.setThemeMode(ThemeMode.dark);
      await Future.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'dark');
    });
  });

  group('loadThemeModePreference', () {
    test('reads dark mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final provider = ThemeProvider(ThemeMode.system);

      await provider.loadThemeModePreference();

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('reads light mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'light'});
      final provider = ThemeProvider(ThemeMode.dark);

      await provider.loadThemeModePreference();

      expect(provider.themeMode, ThemeMode.light);
    });

    test('defaults to system when key is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider(ThemeMode.dark);

      await provider.loadThemeModePreference();

      expect(provider.themeMode, ThemeMode.system);
    });

    test('defaults to system on unknown value', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'unknown_value'});
      final provider = ThemeProvider(ThemeMode.dark);

      await provider.loadThemeModePreference();

      expect(provider.themeMode, ThemeMode.system);
    });

    test('notifies listeners after load', () async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final provider = ThemeProvider(ThemeMode.system);
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.loadThemeModePreference();

      expect(notified, isTrue);
    });
  });

  group('lightTheme / darkTheme', () {
    test('lightTheme uses Material 3', () {
      final provider = ThemeProvider(ThemeMode.light);
      expect(provider.lightTheme.useMaterial3, isTrue);
    });

    test('darkTheme uses Material 3', () {
      final provider = ThemeProvider(ThemeMode.dark);
      expect(provider.darkTheme.useMaterial3, isTrue);
    });
  });
}
