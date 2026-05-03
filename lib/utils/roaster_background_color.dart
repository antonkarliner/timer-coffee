import 'package:flutter/material.dart';

import '../services/roaster_color_service.dart';

/// Derives a screen background color from a [RoasterColorResult].
///
/// - [RoasterColorNone] → `null` (keep default theme background)
/// - [RoasterColorMonochrome] → same alpha-blend as Vibrant but using
///   black in light mode / white in dark mode as the tint color
/// - [RoasterColorVibrant] → direct alpha blend of the brand color over the
///   standard surface (30 % in light mode, 35 % in dark mode)
Color? roasterBackgroundColor({
  required RoasterColorResult result,
  required Brightness brightness,
}) {
  const _base = Color(0xFFFFFFFF);
  const _baseDark = Color(0xFF1C1C1E);

  return switch (result) {
    RoasterColorNone() => null,
    RoasterColorMonochrome() => brightness == Brightness.light
        ? Color.alphaBlend(
            const Color(0xFF000000).withValues(alpha: 0.50), _base)
        : Color.alphaBlend(
            const Color(0xFFFFFFFF).withValues(alpha: 0.55), _baseDark),
    RoasterColorVibrant(color: final c) => brightness == Brightness.light
        ? Color.alphaBlend(c.withValues(alpha: 0.50), _base)
        : Color.alphaBlend(c.withValues(alpha: 0.55), _baseDark),
  };
}
