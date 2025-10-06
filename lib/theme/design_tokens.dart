import 'package:flutter/material.dart';

/// Design tokens for the Timer Coffee app
/// Contains standardized spacing, radius, stroke, icon sizes, and text styles
class AppTokens {
  AppTokens._(); // Private constructor to prevent instantiation

  // Spacing tokens
  static const double base = 16.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Radius tokens
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Stroke tokens
  static const double strokeThin = 1.0;
  static const double strokeMedium = 2.0;

  // Icon size tokens
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

/// App spacing constants
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  /// Base spacing unit (16dp)
  static const double base = AppTokens.base;

  /// Card padding (16dp)
  static const double cardPadding = AppTokens.md;

  /// Field gap between form fields (16dp)
  static const double fieldGap = AppTokens.md;

  /// Section gap between major sections (24dp)
  static const double sectionGap = AppTokens.lg;

  /// Extra small spacing (4dp)
  static const double xs = AppTokens.xs;

  /// Small spacing (8dp)
  static const double sm = AppTokens.sm;

  /// Large spacing (24dp)
  static const double lg = AppTokens.lg;

  /// Extra large spacing (32dp)
  static const double xl = AppTokens.xl;

  /// Extra extra large spacing (48dp)
  static const double xxl = AppTokens.xxl;
}

/// App border radius constants
class AppRadius {
  AppRadius._(); // Private constructor to prevent instantiation

  /// Card border radius (12dp)
  static const double card = AppTokens.radiusMedium;

  /// Form field border radius (12dp)
  static const double field = AppTokens.radiusMedium;

  /// Chip border radius (12dp)
  static const double chip = AppTokens.radiusMedium;

  /// Small border radius (8dp)
  static const double small = AppTokens.radiusSmall;

  /// Large border radius (16dp)
  static const double large = AppTokens.radiusLarge;
}

/// App stroke width constants
class AppStroke {
  AppStroke._(); // Private constructor to prevent instantiation

  /// Border stroke width (1dp)
  static const double border = AppTokens.strokeThin;

  /// Focus stroke width (2dp)
  static const double focus = AppTokens.strokeMedium;
}

/// App icon size constants
class AppIconSize {
  AppIconSize._(); // Private constructor to prevent instantiation

  /// Small icon size (16dp)
  static const double small = AppTokens.iconSmall;

  /// Medium icon size (24dp)
  static const double medium = AppTokens.iconMedium;

  /// Large icon size (32dp)
  static const double large = AppTokens.iconLarge;
}

/// App text styles
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  /// Title style (20px, 600 weight)
  static const TextStyle title = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );

  /// Section header style (20px, 600 weight) - Using titleLarge size to match original app
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );

  /// Field label style (20px, 400 weight) - Using titleLarge size to match original app
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w400,
  );

  /// Body/helper text style (16px, 400 weight) - Increased for better readability
  static const TextStyle body = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
  );

  /// Caption style (14px, 400 weight) - Increased for better readability
  static const TextStyle caption = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
  );
}
