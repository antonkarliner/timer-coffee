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

/// Button design tokens
class AppButtonTokens {
  AppButtonTokens._(); // Private constructor to prevent instantiation

  // Button height constants
  static const double heightSmall = 40.0;
  static const double heightMedium = 48.0;
  static const double heightLarge = 56.0;

  // Button padding constants
  static const EdgeInsetsGeometry paddingSmall =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsetsGeometry paddingMedium =
      EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsetsGeometry paddingLarge =
      EdgeInsets.symmetric(horizontal: 32, vertical: 20);

  // Button radius constants
  static const double radius = AppTokens.radiusMedium;

  // Button elevation constants
  static const double elevation = 2.0;

  // Button text styles
  static const TextStyle label = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle smallLabel = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
  );
}

class AppButton {
  AppButton._();

  // Height constants
  static const double heightSmall = AppButtonTokens.heightSmall;
  static const double heightMedium = AppButtonTokens.heightMedium;
  static const double heightLarge = AppButtonTokens.heightLarge;

  // Padding constants
  static const EdgeInsetsGeometry paddingSmall = AppButtonTokens.paddingSmall;
  static const EdgeInsetsGeometry paddingMedium = AppButtonTokens.paddingMedium;
  static const EdgeInsetsGeometry paddingLarge = AppButtonTokens.paddingLarge;

  // Radius constants
  static const double radius = AppButtonTokens.radius;

  // Elevation constants
  static const double elevation = AppButtonTokens.elevation;

  // Text styles
  static const TextStyle label = AppButtonTokens.label;
  static const TextStyle smallLabel = AppButtonTokens.smallLabel;
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
