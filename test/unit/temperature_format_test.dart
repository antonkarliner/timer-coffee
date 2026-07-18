import 'package:coffee_timer/utils/temperature_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats 93 degrees Celsius in all supported forms', () {
    expect(celsiusToFahrenheit(93), 199);
    expect(formatTemperatureChip(93), '93°');
    expect(formatTemperatureDual(93), '93 °C · 199 °F');
    expect(formatTemperatureInputHelper(93), '= 199 °F');
  });

  test('all temperature helpers accept null', () {
    expect(celsiusToFahrenheit(null), isNull);
    expect(formatTemperatureChip(null), isNull);
    expect(formatTemperatureDual(null), isNull);
    expect(formatTemperatureInputHelper(null), isNull);
  });

  test('fractional Celsius inputs round to whole display units', () {
    expect(celsiusToFahrenheit(93.4), 200);
    expect(formatTemperatureChip(93.4), '93.4°');
    expect(formatTemperatureDual(93.4), '93.4 °C · 200 °F');
    expect(formatTemperatureInputHelper(93.4), '= 200 °F');
  });
}
