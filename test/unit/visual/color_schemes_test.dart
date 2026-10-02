import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance < secondLuminance
      ? firstLuminance
      : secondLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('dark error text meets WCAG AA on every surface role', () {
    final surfaces = <String, Color>{
      'surface': darkColorScheme.surface,
      'surfaceContainerLowest': darkColorScheme.surfaceContainerLowest,
      'surfaceContainerLow': darkColorScheme.surfaceContainerLow,
      'surfaceContainer': darkColorScheme.surfaceContainer,
      'surfaceContainerHigh': darkColorScheme.surfaceContainerHigh,
      'surfaceContainerHighest': darkColorScheme.surfaceContainerHighest,
    };

    for (final surface in surfaces.entries) {
      expect(
        _contrastRatio(darkColorScheme.error, surface.value),
        greaterThanOrEqualTo(4.5),
        reason: 'error text on ${surface.key}',
      );
    }
  });

  test('dark error fills meet WCAG AA with their foreground roles', () {
    expect(
      _contrastRatio(darkColorScheme.onError, darkColorScheme.error),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(
        darkColorScheme.onErrorContainer,
        darkColorScheme.errorContainer,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });
}
