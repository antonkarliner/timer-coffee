import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_export_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('brewExportFileSlug', () {
    test('slugifies a bean name for use in a filename', () {
      expect(brewExportFileSlug('Red Brick'), 'red_brick');
      expect(brewExportFileSlug('Punk Extravagante & Jugoso'), 'punk_extravagante_jugoso');
    });

    test('folds diacritics rather than dropping the letter', () {
      expect(brewExportFileSlug('Café Ethiopia'), 'cafe_ethiopia');
    });

    test('strips characters that are unsafe in a filename', () {
      expect(brewExportFileSlug('Geisha / Lot #7: "rare"'), 'geisha_lot_7_rare');
    });

    test('returns null when nothing usable survives, so the caller falls back', () {
      // A fully non-Latin name would otherwise yield an empty slug and a
      // filename like `timer_coffee__20260727.md`.
      expect(brewExportFileSlug('日本の豆'), isNull);
      expect(brewExportFileSlug('   '), isNull);
      expect(brewExportFileSlug(null), isNull);
    });

    test('caps length and never ends on a separator', () {
      final slug = brewExportFileSlug('${'A' * 30} ${'B' * 30}')!;
      expect(slug.length, lessThanOrEqualTo(40));
      expect(slug, isNot(endsWith('_')));
    });
  });

  testWidgets(
    'buildBrewExportLabels resolves every field from AppLocalizations',
    (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              loc = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final labels = buildBrewExportLabels(loc);

      expect(labels.documentTitle, loc.brewExportDocumentTitle);
      expect(labels.exportedOnLabel, loc.brewExportExportedOn);
      expect(labels.dateLabel, loc.brewExportDateLabel);
      expect(labels.beansLabel, loc.beans);
      expect(labels.ratingLabel, loc.rating);
      expect(labels.coffeeToWaterLabel, loc.brewDiaryDoseWater);
      expect(labels.grindSizeLabel, loc.grindsize);
      expect(labels.waterTempLabel, loc.watertemp);
      expect(labels.tdsLabel, loc.brewExportTdsLabel);
      expect(labels.extractionYieldLabel, loc.brewDiaryExtraction);
      expect(labels.tasteLabel, loc.brewDiaryTasted);
      expect(labels.tasteBalanceLabels, [
        loc.tasteSour,
        loc.tasteBalanced,
        loc.tasteBitter,
      ]);
      expect(labels.tagsLabel, loc.diaryTags);
      expect(labels.notesLabel, loc.notes);
      expect(labels.noBeanGroupLabel, loc.brewExportNoBeanGroup);
    },
  );

  testWidgets(
    'buildBrewExportFormats resolves through DateTimeFormatService rather '
    'than a hardcoded pattern',
    (tester) async {
      late BuildContext capturedContext;
      late AppLocalizations loc;
      await tester.pumpWidget(
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                capturedContext = context;
                loc = AppLocalizations.of(context)!;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final formats = buildBrewExportFormats(capturedContext, loc);

      // With the default (auto) date/time style, DateTimeFormatService falls
      // back to the locale default / device default — asserting equality
      // against a fresh service instance (rather than a literal pattern
      // string) is what proves the call goes through the service instead of
      // bypassing it with `loc.dateFormat` directly.
      final fmtSvc = DateTimeFormatService();
      expect(formats.datePattern, fmtSvc.datePattern(loc.dateFormat));
      expect(
        formats.use24HourTime,
        fmtSvc.use24Hour(
          MediaQuery.of(capturedContext).alwaysUse24HourFormat,
        ),
      );
    },
  );
}
