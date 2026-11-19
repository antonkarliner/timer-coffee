import 'package:flutter/material.dart';

import '../services/roaster_color_service.dart';

// Dark-mode cards are 0xFF303030 (theme_provider.dart's dark cardTheme colour;
// keep in sync). The page tint must sit a step below them so cards still lift
// off it, measured as relative luminance, not HSL lightness: a saturated
// yellow at the same HSL lightness as a grey is perceptibly brighter.
final double _kDarkTintMaxLuminance = const Color(
  0xFF262626,
).computeLuminance();

/// Derives a screen background color from a [RoasterColorResult].
///
/// - [RoasterColorNone] → `null` (keep default theme background)
/// - [RoasterColorMonochrome] → same alpha-blend as Vibrant but using
///   black in light mode / white in dark mode as the tint color
/// - [RoasterColorVibrant] → direct alpha blend of the brand color over the
///   standard surface (50 % in light mode, 55 % in dark mode)
///
/// In dark mode the blend is then darkened, keeping hue and saturation, until
/// its relative luminance is at most that of 0xFF262626, so the page never
/// reads lighter than the cards drawn on it (plan 090 DH).
Color? roasterBackgroundColor({
  required RoasterColorResult result,
  required Brightness brightness,
}) {
  const base = Color(0xFFFFFFFF);
  const baseDark = Color(0xFF1C1C1E);

  final blended = switch (result) {
    RoasterColorNone() => null,
    RoasterColorMonochrome() =>
      brightness == Brightness.light
          ? Color.alphaBlend(
              const Color(0xFF000000).withValues(alpha: 0.50),
              base,
            )
          : Color.alphaBlend(
              const Color(0xFFFFFFFF).withValues(alpha: 0.55),
              baseDark,
            ),
    RoasterColorVibrant(color: final c) =>
      brightness == Brightness.light
          ? Color.alphaBlend(c.withValues(alpha: 0.50), base)
          : Color.alphaBlend(c.withValues(alpha: 0.55), baseDark),
  };

  if (blended == null || brightness == Brightness.light) return blended;
  if (blended.computeLuminance() <= _kDarkTintMaxLuminance) return blended;

  // Binary-search the largest HSL lightness whose luminance fits the cap.
  final hsl = HSLColor.fromColor(blended);
  var low = 0.0;
  var high = hsl.lightness;
  for (var i = 0; i < 16; i++) {
    final mid = (low + high) / 2;
    if (hsl.withLightness(mid).toColor().computeLuminance() <=
        _kDarkTintMaxLuminance) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return hsl.withLightness(low).toColor();
}
