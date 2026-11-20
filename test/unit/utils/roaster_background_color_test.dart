import 'package:coffee_timer/services/roaster_color_service.dart';
import 'package:coffee_timer/utils/roaster_background_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const brown = Color(0xFF8B5A2B);
  const navy = Color(0xFF0A1A3A);
  const darkBase = Color(0xFF1C1C1E);
  final cardLuminance = const Color(0xFF303030).computeLuminance();

  for (final brightness in Brightness.values) {
    test('none returns null in ${brightness.name} mode', () {
      expect(
        roasterBackgroundColor(
          result: const RoasterColorNone(),
          brightness: brightness,
        ),
        isNull,
      );
    });
  }

  test('light-mode vibrant and monochrome blends remain unchanged', () {
    for (final (result, tint) in <(RoasterColorResult, Color)>[
      (const RoasterColorVibrant(brown), brown),
      (const RoasterColorMonochrome(), const Color(0xFF000000)),
    ]) {
      expect(
        roasterBackgroundColor(result: result, brightness: Brightness.light),
        Color.alphaBlend(tint.withValues(alpha: 0.50), const Color(0xFFFFFFFF)),
      );
    }
  });

  for (final color in [
    brown,
    const Color(0xFFFFD400),
    const Color(0xFFE53935),
    navy,
  ]) {
    test('dark-mode $color stays darker than cards and preserves hue', () {
      final blended = Color.alphaBlend(color.withValues(alpha: 0.55), darkBase);
      final actual = roasterBackgroundColor(
        result: RoasterColorVibrant(color),
        brightness: Brightness.dark,
      )!;
      final hsl = HSLColor.fromColor(actual);
      expect(actual.computeLuminance(), lessThan(cardLuminance));
      final hueDifference = (hsl.hue - HSLColor.fromColor(blended).hue).abs();
      final circularDifference = hueDifference > 180
          ? 360 - hueDifference
          : hueDifference;
      expect(circularDifference, lessThanOrEqualTo(2));
    });
  }

  test('dark-mode navy below the cap returns the original blend', () {
    final blended = Color.alphaBlend(navy.withValues(alpha: 0.55), darkBase);
    expect(
      blended.computeLuminance(),
      lessThan(const Color(0xFF262626).computeLuminance()),
    );
    expect(
      roasterBackgroundColor(
        result: const RoasterColorVibrant(navy),
        brightness: Brightness.dark,
      ),
      blended,
    );
  });

  test('dark-mode monochrome stays darker than cards and remains neutral', () {
    final actual = roasterBackgroundColor(
      result: const RoasterColorMonochrome(),
      brightness: Brightness.dark,
    )!;
    expect(actual.computeLuminance(), lessThan(cardLuminance));
    expect(HSLColor.fromColor(actual).saturation, 0);
  });
}
