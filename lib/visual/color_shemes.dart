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
