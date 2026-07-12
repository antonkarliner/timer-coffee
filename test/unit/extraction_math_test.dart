import 'package:coffee_timer/utils/extraction_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractionYield', () {
    test('espresso example: dose 18, shot 36, TDS 10% -> EY 20.0%', () {
      final ey = extractionYield(dose: 18, beverage: 36, tdsPercent: 10);
      expect(ey, closeTo(20.0, 1e-9));
    });

    test('filter example: dose 30, beverage 470, TDS 1.35% -> EY 21.15%', () {
      final ey = extractionYield(dose: 30, beverage: 470, tdsPercent: 1.35);
      expect(ey, closeTo(21.15, 1e-9));
    });

    test('null dose returns null', () {
      expect(
        extractionYield(dose: null, beverage: 36, tdsPercent: 10),
        isNull,
      );
    });

    test('null beverage returns null', () {
      expect(
        extractionYield(dose: 18, beverage: null, tdsPercent: 10),
        isNull,
      );
    });

    test('null tdsPercent returns null', () {
      expect(
        extractionYield(dose: 18, beverage: 36, tdsPercent: null),
        isNull,
      );
    });

    test('zero dose returns null', () {
      expect(extractionYield(dose: 0, beverage: 36, tdsPercent: 10), isNull);
    });

    test('negative beverage returns null', () {
      expect(extractionYield(dose: 18, beverage: -36, tdsPercent: 10), isNull);
    });

    test('negative tdsPercent returns null', () {
      expect(extractionYield(dose: 18, beverage: 36, tdsPercent: -10), isNull);
    });
  });

  group('classifyExtractionYield', () {
    test('exactly 18.0 is target', () {
      expect(classifyExtractionYield(18.0), ExtractionBand.target);
    });

    test('exactly 22.0 is target', () {
      expect(classifyExtractionYield(22.0), ExtractionBand.target);
    });

    test('below 18.0 is under', () {
      expect(classifyExtractionYield(17.9), ExtractionBand.under);
    });

    test('above 22.0 is over', () {
      expect(classifyExtractionYield(22.1), ExtractionBand.over);
    });

    test('midpoint is target', () {
      expect(classifyExtractionYield(20.0), ExtractionBand.target);
    });
  });

  group('classifyTdsStrength', () {
    test('exactly 1.15 is ideal', () {
      expect(classifyTdsStrength(1.15), TdsStrengthBand.ideal);
    });

    test('exactly 1.45 is ideal', () {
      expect(classifyTdsStrength(1.45), TdsStrengthBand.ideal);
    });

    test('below 1.15 is weak', () {
      expect(classifyTdsStrength(1.0), TdsStrengthBand.weak);
    });

    test('above 1.45 is strong', () {
      expect(classifyTdsStrength(1.5), TdsStrengthBand.strong);
    });
  });

  group('estimatedBeverage', () {
    test('water 500, dose 30 -> 440', () {
      expect(estimatedBeverage(water: 500, dose: 30), closeTo(440, 1e-9));
    });

    test('clamps at 0 when retention exceeds water', () {
      expect(estimatedBeverage(water: 10, dose: 30), 0);
    });
  });
}
