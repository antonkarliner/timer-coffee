import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

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
    test('dialogs, bottom sheets and popup menus use design tokens', () {
      for (final theme in [
        ThemeProvider(ThemeMode.light).lightTheme,
        ThemeProvider(ThemeMode.dark).darkTheme,
      ]) {
        expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
        expect(
          (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(AppRadius.card),
        );
        expect(theme.dialogTheme.backgroundColor, isNull);

        expect(theme.bottomSheetTheme.shape, isA<RoundedRectangleBorder>());
        expect(
          (theme.bottomSheetTheme.shape! as RoundedRectangleBorder).borderRadius,
          const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        );
        expect(
          theme.bottomSheetTheme.dragHandleColor,
          theme.colorScheme.outlineVariant,
        );
        expect(theme.bottomSheetTheme.showDragHandle, isNull);

        expect(theme.popupMenuTheme.shape, isA<RoundedRectangleBorder>());
        expect(
          (theme.popupMenuTheme.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(AppRadius.card),
        );
        expect(theme.popupMenuTheme.surfaceTintColor, Colors.transparent);
      }
    });

    test('app bars retain their colour when content scrolls under them', () {
      for (final theme in [
        ThemeProvider(ThemeMode.light).lightTheme,
        ThemeProvider(ThemeMode.dark).darkTheme,
      ]) {
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      }
    });

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
