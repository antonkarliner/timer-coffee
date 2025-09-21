import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Colors.black,
  onPrimary: Colors.white,
  secondary: Color(0xffc47c3b), // updated secondary light
  onSecondary: Color.fromRGBO(121, 85, 72, 1), // kept intact
  tertiary: Color(0xffb88a6b), // updated tertiary light
  onTertiary: Colors.white,
  error: Colors.red,
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Colors.black,
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.white,
  onPrimary: Color.fromRGBO(48, 48, 48, 1),
  secondary: Color(0xff5F98B5), // updated secondary dark
  onSecondary: Colors.black, // kept intact
  tertiary: Color(0xff5a798c), // updated tertiary dark
  onTertiary: Colors.black,
  error: Color(0xFFB71C1C),
  onError: Colors.white,
  surface: Color.fromRGBO(58, 58, 58, 1),
  onSurface: Colors.white,
);

/// Glass colors for iOS Liquid Glass effect - tuned for contrast on light mode
/// Bump opacity to ensure text remains legible against busy backdrops
const Color lightGlassSurface =
    Color(0x99FFFFFF); // ~60% opacity white for higher separation
const Color lightGlassBorder =
    Color(0xB3FFFFFF); // ~70% opacity white for defined edges
const Color lightGlassHighlight =
    Color(0xE6FFFFFF); // concentrated rim light for light mode
const Color lightGlassShadow =
    Color(0x14000000); // subtle drop shadow tint for light mode glass
const Color lightGlassTint =
    Color(0x1A9AB0C6); // faint blue tint inspired by iOS 17-18 glass

/// Highly transparent for dark theme
const Color darkGlassSurface = Color(0x1AFFFFFF); // ~10% opacity white
const Color darkGlassBorder = Color(0x33FFFFFF); // ~20% opacity white
const Color darkGlassHighlight =
    Color(0x59FFFFFF); // rim light stands out in dark mode
const Color darkGlassShadow =
    Color(0x33000000); // deeper shadow for dark mode glass
const Color darkGlassTint =
    Color(0x1427434D); // cool cyan tint to keep dark glass luminous
