import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Colors.black,
  onPrimary: Colors.white,
  secondary: Colors.white,
  onSecondary: Color.fromRGBO(121, 85, 72, 1),
  error: Colors.red,
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Colors.black,
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.white, // Darker shade of your primary color
  onPrimary: Color.fromRGBO(
      48, 48, 48, 1), // Text color on primary color, typically a light color
  secondary:
      Color.fromRGBO(180, 138, 127, 1), // Darker shade of your secondary color
  onSecondary: Colors.black, // Text color on secondary color
  error: Color(0xFFB71C1C), // Darker shade for error
  onError: Colors.white, // Text color on error
  surface: Color.fromRGBO(58, 58, 58, 1), // Dark surface color
  onSurface: Colors.white, // Text color on surface
);
