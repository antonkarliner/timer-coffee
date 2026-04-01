import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/utils/country_names.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localizedCountryNameGenitive', () {
    test('returns null for null, empty, and unknown country codes', () {
      expect(localizedCountryNameGenitive(null, const Locale('fi')), isNull);
      expect(localizedCountryNameGenitive('', const Locale('fi')), isNull);
      expect(localizedCountryNameGenitive('XX', const Locale('fi')), isNull);
    });

    test('supports Finnish from-country forms', () {
      expect(
        localizedCountryNameGenitive('FI', const Locale('fi')),
        'Suomesta',
      );
      expect(
        localizedCountryNameGenitive('FR', const Locale('fi')),
        'Ranskasta',
      );
      expect(
        localizedCountryNameGenitive('US', const Locale('fi')),
        'Yhdysvalloista',
      );
      expect(
        localizedCountryNameGenitive('TR', const Locale('fi')),
        'Turkista',
      );
    });

    test('supports Greek from-country forms', () {
      expect(
        localizedCountryNameGenitive('GR', const Locale('el')),
        'την Ελλάδα',
      );
      expect(
        localizedCountryNameGenitive('DE', const Locale('el')),
        'την Γερμανία',
      );
      expect(
        localizedCountryNameGenitive('US', const Locale('el')),
        'τις Ηνωμένες Πολιτείες',
      );
      expect(
        localizedCountryNameGenitive('CH', const Locale('el')),
        'την Ελβετία',
      );
    });

    test('supports Turkish from-country forms', () {
      expect(
        localizedCountryNameGenitive('TR', const Locale('tr')),
        "Türkiye'den",
      );
      expect(
        localizedCountryNameGenitive('DE', const Locale('tr')),
        "Almanya'dan",
      );
      expect(
        localizedCountryNameGenitive('FR', const Locale('tr')),
        "Fransa'dan",
      );
      expect(
        localizedCountryNameGenitive('US', const Locale('tr')),
        "Amerika Birleşik Devletleri'nden",
      );
    });

    test('handles German article exceptions and nominative fallback', () {
      expect(
        localizedCountryNameGenitive('CH', const Locale('de')),
        'der Schweiz',
      );
      expect(
        localizedCountryNameGenitive('US', const Locale('de')),
        'den USA',
      );
      expect(
        localizedCountryNameGenitive('TR', const Locale('de')),
        'der Türkei',
      );
      expect(
        localizedCountryNameGenitive('NL', const Locale('de')),
        'den Niederlanden',
      );
      expect(
        localizedCountryNameGenitive('FR', const Locale('de')),
        'Frankreich',
      );
    });

    test('keeps existing curated languages working', () {
      expect(
        localizedCountryNameGenitive('FR', const Locale('ru')),
        'Франции',
      );
      expect(
        localizedCountryNameGenitive('US', const Locale('pl')),
        'Stanów Zjednoczonych',
      );
      expect(
        localizedCountryNameGenitive('TR', const Locale('hr')),
        'Turske',
      );
    });
  });

  group('pulseSomeoneFromBrewed composition', () {
    test('Finnish template uses the full helper-provided form', () {
      final l10n = lookupAppLocalizations(const Locale('fi'));
      final country = localizedCountryNameGenitive('FI', const Locale('fi'));

      expect(
        l10n.pulseSomeoneFromBrewed(country!, 'V60'),
        'Joku Suomesta uutti V60',
      );
    });

    test('Turkish template uses the full helper-provided form', () {
      final l10n = lookupAppLocalizations(const Locale('tr'));
      final country = localizedCountryNameGenitive('TR', const Locale('tr'));

      expect(
        l10n.pulseSomeoneFromBrewed(country!, 'V60'),
        "Türkiye'den birisi V60 demledi",
      );
    });
  });
}
