import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/services/brew_markdown_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _kFormats = BrewExportFormats(
  datePattern: 'yyyy-MM-dd',
  use24HourTime: true,
);

const _kLabels = BrewExportLabels(
  documentTitle: 'Timer.Coffee Brew Diary',
  exportedOnLabel: 'Exported',
  dateLabel: 'Date',
  beansLabel: 'Beans',
  ratingLabel: 'Rating',
  coffeeToWaterLabel: 'Dose → Water',
  grindSizeLabel: 'Grind size',
  waterTempLabel: 'Water temp',
  tdsLabel: 'TDS',
  extractionYieldLabel: 'Extraction yield',
  tasteLabel: 'Taste',
  tasteBalanceLabels: ['Sour', 'Balanced', 'Bitter'],
  tagsLabel: 'Tags',
  notesLabel: 'Notes',
  noBeanGroupLabel: 'Other brews',
  originLabel: 'Origin',
  bookmarkLabel: 'Bookmarked',
);

DiaryEntry _makeEntry({
  required String uuid,
  DateTime? createdAt,
  String recipeName = '',
  String methodName = '',
  String? notes,
  String? beanName,
  String? roaster,
  String? origin,
  double? rating,
  bool isMarked = false,
  String? coffeeBeansUuid,
  String? grindSize,
  double? tdsPercent,
  double? extractionYieldPercent,
  double? waterTemp,
  int? tasteBalance,
  int? entrySource,
  String? tags,
  double coffeeAmount = 18,
  double waterAmount = 300,
}) {
  return DiaryEntry(
    statUuid: uuid,
    recipeId: 'recipe-1',
    recipeName: recipeName,
    brewingMethodId: 'v60',
    methodName: methodName,
    createdAt: createdAt ?? DateTime(2026, 7, 20, 8, 30),
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
    notes: notes,
    beanName: beanName,
    roaster: roaster,
    origin: origin,
    rating: rating,
    isMarked: isMarked,
    coffeeBeansUuid: coffeeBeansUuid,
    grindSize: grindSize,
    tdsPercent: tdsPercent,
    extractionYieldPercent: extractionYieldPercent,
    waterTemp: waterTemp,
    tasteBalance: tasteBalance,
    entrySource: entrySource,
    tags: tags,
  );
}

void main() {
  group('BrewExportScope.wholeDiary', () {
    test(
      'renders a document title, export timestamp, day dividers, and '
      'per-brew recipe · method headings',
      () {
        final entries = [
          _makeEntry(
            uuid: 'a',
            createdAt: DateTime(2026, 7, 20, 8, 30),
            recipeName: 'Easy and Effective V60 by Lance Hedrick',
            methodName: 'Hario V60',
            beanName: 'Yirgacheffe',
            roaster: 'Counter Culture',
            rating: 4.5,
          ),
          _makeEntry(
            uuid: 'b',
            createdAt: DateTime(2026, 7, 18, 7, 0),
            recipeName: 'Kaffeeform Recipe',
            methodName: 'AeroPress',
            beanName: 'Kayon Mountain',
            roaster: 'Prodigal',
          ),
        ];

        final output = renderBrewMarkdown(
          entries: entries,
          scope: BrewExportScope.wholeDiary,
          formats: _kFormats,
          labels: _kLabels,
          exportedAt: DateTime(2026, 7, 26, 9, 15),
        );

        expect(output, startsWith('# Timer.Coffee Brew Diary'));
        expect(output, contains('_Exported 2026-07-26 · 09:15_'));
        expect(output, contains('## 2026-07-20'));
        expect(output, contains('## 2026-07-18'));
        expect(
          output,
          contains(
            '### Easy and Effective V60 by Lance Hedrick · Hario V60',
          ),
        );
        expect(output, contains('### Kaffeeform Recipe · AeroPress'));
        expect(output, contains('_2026-07-20 · 08:30_'));
        expect(output, contains('_2026-07-18 · 07:00_'));
        // Reverse-chronological: the newer day's divider appears first.
        expect(
          output.indexOf('## 2026-07-20'),
          lessThan(output.indexOf('## 2026-07-18')),
        );
        expect(output, contains('Yirgacheffe · Counter Culture'));
        expect(output, contains('★ 4.5'));
      },
    );

    test('groups two same-day brews under one divider', () {
      final entries = [
        _makeEntry(
          uuid: 'morning',
          createdAt: DateTime(2026, 7, 20, 8, 0),
          recipeName: 'Morning recipe',
          methodName: 'V60',
        ),
        _makeEntry(
          uuid: 'evening',
          createdAt: DateTime(2026, 7, 20, 20, 0),
          recipeName: 'Evening recipe',
          methodName: 'AeroPress',
        ),
      ];

      final output = renderBrewMarkdown(
        entries: entries,
        scope: BrewExportScope.wholeDiary,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      // Exactly one day divider for both brews.
      expect('## 2026-07-20'.allMatches(output).length, 1);
      expect(output, contains('### Morning recipe · V60'));
      expect(output, contains('### Evening recipe · AeroPress'));
      // Within the day, more recent brew (evening) comes first.
      expect(
        output.indexOf('### Evening recipe'),
        lessThan(output.indexOf('### Morning recipe')),
      );
    });

    test('gives brews on different days separate dividers', () {
      final entries = [
        _makeEntry(uuid: 'd1', createdAt: DateTime(2026, 7, 1, 8, 0)),
        _makeEntry(uuid: 'd2', createdAt: DateTime(2026, 7, 2, 8, 0)),
        _makeEntry(uuid: 'd3', createdAt: DateTime(2026, 7, 3, 8, 0)),
      ];

      final output = renderBrewMarkdown(
        entries: entries,
        scope: BrewExportScope.wholeDiary,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains('## 2026-07-01'));
      expect(output, contains('## 2026-07-02'));
      expect(output, contains('## 2026-07-03'));
      // Reverse-chronological days.
      expect(
        output.indexOf('## 2026-07-03'),
        lessThan(output.indexOf('## 2026-07-02')),
      );
      expect(
        output.indexOf('## 2026-07-02'),
        lessThan(output.indexOf('## 2026-07-01')),
      );
    });

    test('ordering is stable and independent of input order', () {
      final entries = [
        _makeEntry(uuid: 'z', createdAt: DateTime(2026, 1, 1)),
        _makeEntry(uuid: 'a', createdAt: DateTime(2026, 1, 1)),
        _makeEntry(uuid: 'm', createdAt: DateTime(2026, 1, 2)),
      ];
      final shuffled = [entries[2], entries[0], entries[1]];

      final first = renderBrewMarkdown(
        entries: entries,
        scope: BrewExportScope.wholeDiary,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 1, 3),
      );
      final second = renderBrewMarkdown(
        entries: shuffled,
        scope: BrewExportScope.wholeDiary,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 1, 3),
      );

      expect(first, second);
    });

    test(
      'falls back to the formatted date/time as heading when recipe and '
      'method are both empty',
      () {
        final entry = _makeEntry(
          uuid: 'no-recipe',
          createdAt: DateTime(2026, 7, 1, 9, 30),
        );

        final output = renderBrewMarkdown(
          entries: [entry],
          scope: BrewExportScope.wholeDiary,
          formats: _kFormats,
          labels: _kLabels,
          exportedAt: DateTime(2026, 7, 26),
        );

        expect(output, contains('### 2026-07-01 · 09:30'));
      },
    );

    test('uses whichever of recipe/method is present when the other is empty', () {
      final recipeOnly = _makeEntry(
        uuid: 'recipe-only',
        createdAt: DateTime(2026, 7, 1),
        recipeName: 'Solo recipe',
      );
      final methodOnly = _makeEntry(
        uuid: 'method-only',
        createdAt: DateTime(2026, 7, 2),
        methodName: 'Solo method',
      );

      final output = renderBrewMarkdown(
        entries: [recipeOnly, methodOnly],
        scope: BrewExportScope.wholeDiary,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains('### Solo recipe'));
      expect(output, isNot(contains('Solo recipe ·')));
      expect(output, contains('### Solo method'));
      expect(output, isNot(contains('· Solo method')));
    });
  });

  group('BrewExportScope.singleBrew', () {
    test('omits the document title, export timestamp, and day divider', () {
      final entry = _makeEntry(
        uuid: 'solo',
        createdAt: DateTime(2026, 7, 20, 8, 30),
        recipeName: 'Easy V60',
        methodName: 'Hario V60',
        beanName: 'Yirgacheffe',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26, 9, 15),
      );

      expect(output, isNot(contains('Timer.Coffee Brew Diary')));
      expect(output, isNot(contains('Exported')));
      expect(output, isNot(contains('##')));
      expect(output, startsWith('# Easy V60 · Hario V60'));
      expect(output, contains('**Date:** 2026-07-20 · 08:30'));
      expect(output, contains('Yirgacheffe'));
    });

    test('falls back to the date as heading when recipe/method are empty', () {
      final entry = _makeEntry(
        uuid: 'solo-no-recipe',
        createdAt: DateTime(2026, 7, 20, 8, 30),
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26, 9, 15),
      );

      expect(output, startsWith('# 2026-07-20 · 08:30'));
    });
  });

  group('BrewExportScope.byBean', () {
    test(
      'groups reverse-chronologically within a heading per bean, with a '
      'recipe · method heading per brew and no day dividers',
      () {
        final entries = [
          _makeEntry(
            uuid: 'a1',
            createdAt: DateTime(2026, 7, 1),
            coffeeBeansUuid: 'bean-uuid-1',
            beanName: 'Yirgacheffe',
            roaster: 'Counter Culture',
            recipeName: 'Recipe A',
            methodName: 'V60',
          ),
          _makeEntry(
            uuid: 'a2',
            createdAt: DateTime(2026, 7, 5),
            coffeeBeansUuid: 'bean-uuid-1',
            beanName: 'Yirgacheffe',
            roaster: 'Counter Culture',
            recipeName: 'Recipe B',
            methodName: 'AeroPress',
          ),
          _makeEntry(
            uuid: 'b1',
            createdAt: DateTime(2026, 6, 1),
            coffeeBeansUuid: 'bean-uuid-2',
            beanName: 'Kayon Mountain',
            roaster: 'Prodigal',
          ),
        ];

        final output = renderBrewMarkdown(
          entries: entries,
          scope: BrewExportScope.byBean,
          formats: _kFormats,
          labels: _kLabels,
          exportedAt: DateTime(2026, 7, 26),
        );

        expect(output, contains('# Counter Culture · Yirgacheffe'));
        expect(output, contains('# Prodigal · Kayon Mountain'));
        expect(output, contains('## Recipe A · V60'));
        expect(output, contains('## Recipe B · AeroPress'));
        // No day dividers in by-bean scope.
        expect(output, isNot(contains('## 2026-07')));
        // Most recently brewed bean group appears first.
        expect(
          output.indexOf('# Counter Culture'),
          lessThan(output.indexOf('# Prodigal')),
        );
        // Within the group, the more recent brew comes first.
        expect(
          output.indexOf('## Recipe B'),
          lessThan(output.indexOf('## Recipe A')),
        );
      },
    );

    test('falls back to the no-bean group label when nothing is recorded', () {
      final entries = [
        _makeEntry(uuid: 'no-bean', createdAt: DateTime(2026, 7, 1)),
      ];

      final output = renderBrewMarkdown(
        entries: entries,
        scope: BrewExportScope.byBean,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains('# Other brews'));
    });
  });

  group('bookmark', () {
    test('emits the bookmark line only when isMarked is true', () {
      final marked = _makeEntry(
        uuid: 'marked',
        createdAt: DateTime(2026, 7, 1),
        isMarked: true,
      );
      final unmarked = _makeEntry(
        uuid: 'unmarked',
        createdAt: DateTime(2026, 7, 1),
        isMarked: false,
      );

      final markedOutput = renderBrewMarkdown(
        entries: [marked],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );
      final unmarkedOutput = renderBrewMarkdown(
        entries: [unmarked],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(markedOutput, contains('**Bookmarked**'));
      expect(unmarkedOutput, isNot(contains('Bookmarked')));
    });
  });

  group('origin', () {
    test('emits an origin field when present', () {
      final entry = _makeEntry(
        uuid: 'with-origin',
        createdAt: DateTime(2026, 7, 1),
        beanName: 'Yirgacheffe',
        origin: 'Ethiopia',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains('**Origin:** Ethiopia'));
    });

    test('omits the origin field when absent', () {
      final entry = _makeEntry(uuid: 'no-origin', createdAt: DateTime(2026, 7, 1));

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, isNot(contains('Origin')));
    });
  });

  group('field omission', () {
    test('omits every optional field that is null or blank', () {
      final entry = _makeEntry(uuid: 'bare', createdAt: DateTime(2026, 7, 1));

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, isNot(contains('Beans')));
      expect(output, isNot(contains('Origin')));
      expect(output, isNot(contains('Bookmarked')));
      expect(output, isNot(contains('Rating')));
      expect(output, isNot(contains('Grind size')));
      expect(output, isNot(contains('Water temp')));
      expect(output, isNot(contains('TDS')));
      expect(output, isNot(contains('Extraction yield')));
      expect(output, isNot(contains('Taste')));
      expect(output, isNot(contains('Tags')));
      expect(output, isNot(contains('Notes')));
      expect(output, isNot(contains('null')));
      // The always-present dose line is still rendered.
      expect(output, contains('Dose → Water'));
    });

    test('includes only the fields that are actually set', () {
      final entry = _makeEntry(
        uuid: 'partial',
        createdAt: DateTime(2026, 7, 1),
        grindSize: '22 clicks',
        tdsPercent: 1.38,
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains('**Grind size:** 22 clicks'));
      expect(output, contains('**TDS:** 1.38%'));
      expect(output, isNot(contains('Water temp')));
      expect(output, isNot(contains('Extraction yield')));
    });
  });

  group('markdown escaping', () {
    test(
      'escapes # and | in a single-line field so structure cannot break',
      () {
        final entry = _makeEntry(
          uuid: 'escape-fields',
          createdAt: DateTime(2026, 7, 1),
          beanName: 'Pipe | Test # Bean',
          roaster: 'Roaster # 1',
        );

        final output = renderBrewMarkdown(
          entries: [entry],
          scope: BrewExportScope.singleBrew,
          formats: _kFormats,
          labels: _kLabels,
          exportedAt: DateTime(2026, 7, 26),
        );

        expect(output, contains(r'Pipe \| Test \# Bean'));
        expect(output, contains(r'Roaster \# 1'));
        // The raw, unescaped text must never reach the output.
        expect(output, isNot(contains('Pipe | Test # Bean')));
        expect(output, isNot(contains('Roaster # 1')));
      },
    );

    test(
      'escapes # in the recipe/method heading so it cannot break document '
      'structure',
      () {
        final entry = _makeEntry(
          uuid: 'escape-heading',
          createdAt: DateTime(2026, 7, 1),
          recipeName: 'Recipe # 1',
          methodName: 'Method # 2',
        );

        final output = renderBrewMarkdown(
          entries: [entry],
          scope: BrewExportScope.singleBrew,
          formats: _kFormats,
          labels: _kLabels,
          exportedAt: DateTime(2026, 7, 26),
        );

        expect(output, contains(r'Recipe \# 1 · Method \# 2'));
        expect(output, isNot(contains('Recipe # 1')));
      },
    );

    test('escapes control characters in tag values', () {
      final entry = _makeEntry(
        uuid: 'escape-tags',
        createdAt: DateTime(2026, 7, 1),
        tags: 'fruity#bold',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains(r'#fruity\#bold'));
    });

    test('escapes a leading # in notes so it cannot open a heading', () {
      final entry = _makeEntry(
        uuid: 'escape-notes-heading',
        createdAt: DateTime(2026, 7, 1),
        notes: '# Not a heading\nJust notes.',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains(r'> \# Not a heading'));
      expect(output, isNot(contains('\n# Not a heading')));
    });

    test('escapes a leading list marker in notes so it cannot open a list', () {
      final entry = _makeEntry(
        uuid: 'escape-notes-list',
        createdAt: DateTime(2026, 7, 1),
        notes: '- looks like a bullet\n1. looks like a list item',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, contains(r'> \- looks like a bullet'));
      expect(output, contains(r'> 1\. looks like a list item'));
    });
  });

  group('multi-line notes', () {
    test('renders every line as a blockquote, preserving blank lines', () {
      final entry = _makeEntry(
        uuid: 'multiline',
        createdAt: DateTime(2026, 7, 1),
        notes: 'First paragraph.\n\nSecond paragraph,\nwrapped onto two lines.',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(
        output,
        contains(
          '**Notes**\n'
          '> First paragraph.\n'
          '>\n'
          '> Second paragraph,\n'
          '> wrapped onto two lines.',
        ),
      );
    });

    test('omits the notes block entirely for blank notes', () {
      final entry = _makeEntry(
        uuid: 'blank-notes',
        createdAt: DateTime(2026, 7, 1),
        notes: '   \n  ',
      );

      final output = renderBrewMarkdown(
        entries: [entry],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, isNot(contains('Notes')));
      expect(output, isNot(contains('>')));
    });
  });

  group('empty input', () {
    test('wholeDiary still renders the document title with no entries', () {
      final output = renderBrewMarkdown(
        entries: const [],
        scope: BrewExportScope.wholeDiary,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26, 9, 15),
      );

      expect(output, contains('Timer.Coffee Brew Diary'));
      expect(output, contains('Exported 2026-07-26 · 09:15'));
      expect(output, isNot(contains('##')));
    });

    test('singleBrew returns an empty string', () {
      final output = renderBrewMarkdown(
        entries: const [],
        scope: BrewExportScope.singleBrew,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, isEmpty);
    });

    test('byBean returns an empty string', () {
      final output = renderBrewMarkdown(
        entries: const [],
        scope: BrewExportScope.byBean,
        formats: _kFormats,
        labels: _kLabels,
        exportedAt: DateTime(2026, 7, 26),
      );

      expect(output, isEmpty);
    });
  });
}
