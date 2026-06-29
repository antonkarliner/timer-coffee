import 'package:coffee_timer/models/roaster_profile_model.dart';
import 'package:coffee_timer/utils/roaster_matching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RoasterProfileModel profile({
    String roasterName = 'Belleville Brûlerie',
    String? aliases,
  }) =>
      RoasterProfileModel(
        id: 'id',
        slug: 'slug',
        coffeeRoasterId: 1,
        roasterName: roasterName,
        isActive: true,
        aliases: aliases,
      );

  // Mirrors how _computeCanReview / the review form decide whether a user's
  // free-text bean roaster string belongs to this roaster.
  bool owns(RoasterProfileModel p, String beanRoaster) =>
      p.matchableRoasterNames.contains(normalizeRoasterName(beanRoaster));

  group('aliasList', () {
    test('splits comma-separated aliases, trims, and drops empties', () {
      final p = profile(aliases: 'Botanica, BOTANICA ,, Ботаника');
      expect(p.aliasList, ['Botanica', 'BOTANICA', 'Ботаника']);
    });

    test('is empty for null or blank aliases', () {
      expect(profile(aliases: null).aliasList, isEmpty);
      expect(profile(aliases: '   ').aliasList, isEmpty);
    });
  });

  group('matchableRoasterNames', () {
    test('includes the normalized canonical name and aliases', () {
      final p = profile(
        roasterName: 'Botanica Coffee Roasters',
        aliases: 'Botanica, BOTANICA',
      );
      expect(p.matchableRoasterNames, contains('botanica coffee roasters'));
      expect(p.matchableRoasterNames, contains('botanica'));
    });
  });

  group('review-eligibility matching', () {
    test('matches a bean roaster case-insensitively', () {
      final p = profile(roasterName: 'Onyx Coffee Lab');
      expect(owns(p, 'ONYX COFFEE LAB'), isTrue);
      expect(owns(p, 'onyx coffee lab'), isTrue);
    });

    test('matches a bean roaster accent-insensitively', () {
      final p = profile(roasterName: 'Belleville Brûlerie');
      expect(owns(p, 'Belleville Brulerie'), isTrue);
      expect(owns(p, 'belleville brûlerie'), isTrue);
    });

    test('matches via an alias, ignoring case, accents, and whitespace', () {
      final p = profile(
        roasterName: 'Botanica Coffee Roasters',
        aliases: 'Botanica',
      );
      expect(owns(p, 'BOTÁNICA'), isTrue);
      expect(owns(p, '  botanica  '), isTrue);
    });

    test('does not match an unrelated roaster', () {
      final p = profile(roasterName: 'Onyx Coffee Lab', aliases: 'Onyx');
      expect(owns(p, 'Tasty Coffee'), isFalse);
    });
  });

  group('fromJson', () {
    test('parses aliases and logged_bag_count', () {
      final p = RoasterProfileModel.fromJson({
        'id': 'id',
        'slug': 'slug',
        'coffee_roaster_id': 1,
        'roaster_name': 'Botanica Coffee Roasters',
        'aliases': 'Botanica,BOTANICA',
        'is_active': true,
        'logged_bag_count': 42,
      });
      expect(p.aliases, 'Botanica,BOTANICA');
      expect(p.aliasList, ['Botanica', 'BOTANICA']);
      expect(p.loggedBagCount, 42);
      expect(p.matchableRoasterNames, contains('botanica'));
    });

    test('defaults aliases to null and logged_bag_count to 0 when absent', () {
      final p = RoasterProfileModel.fromJson({
        'id': 'id',
        'slug': 'slug',
        'coffee_roaster_id': 1,
        'roaster_name': 'X',
        'is_active': true,
      });
      expect(p.aliases, isNull);
      expect(p.aliasList, isEmpty);
      expect(p.loggedBagCount, 0);
    });
  });
}
