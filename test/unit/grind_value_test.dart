import 'package:coffee_timer/utils/grind_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseGrindValue', () {
    test('parses leading numbers from free text', () {
      expect(parseGrindValue('24 clicks'), 24);
      expect(parseGrindValue('2.4 (Ode)'), 2.4);
      expect(parseGrindValue('18'), 18);
      expect(parseGrindValue('2,4'), 2.4);
    });

    test('allows leading whitespace and integer suffixes', () {
      expect(parseGrindValue('  12.5 clicks'), 12.5);
      expect(parseGrindValue('42x'), 42);
    });

    test('rejects values without a leading number', () {
      expect(parseGrindValue('medium-fine'), isNull);
      expect(parseGrindValue(''), isNull);
      expect(parseGrindValue(null), isNull);
      expect(parseGrindValue('fine 20'), isNull);
    });

    test('rejects negative values', () {
      expect(parseGrindValue('-2 clicks'), isNull);
    });
  });

  group('parseGrindSetting', () {
    test('returns the leading value and normalized scale context', () {
      final clicks = parseGrindSetting(' 24   CLICKS ');
      expect(clicks?.value, 24);
      expect(clicks?.contextKey, 'clicks');

      final ode = parseGrindSetting('2,4 ( Ode )');
      expect(ode?.value, 2.4);
      expect(ode?.contextKey, 'ode');
    });

    test('preserves meaningful context tokens', () {
      expect(parseGrindSetting('2.4 (Ode Gen 2)')?.contextKey, 'ode gen 2');
      expect(parseGrindSetting('24 clicks')?.contextKey, isNot('ode'));
    });

    test('uses an empty context for bare numeric settings', () {
      expect(parseGrindSetting('18')?.contextKey, isEmpty);
    });
  });
}
