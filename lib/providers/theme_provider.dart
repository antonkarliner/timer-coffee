import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../visual/color_shemes.dart';
import '../theme/design_tokens.dart';

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
      fontFamily: kIsWeb ? 'Inter' : null,
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, foregroundColor: Colors.black),
      // Input decoration theme for outlined fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: Colors.grey.shade600,
            width: AppStroke.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: AppStroke.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: Colors.grey.shade700,
            width: AppStroke.focus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(
            color: Colors.red,
            width: AppStroke.border,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(
            color: Colors.red,
            width: AppStroke.focus,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: Colors.grey.shade600,
        ),
        labelStyle: AppTextStyles.body.copyWith(
          color: lightColorScheme.onSurface,
        ),
        floatingLabelStyle: AppTextStyles.fieldLabel.copyWith(
          color: lightColorScheme.onSurface,
        ),
      ),
      // Chip theme data
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: lightColorScheme.secondary.withOpacity(0.2),
        disabledColor: Colors.grey.shade300,
        labelStyle: AppTextStyles.body.copyWith(
          color: lightColorScheme.onSurface,
        ),
        secondaryLabelStyle: AppTextStyles.body.copyWith(
          color: lightColorScheme.secondary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: const BorderSide(
            color: Colors.grey,
            width: AppStroke.border,
          ),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      // Text theme extensions
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.title,
        displayMedium: AppTextStyles.title,
        displaySmall: AppTextStyles.title,
        headlineLarge: AppTextStyles.title,
        headlineMedium: AppTextStyles.sectionHeader,
        headlineSmall: AppTextStyles.sectionHeader,
        titleLarge: AppTextStyles.sectionHeader,
        titleMedium: AppTextStyles.fieldLabel,
        titleSmall: AppTextStyles.fieldLabel,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.body,
        labelLarge: AppTextStyles.fieldLabel,
        labelMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: kIsWeb ? 'Inter' : null,
      appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(48, 48, 48, 1),
          foregroundColor: Colors.white),
      // Input decoration theme for outlined fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
            width: AppStroke.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: Colors.grey.shade500,
            width: AppStroke.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: AppStroke.focus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(
            color: Colors.red,
            width: AppStroke.border,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(
            color: Colors.red,
            width: AppStroke.focus,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTextStyles.body.copyWith(
          color: Colors.grey.shade400,
        ),
        labelStyle: AppTextStyles.body.copyWith(
          color: darkColorScheme.onSurface,
        ),
        floatingLabelStyle: AppTextStyles.fieldLabel.copyWith(
          color: darkColorScheme.onSurface,
        ),
      ),
      // Chip theme data
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade700,
        selectedColor: darkColorScheme.secondary.withOpacity(0.3),
        disabledColor: Colors.grey.shade800,
        labelStyle: AppTextStyles.body.copyWith(
          color: darkColorScheme.onSurface,
        ),
        secondaryLabelStyle: AppTextStyles.body.copyWith(
          color: darkColorScheme.secondary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(
            color: Colors.grey.shade600,
            width: AppStroke.border,
          ),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2.0,
        color: const Color.fromRGBO(48, 48, 48, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      // Text theme extensions
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.title,
        displayMedium: AppTextStyles.title,
        displaySmall: AppTextStyles.title,
        headlineLarge: AppTextStyles.title,
        headlineMedium: AppTextStyles.sectionHeader,
        headlineSmall: AppTextStyles.sectionHeader,
        titleLarge: AppTextStyles.sectionHeader,
        titleMedium: AppTextStyles.fieldLabel,
        titleSmall: AppTextStyles.fieldLabel,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.body,
        labelLarge: AppTextStyles.fieldLabel,
        labelMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }
}
