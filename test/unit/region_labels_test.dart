import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/utils/region_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('known region codes and long-form aliases', () {
    test('EU / EUROPE', () {
      expect(localizeRegion('EU', l10n), l10n.regionEurope);
      expect(localizeRegion('EUROPE', l10n), l10n.regionEurope);
    });

    test('NA / NORTH AMERICA', () {
      expect(localizeRegion('NA', l10n), l10n.regionNorthAmerica);
      expect(localizeRegion('NORTH AMERICA', l10n), l10n.regionNorthAmerica);
    });

    test('AS / ASIA', () {
      expect(localizeRegion('AS', l10n), l10n.regionAsia);
      expect(localizeRegion('ASIA', l10n), l10n.regionAsia);
    });

    test('AU / OCEANIA / AUSTRALIA', () {
      expect(localizeRegion('AU', l10n), l10n.regionAustralia);
      expect(localizeRegion('OCEANIA', l10n), l10n.regionAustralia);
      expect(localizeRegion('AUSTRALIA', l10n), l10n.regionAustralia);
    });

    test('AF / AFRICA', () {
      expect(localizeRegion('AF', l10n), l10n.regionAfrica);
      expect(localizeRegion('AFRICA', l10n), l10n.regionAfrica);
    });

    test('ME / MIDDLE EAST', () {
      expect(localizeRegion('ME', l10n), l10n.regionMiddleEast);
      expect(localizeRegion('MIDDLE EAST', l10n), l10n.regionMiddleEast);
    });

    test('SA / SOUTH AMERICA', () {
      expect(localizeRegion('SA', l10n), l10n.regionSouthAmerica);
      expect(localizeRegion('SOUTH AMERICA', l10n), l10n.regionSouthAmerica);
    });

    test('WW / WORLDWIDE', () {
      expect(localizeRegion('WW', l10n), l10n.regionWorldwide);
      expect(localizeRegion('WORLDWIDE', l10n), l10n.regionWorldwide);
    });

    test('distinct codes never collapse onto each other', () {
      final labels = <String>{
        localizeRegion('EU', l10n),
        localizeRegion('NA', l10n),
        localizeRegion('AS', l10n),
        localizeRegion('AU', l10n),
        localizeRegion('AF', l10n),
        localizeRegion('ME', l10n),
        localizeRegion('SA', l10n),
        localizeRegion('WW', l10n),
      };
      expect(labels, hasLength(8));
    });
  });

  group('normalization', () {
    test('leading and trailing whitespace is trimmed', () {
      expect(localizeRegion(' EU ', l10n), l10n.regionEurope);
      expect(localizeRegion('\tEU\n', l10n), l10n.regionEurope);
      expect(localizeRegion('  NORTH AMERICA  ', l10n), l10n.regionNorthAmerica);
    });

    test('lowercase input is uppercased', () {
      expect(localizeRegion('eu', l10n), l10n.regionEurope);
      expect(localizeRegion('north america', l10n), l10n.regionNorthAmerica);
      expect(localizeRegion('asia', l10n), l10n.regionAsia);
      expect(localizeRegion('oceania', l10n), l10n.regionAustralia);
      expect(localizeRegion('australia', l10n), l10n.regionAustralia);
      expect(localizeRegion('africa', l10n), l10n.regionAfrica);
      expect(localizeRegion('middle east', l10n), l10n.regionMiddleEast);
      expect(localizeRegion('south america', l10n), l10n.regionSouthAmerica);
      expect(localizeRegion('worldwide', l10n), l10n.regionWorldwide);
    });

    test('mixed case with surrounding whitespace resolves', () {
      expect(localizeRegion(' Eu ', l10n), l10n.regionEurope);
      expect(localizeRegion(' Worldwide ', l10n), l10n.regionWorldwide);
    });
  });

  group('default branch', () {
    test('unrecognized code returns the raw input unchanged', () {
      expect(localizeRegion('XX', l10n), 'XX');
      expect(localizeRegion('LATAM', l10n), 'LATAM');
      expect(localizeRegion('Southeast Asia', l10n), 'Southeast Asia');
    });

    test('fallback preserves the original casing and whitespace', () {
      // The default branch returns the untouched argument, not the
      // trimmed/uppercased working copy.
      expect(localizeRegion('  xx  ', l10n), '  xx  ');
      expect(localizeRegion(' CaRiBbEaN ', l10n), ' CaRiBbEaN ');
    });
  });
}
