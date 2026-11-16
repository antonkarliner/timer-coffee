import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/utils/stock_attribute_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final language in ['en', 'de', 'ar']) {
    group('$language stock attribute mappings', () {
      late AppLocalizations l10n;
      setUp(() async {
        l10n = await AppLocalizations.delegate.load(Locale(language));
      });

      test('every process maps to its localized label', () {
        final expected = {
          'washed': l10n.stockProcessWashed,
          'natural': l10n.stockProcessNatural,
          'honey': l10n.stockProcessHoney,
          'experimental': l10n.stockProcessExperimental,
          'wet_hulled': l10n.stockProcessWetHulled,
        };
        for (final entry in expected.entries) {
          expect(
            stockProcessLabel(l10n, entry.key),
            entry.value,
            reason: entry.key,
          );
        }
      });

      test('every flavour maps to its localized label', () {
        final expected = {
          'fruity': l10n.flavorCatFruity,
          'berry': l10n.flavorSubBerry,
          'citrus': l10n.flavorSubCitrus,
          'tropical': l10n.flavorSubTropical,
          'floral': l10n.flavorCatFloral,
          'nutty': l10n.flavorSubNutty,
          'spice': l10n.flavorCatSpices,
          'caramel_sweet': l10n.flavorSubCaramel,
          'chocolate': l10n.stockFlavorChocolate,
          'stone_fruit': l10n.stockFlavorStoneFruit,
          'tea_like': l10n.stockFlavorTeaLike,
          'winey_fermented': l10n.stockFlavorWiney,
          'earthy': l10n.stockFlavorEarthy,
        };
        for (final entry in expected.entries) {
          expect(
            stockFlavorLabel(l10n, entry.key),
            entry.value,
            reason: entry.key,
          );
        }
      });

      test('other, unknown, empty and null are omitted', () {
        for (final value in ['other', 'unknown', '', null]) {
          expect(stockProcessLabel(l10n, value), isNull);
          expect(stockFlavorLabel(l10n, value), isNull);
        }
      });
    });
  }
}
