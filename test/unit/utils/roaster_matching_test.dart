import 'package:coffee_timer/utils/roaster_matching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeRoasterName', () {
    test('is case-insensitive', () {
      expect(
        normalizeRoasterName('Onyx Coffee Lab'),
        normalizeRoasterName('onyx coffee lab'),
      );
      expect(normalizeRoasterName('TASTY COFFEE'), 'tasty coffee');
    });

    test('is accent-insensitive', () {
      expect(
        normalizeRoasterName('Belleville Brûlerie'),
        normalizeRoasterName('Belleville Brulerie'),
      );
      expect(normalizeRoasterName('Café Crème'), 'cafe creme');
    });

    test('combines case, accent, and surrounding whitespace', () {
      expect(
        normalizeRoasterName('  BELLEVILLE BRÛLERIE '),
        normalizeRoasterName('belleville brulerie'),
      );
    });

    test('case-folds non-Latin scripts without stripping their letters', () {
      // Cyrillic has no Latin diacritics to remove; it should only case-fold.
      expect(normalizeRoasterName('Ботаника'), 'ботаника');
    });

    test('is idempotent', () {
      final once = normalizeRoasterName('Belleville Brûlerie');
      expect(normalizeRoasterName(once), once);
    });

    test('reduces blank input to an empty string', () {
      expect(normalizeRoasterName('   '), '');
    });
  });
}
