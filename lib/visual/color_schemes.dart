import 'package:flutter/material.dart';

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
  secondary: Color(0xffc47c3b), // updated secondary light
  onSecondary: Color.fromRGBO(121, 85, 72, 1), // kept intact
  tertiary: Color(0xffb88a6b), // updated tertiary light
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
  secondary: Color(0xffb07035), // closer to secondary light
  onSecondary: Colors.black, // kept intact
  tertiary: Color(0xff5a798c), // updated tertiary dark
  onTertiary: Colors.black,
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
