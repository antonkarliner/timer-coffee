import 'package:flutter/material.dart';
import 'package:coffee_timer/utils/extraction_math.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Colors.black,
  onPrimary: Colors.white,
  // Deliberately mirrors primary/onPrimary (the framework default when
  // unset): this is the bold brand surface used by FABs and emphasis chips,
  // NOT an M3 soft tonal tint. For a muted selected state use
  // chipTheme.selectedColor instead.
  primaryContainer: Colors.black,
  onPrimaryContainer: Colors.white,
  secondary: Color(0xFF815B43),
  onSecondary: Colors.white,
  tertiary: Color(0xFF526955),
  onTertiary: Colors.white,
  error: Colors.red,
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Colors.black,
  onSurfaceVariant: Colors.black,
  outline: Color(0xFF757575),
  outlineVariant: Color(0xFFE0E0E0),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFF5F5F5),
  surfaceContainerHigh: Color(0xFFEEEEEE),
  surfaceContainerHighest: Color(0xFFE0E0E0),
  inverseSurface: Color(0xFF2E2E2E),
  onInverseSurface: Color(0xFFF5F5F5),
  inversePrimary: Colors.white,
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.white,
  onPrimary: Color.fromRGBO(48, 48, 48, 1),
  // See lightColorScheme: intentionally the bold brand surface, not a tint.
  primaryContainer: Colors.white,
  onPrimaryContainer: Color.fromRGBO(48, 48, 48, 1),
  secondary: Color(0xFFC6A182),
  onSecondary: Color(0xFF3A3A3A),
  tertiary: Color(0xFFA3B39C),
  onTertiary: Color(0xFF3A3A3A),
  error: Color(0xFFB71C1C),
  onError: Colors.white,
  surface: Color.fromRGBO(58, 58, 58, 1),
  onSurface: Colors.white,
  onSurfaceVariant: Colors.white,
  outline: Color(0xFF9A9A9A),
  outlineVariant: Color(0xFF555555),
  surfaceContainerLowest: Color(0xFF2A2A2A),
  surfaceContainerLow: Color(0xFF303030),
  surfaceContainer: Color(0xFF454545),
  surfaceContainerHigh: Color(0xFF4B4B4B),
  surfaceContainerHighest: Color(0xFF505050),
  inverseSurface: Color(0xFFEBEBEB),
  onInverseSurface: Color(0xFF303030),
  inversePrimary: Colors.black,
);

/// Roasted-walnut liquid shared by the immersive brewing view and the
/// completion ring. This is a dedicated color role, independent of the
/// app-wide secondary accent.
class AppBrewColors {
  AppBrewColors._();

  static const Color _fillLight = Color(0xFF654735);
  static const Color _fillDark = Color(0xFF795840);

  static Color brewFill(ColorScheme scheme) =>
      scheme.brightness == Brightness.light ? _fillLight : _fillDark;
}

typedef AppSemanticColorPair = ({Color background, Color foreground});

/// Color pairs for taste, extraction, and neutral chips. The shared accents
/// come from the app's color schemes so they cannot drift apart.
class AppSemanticColors {
  AppSemanticColors._();

  static const Color _rustLight = Color(0xFF9B5439);
  static const Color _rustDark = Color(0xFFD59A80);

  static ColorScheme _scheme(Brightness brightness) =>
      brightness == Brightness.light ? lightColorScheme : darkColorScheme;

  static AppSemanticColorPair _pair(Color background, Color foreground) =>
      (background: background, foreground: foreground);

  static AppSemanticColorPair _rust(Brightness brightness) =>
      brightness == Brightness.light
      ? _pair(_rustLight, Colors.white)
      : _pair(_rustDark, darkColorScheme.surface);

  static AppSemanticColorPair taste(int balance, Brightness brightness) {
    final scheme = _scheme(brightness);
    return switch (balance) {
      -1 => _pair(scheme.secondary, scheme.onSecondary),
      0 => _pair(scheme.tertiary, scheme.onTertiary),
      _ => _rust(brightness),
    };
  }

  static AppSemanticColorPair neutralChip(Brightness brightness) {
    final scheme = _scheme(brightness);
    return _pair(scheme.surfaceContainerHighest, scheme.onSurface);
  }

  static AppSemanticColorPair extractionYield(
    ExtractionBand band,
    Brightness brightness,
  ) {
    final scheme = _scheme(brightness);
    return switch (band) {
      ExtractionBand.under => _pair(scheme.secondary, scheme.onSecondary),
      ExtractionBand.target => _pair(scheme.tertiary, scheme.onTertiary),
      ExtractionBand.over => _rust(brightness),
    };
  }
}
