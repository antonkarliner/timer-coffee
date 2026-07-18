import 'package:coffee_timer/utils/diary_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diaryTagsFromStorage', () {
    test('returns empty list for null', () {
      expect(diaryTagsFromStorage(null), isEmpty);
    });

    test('returns empty list for blank string', () {
      expect(diaryTagsFromStorage(''), isEmpty);
      expect(diaryTagsFromStorage('   '), isEmpty);
    });

    test('returns a single-item list for one tag', () {
      expect(diaryTagsFromStorage('fruity'), ['fruity']);
    });

    test('splits multiple tags on the separator', () {
      expect(diaryTagsFromStorage('fruity, new kettle, home'), [
        'fruity',
        'new kettle',
        'home',
      ]);
    });

    test('trims whitespace-padded items and drops empties', () {
      expect(diaryTagsFromStorage('  fruity ,  , new kettle  '), [
        'fruity',
        'new kettle',
      ]);
    });
  });

  group('diaryTagsToStorage', () {
    test('returns null for an empty list', () {
      expect(diaryTagsToStorage(const []), isNull);
    });

    test('joins a single tag without a separator', () {
      expect(diaryTagsToStorage(const ['fruity']), 'fruity');
    });

    test('joins multiple tags with the separator', () {
      expect(
        diaryTagsToStorage(const ['fruity', 'new kettle']),
        'fruity, new kettle',
      );
    });

    test('normalizes before joining, e.g. strips commas', () {
      expect(diaryTagsToStorage(const ['fru,ity']), 'fruity');
    });

    test('returns null when all tags normalize to empty', () {
      expect(diaryTagsToStorage(const [' , ', '   ']), isNull);
    });
  });

  group('normalizeDiaryTags', () {
    test('strips commas since comma is the storage separator', () {
      expect(normalizeDiaryTags(['fru,ity', 'new, kettle']), [
        'fruity',
        'new kettle',
      ]);
    });

    test('collapses internal whitespace runs to a single space', () {
      expect(normalizeDiaryTags(['new   kettle', '  fruity  ']), [
        'new kettle',
        'fruity',
      ]);
    });

    test('dedupes case-insensitively, preserving first-seen casing', () {
      expect(normalizeDiaryTags(['Fruity', 'fruity', 'FRUITY', 'Home']), [
        'Fruity',
        'Home',
      ]);
    });

    test('caps at 10 tags, keeping the first 10', () {
      final input = List.generate(15, (i) => 'tag$i');
      final result = normalizeDiaryTags(input);
      expect(result, hasLength(10));
      expect(result, List.generate(10, (i) => 'tag$i'));
    });

    test('truncates a tag to 30 characters and re-trims', () {
      final longTag = '${'a' * 29} b extra';
      final result = normalizeDiaryTags([longTag]);
      expect(result.single.length, lessThanOrEqualTo(30));
      expect(result.single, 'a' * 29);
    });

    test('drops tags that normalize to empty', () {
      expect(normalizeDiaryTags(['  ', ',,,', 'fruity']), ['fruity']);
    });
  });

  group('diaryTagsWithPending', () {
    test('returns tags unchanged for blank pending text', () {
      expect(diaryTagsWithPending(const ['fruity'], '   '), const ['fruity']);
    });

    test('appends trimmed pending text', () {
      expect(diaryTagsWithPending(const ['fruity'], ' kettle '), [
        'fruity',
        'kettle',
      ]);
    });

    test('pending duplicate is dropped by storage normalization', () {
      expect(
        diaryTagsToStorage(diaryTagsWithPending(const ['fruity'], 'Fruity')),
        'fruity',
      );
    });
  });
}
