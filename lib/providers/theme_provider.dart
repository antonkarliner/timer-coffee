import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../visual/color_schemes.dart';
import '../theme/design_tokens.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider(this._themeMode);

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _buildTheme(lightColorScheme);
  ThemeData get darkTheme => _buildTheme(darkColorScheme);

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

  ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: kIsWeb ? 'Inter' : null,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? const Color(0xFF303030) : scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      // Input decoration theme for outlined fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: scheme.outline,
            width: AppStroke.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: isDark ? scheme.outline : scheme.outlineVariant,
            width: AppStroke.border,
          ),
        ),
        // Uses explicit greys (not scheme.onSurfaceVariant) because
        // onSurfaceVariant is full-contrast black/white in this app's
        // color scheme (it drives icon color), which would be too
        // strong for a focused-border accent.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            width: AppStroke.focus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: scheme.error,
            width: AppStroke.border,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(
            color: scheme.error,
            width: AppStroke.focus,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        // Uses explicit greys (not scheme.onSurfaceVariant) because
        // onSurfaceVariant is full-contrast black/white in this app's
        // color scheme (it drives icon color), which would be too
        // strong for a muted hint text color.
        hintStyle: AppTextStyles.body.copyWith(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        labelStyle: AppTextStyles.body.copyWith(
          color: scheme.onSurface,
        ),
        floatingLabelStyle: AppTextStyles.fieldLabel.copyWith(
          color: scheme.onSurface,
        ),
      ),
      // Chip theme data
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainer,
        // Monochrome: solid primary (black light / white dark), matching
        // the app's other selected-chip surfaces (beans-screen filter
        // chips, diary fact chips).
        selectedColor: scheme.primary,
        disabledColor: isDark
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerHighest,
        labelStyle: AppTextStyles.body.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
        secondaryLabelStyle: AppTextStyles.body.copyWith(
          color: scheme.secondary,
        ),
        checkmarkColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(
            color: scheme.outline,
            width: AppStroke.border,
          ),
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        elevation: 2.0,
        color: isDark ? const Color(0xFF303030) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(double.infinity, AppButton.heightMedium),
          padding: AppButton.paddingMedium,
          elevation: AppButton.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppButton.radius),
          ),
          textStyle: AppButton.label,
        ),
      ),
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, AppButton.heightMedium),
          padding: AppButton.paddingMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppButton.radius),
          ),
          textStyle: AppButton.label,
        ),
      ),
      // Text theme extensions
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        displayMedium: AppTextStyles.display,
        displaySmall: AppTextStyles.display,
        headlineLarge: AppTextStyles.headline,
        headlineMedium: AppTextStyles.headline,
        headlineSmall: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.fieldLabel,
        titleSmall: AppTextStyles.fieldLabel,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.fieldLabel,
        labelMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.caption,
      ),
    );
  }
}
