import 'package:coffee_timer/utils/text_wrapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('keepNumbersWithUnits', () {
    final cases = <String, String>{
      'up to 176 g of': 'up to 176\u00A0g of',
      '126.5 g': '126.5\u00A0g',
      '94 °C': '94\u00A0°C',
      'Pour 60 grams': 'Pour 60\u00A0grams',
      '176 г': '176\u00A0г',
      '30 δευτ.': '30\u00A0δευτ.',
      '30 ثانية': '30\u00A0ثانية',
      '40g.': '40g.',
      '1 2 3': '1 2 3',
      'Wait.': 'Wait.',
    };

    for (final entry in cases.entries) {
      test('transforms ${entry.key}', () {
        expect(keepNumbersWithUnits(entry.key), entry.value);
      });
    }

    test('collapses spaces and tabs without crossing newlines', () {
      expect(keepNumbersWithUnits('60 \t  g'), '60\u00A0g');
      expect(keepNumbersWithUnits('60\ng'), '60\ng');
    });
  });
}
