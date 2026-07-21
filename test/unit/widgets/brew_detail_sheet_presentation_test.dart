import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/extraction_calculator_screen.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/add_coffee_beans_widget.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  test('typed extraction result updates the loaded entry in memory', () {
    final updated = applyExtractionCalculatorResult(
      _entry,
      const ExtractionCalculatorResult(
        tdsPercent: 1.31,
        extractionYieldPercent: 20.8,
      ),
    );

    expect(updated.statUuid, _entry.statUuid);
    expect(updated.tdsPercent, 1.31);
    expect(updated.extractionYieldPercent, 20.8);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    String? roaster,
    String? origin,
    ValueChanged<DiaryEntry>? onOpenBeanJourney,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BrewDetailSheet(
            entry: _entry.copyWith(roaster: roaster, origin: origin),
            onOpenBeanJourney: onOpenBeanJourney,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bean subtitle joins trimmed roaster and origin', (tester) async {
    await pumpSheet(
      tester,
      roaster: '  Test Roaster  ',
      origin: '  Ethiopia  ',
    );

    expect(find.text('Test Roaster · Ethiopia'), findsOneWidget);
    expect(find.text(_entry.beanName!), findsOneWidget);
  });

  testWidgets('linked bean summary opens Journey without Details action', (
    tester,
  ) async {
    var journeyOpenCount = 0;
    await pumpSheet(
      tester,
      roaster: 'Test Roaster',
      origin: 'Ethiopia',
      onOpenBeanJourney: (_) => journeyOpenCount++,
    );

    expect(find.byKey(const Key('beanDetailsButton')), findsNothing);
    await tester.tap(find.byKey(const Key('beanSummaryButton')));
    await tester.pump();

    expect(journeyOpenCount, 1);
  });

  testWidgets(
    'detail shows full-strength V60 icon and compact rectangle logo',
    (tester) async {
      await pumpSheet(tester, roaster: 'Test Roaster', origin: 'Ethiopia');

      final methodIcon = tester.widget<Icon>(find.byIcon(Coffeico.hario_v60));
      final colors = Theme.of(
        tester.element(find.byType(BrewDetailSheet)),
      ).colorScheme;
      expect(methodIcon.color, colors.primary);
      expect(methodIcon.size, AppIconSize.medium);
      expect(find.text('V60'), findsOneWidget);

      final logo = tester.widget<RoasterLogo>(find.byType(RoasterLogo));
      expect(logo.width, AppSpacing.xxl + AppSpacing.lg);
      expect(logo.height, AppSpacing.xxl);
      expect(logo.width, greaterThan(logo.height));
      expect(logo.width, isNot(AppIconSize.small));
      expect(logo.height, isNot(AppIconSize.small));
    },
  );

  testWidgets('bean subtitle renders roaster without a separator', (
    tester,
  ) async {
    await pumpSheet(tester, roaster: '  Test Roaster  ', origin: '  ');

    expect(find.text('Test Roaster'), findsOneWidget);
  });

  testWidgets('bean subtitle renders origin without a separator', (
    tester,
  ) async {
    await pumpSheet(tester, roaster: '', origin: '  Ethiopia  ');

    expect(find.text('Ethiopia'), findsOneWidget);
  });

  testWidgets('header wraps recipe name and owns bookmark and delete actions', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    const longName =
        'Easy and Effective V60 by James Hoffmann with the complete recipe name';
    await harness.pump(tester, _entry.copyWith(recipeName: longName));

    final recipeText = tester.widget<Text>(
      find.byKey(const Key('brewDetailRecipeName')),
    );
    expect(recipeText.data, longName);
    expect(recipeText.maxLines, isNull);
    expect(recipeText.overflow, isNull);
    expect(find.byKey(const Key('brewDetailMenuButton')), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    final menu = tester.widget<PopupMenuButton<String>>(
      find.byKey(const Key('brewDetailMenuButton')),
    );
    expect(menu.position, PopupMenuPosition.under);
    expect(menu.offset, const Offset(0, AppSpacing.xs));
    expect(menu.shape, isA<RoundedRectangleBorder>());

    await tester.tap(find.byTooltip('Add bookmark'));
    await tester.pumpAndSettle();
    expect((await harness.stat()).isMarked, isTrue);
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    await tester.tap(find.byKey(const Key('brewDetailMenuButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('deleteBrewMenuItem')), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('focused edit affordances replace the global edit form', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    await harness.pump(tester, _entry.copyWith(entrySource: 1, rating: 4.5));

    for (final key in <String>[
      'editAmountsButton',
      'editGrindButton',
      'editTemperatureButton',
      'editTasteButton',
      'editNotesButton',
      'editRatingButton',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.widgetWithText(AppTextButton, 'Edit'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half), findsOneWidget);

    for (final entry in <(String, String)>[
      ('editAmountsButton', 'Edit dose and water'),
      ('editGrindButton', 'Edit grind size'),
      ('editTemperatureButton', 'Edit water temperature'),
      ('editTasteButton', 'Edit taste'),
      ('editNotesButton', 'Edit notes'),
      ('editRatingButton', 'Rate this brew'),
    ]) {
      await tester.ensureVisible(find.byKey(Key(entry.$1)));
      await tester.tap(find.byKey(Key(entry.$1)));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      await tester.tap(find.byKey(const Key('focusedCancelButton')));
      await tester.pumpAndSettle();
    }
    expect(harness.stats.totalFocusedCalls, 0);
  });

  testWidgets('focused edit dialog keeps content and actions compact', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    await harness.pump(tester, _entry.copyWith(entrySource: 1));
    tester.view.physicalSize = const Size(472, 1024);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('editTasteButton')));
    await tester.tap(find.byKey(const Key('editTasteButton')));
    await tester.pumpAndSettle();

    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(3));
    final chipCenters = [
      for (var index = 0; index < 3; index++) tester.getCenter(chips.at(index)),
    ];
    expect(chipCenters[0].dy, closeTo(chipCenters[1].dy, 0.1));
    expect(chipCenters[1].dy, closeTo(chipCenters[2].dy, 0.1));

    final clearRect = tester.getRect(
      find.byKey(const Key('focusedClearButton')),
    );
    final cancelRect = tester.getRect(
      find.byKey(const Key('focusedCancelButton')),
    );
    final saveRect = tester.getRect(find.byKey(const Key('focusedSaveButton')));
    expect(clearRect.center.dy, closeTo(cancelRect.center.dy, 0.1));
    expect(cancelRect.center.dy, closeTo(saveRect.center.dy, 0.1));
    expect(clearRect.left, lessThan(cancelRect.left));
    expect(cancelRect.left, lessThan(saveRect.left));

    expect(tester.takeException(), isNull);
  });

  testWidgets('auto-logged entry has no amount edit affordance', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create(entrySource: 0);
    addTearDown(harness.close);
    await harness.pump(tester, _entry.copyWith(entrySource: 0));

    expect(find.byKey(const Key('editAmountsButton')), findsNothing);
    expect(find.byKey(const Key('editGrindButton')), findsOneWidget);
  });

  testWidgets('focused saves call only their matching provider mutation', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    await harness.pump(tester, _entry.copyWith(entrySource: 1));

    for (final key in <String>[
      'editAmountsButton',
      'editGrindButton',
      'editTemperatureButton',
      'editTasteButton',
      'editNotesButton',
      'editRatingButton',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('focusedSaveButton')));
      await tester.pumpAndSettle();
    }

    expect(harness.stats.amountCalls, 1);
    expect(harness.stats.grindCalls, 1);
    expect(harness.stats.temperatureCalls, 1);
    expect(harness.stats.tasteCalls, 1);
    expect(harness.stats.notesCalls, 1);
    expect(harness.stats.ratingCalls, 1);
  });

  testWidgets('Clear is pending, Cancel does not write, and Save clears', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create(waterTemp: 93);
    addTearDown(harness.close);
    await harness.pump(
      tester,
      _entry.copyWith(entrySource: 1, waterTemp: 93.0),
    );

    await tester.tap(find.byKey(const Key('editTemperatureButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focusedClearButton')));
    await tester.tap(find.byKey(const Key('focusedCancelButton')));
    await tester.pumpAndSettle();
    expect(harness.stats.temperatureCalls, 0);
    expect((await harness.stat()).waterTemp, 93);

    await tester.tap(find.byKey(const Key('editTemperatureButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focusedClearButton')));
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();
    expect(harness.stats.temperatureCalls, 1);
    expect((await harness.stat()).waterTemp, isNull);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('rating save blocks duplicates and renders saved half rating', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create(rating: null);
    addTearDown(harness.close);
    harness.stats.ratingGate = Completer<void>();
    await harness.pump(tester, _entry.copyWith(entrySource: 1, rating: null));

    await tester.ensureVisible(find.byKey(const Key('editRatingButton')));
    await tester.tap(find.byKey(const Key('editRatingButton')));
    await tester.pumpAndSettle();
    final bar = find.byKey(const Key('focusedRatingBar'));
    final box = tester.getRect(bar);
    await tester.tapAt(Offset(box.left + box.width * 0.9, box.center.dy));
    await tester.pump();
    expect(find.text('4.5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pump();
    expect(harness.stats.ratingCalls, 1);
    expect(find.byType(AlertDialog), findsOneWidget);

    harness.stats.ratingGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half), findsOneWidget);
  });

  testWidgets('save failure stays open with localized copy', (tester) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    harness.stats.failRating = true;
    await harness.pump(tester, _entry.copyWith(entrySource: 1));

    await tester.ensureVisible(find.byKey(const Key('editRatingButton')));
    await tester.tap(find.byKey(const Key('editRatingButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Could not save changes. Try again.'), findsOneWidget);
    expect(find.textContaining('forced rating failure'), findsNothing);
  });

  testWidgets(
    'shared selector awaits, blocks duplicates, survives failure, and retries',
    (tester) async {
      final harness = await _WidgetHarness.create();
      addTearDown(harness.close);
      final firstGate = Completer<void>();
      var calls = 0;
      await harness.pumpSelector(tester, (uuid) async {
        calls++;
        if (calls == 1) {
          await firstGate.future;
          throw StateError('raw selector failure');
        }
      });

      await tester.tap(find.text('Second beans'));
      await tester.pump();
      final nextButton = find.widgetWithText(AppElevatedButton, 'Next');
      await tester.tap(nextButton);
      await tester.tap(nextButton);
      await tester.pump();

      expect(calls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Test beans'))
            .onTap,
        isNull,
      );

      firstGate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AddCoffeeBeansWidget), findsOneWidget);
      expect(find.text('Unexpected error occurred'), findsOneWidget);
      expect(find.textContaining('raw selector failure'), findsNothing);

      await tester.tap(find.widgetWithText(AppElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Unexpected error occurred'), findsNothing);
    },
  );

  testWidgets(
    'unlinked entry attaches an active bean absent from diary history',
    (tester) async {
      final harness = await _WidgetHarness.create(initialBeanUuid: null);
      addTearDown(harness.close);
      harness.stats.beanGate = Completer<void>();
      await harness.pump(
        tester,
        _entry.copyWith(
          coffeeBeansUuid: null,
          beanName: null,
          roaster: null,
          origin: null,
        ),
      );

      expect(find.byKey(const Key('addDiaryBeanButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('addDiaryBeanButton')));
      await tester.pumpAndSettle();
      expect(find.text('Second beans'), findsOneWidget);
      await tester.tap(find.text('Second beans'));
      await tester.pump();
      harness.database.requestedRoasters.clear();
      await tester.tap(find.widgetWithText(AppElevatedButton, 'Next'));
      await tester.pump();
      expect(
        tester
            .widget<AppElevatedButton>(
              find.byKey(const Key('addDiaryBeanButton')),
            )
            .onPressed,
        isNull,
      );
      harness.stats.beanGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(BrewDetailSheet), findsOneWidget);
      expect(find.byKey(const Key('linkedBeanBlock')), findsOneWidget);
      expect(
        tester.widget<Card>(find.byKey(const Key('linkedBeanBlock'))).margin,
        EdgeInsets.zero,
      );
      expect(find.text('Second beans'), findsOneWidget);
      expect(find.text('Second Roaster · Kenya'), findsOneWidget);
      expect(find.byKey(const Key('beanDetailsButton')), findsNothing);
      expect(find.byKey(const Key('changeDiaryBeanButton')), findsOneWidget);
      expect(find.byKey(const Key('removeDiaryBeanButton')), findsOneWidget);
      expect((await harness.stat()).coffeeBeansUuid, _WidgetHarness.beanBUuid);
      expect(await harness.weight(_WidgetHarness.beanBUuid), 85);
      expect(
        tester.widget<RoasterLogo>(find.byType(RoasterLogo)).originalUrl,
        'https://example.com/Second Roaster.png',
      );
      expect(find.byIcon(Icons.note_outlined), findsOneWidget);
    },
  );

  testWidgets('replacement updates UUID, metadata, and logo without closing', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create(
      initialBeanUuid: _WidgetHarness.beanUuid,
      beanAWeight: 85,
    );
    addTearDown(harness.close);
    await harness.pump(
      tester,
      _entry.copyWith(
        coffeeBeansUuid: _WidgetHarness.beanUuid,
        beanName: 'Test beans',
        roaster: 'Test Roaster',
        origin: 'Ethiopia',
      ),
    );

    await tester.tap(find.byKey(const Key('changeDiaryBeanButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second beans'));
    await tester.pump();
    harness.database.requestedRoasters.clear();
    await tester.tap(find.widgetWithText(AppElevatedButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.byType(BrewDetailSheet), findsOneWidget);
    expect((await harness.stat()).coffeeBeansUuid, _WidgetHarness.beanBUuid);
    expect(await harness.weight(_WidgetHarness.beanUuid), 100);
    expect(await harness.weight(_WidgetHarness.beanBUuid), 85);
    expect(find.text('Second beans'), findsOneWidget);
    expect(find.text('Second Roaster · Kenya'), findsOneWidget);
    expect(
      tester.widget<RoasterLogo>(find.byType(RoasterLogo)).originalUrl,
      'https://example.com/Second Roaster.png',
    );
  });

  testWidgets('detachment clears bean presentation and exposes Add', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create(beanAWeight: 85);
    addTearDown(harness.close);
    await harness.pump(tester, _entry);

    await tester.tap(find.byKey(const Key('removeDiaryBeanButton')));
    await tester.pumpAndSettle();

    expect((await harness.stat()).coffeeBeansUuid, isNull);
    expect(await harness.weight(_WidgetHarness.beanUuid), 100);
    expect(find.byKey(const Key('unlinkedBeanBlock')), findsOneWidget);
    expect(find.byKey(const Key('addDiaryBeanButton')), findsOneWidget);
    expect(find.text('Test beans'), findsNothing);
  });

  testWidgets('canceling selector performs no association write', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create(initialBeanUuid: null);
    addTearDown(harness.close);
    await harness.pump(
      tester,
      _entry.copyWith(
        coffeeBeansUuid: null,
        beanName: null,
        roaster: null,
        origin: null,
      ),
    );

    await tester.tap(find.byKey(const Key('addDiaryBeanButton')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(harness.stats.beanCalls, 0);
    expect((await harness.stat()).coffeeBeansUuid, isNull);
  });

  testWidgets(
    'saving disables association actions and failure preserves bean',
    (tester) async {
      final harness = await _WidgetHarness.create(beanAWeight: 85);
      addTearDown(harness.close);
      harness.stats.beanGate = Completer<void>();
      harness.stats.failBean = true;
      await harness.pump(tester, _entry);

      await tester.tap(find.byKey(const Key('changeDiaryBeanButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second beans'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppElevatedButton, 'Next'));
      await tester.pump();

      expect(
        tester
            .widget<AppTextButton>(
              find.byKey(const Key('changeDiaryBeanButton')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('removeDiaryBeanButton')))
            .onPressed,
        isNull,
      );
      expect(harness.stats.beanCalls, 1);

      harness.stats.beanGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AddCoffeeBeansWidget), findsOneWidget);
      expect(find.text('Unexpected error occurred'), findsWidgets);
      expect(find.textContaining('forced bean failure'), findsNothing);
      expect((await harness.stat()).coffeeBeansUuid, _WidgetHarness.beanUuid);
      expect(await harness.weight(_WidgetHarness.beanUuid), 85);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('Test beans'), findsOneWidget);
      expect(find.text('Second beans'), findsNothing);
    },
  );

  testWidgets('tags render as chips and editing persists normalized storage', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    await harness.pump(
      tester,
      _entry.copyWith(entrySource: 1, tags: 'fruity, new kettle'),
    );

    expect(find.text('fruity'), findsOneWidget);
    expect(find.text('new kettle'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('editTagsButton')));
    await tester.tap(find.byKey(const Key('editTagsButton')));
    await tester.pumpAndSettle();
    expect(find.text('Edit tags'), findsOneWidget);

    final tagsInputField = find.descendant(
      of: find.byKey(const Key('focusedTagsInput')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(tagsInputField, 'Home brew');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(harness.stats.tagsCalls, 1);
    expect((await harness.stat()).tags, 'fruity, new kettle, Home brew');
    expect(find.text('fruity'), findsOneWidget);
    expect(find.text('new kettle'), findsOneWidget);
    expect(find.text('Home brew'), findsOneWidget);
  });

  testWidgets('a comma in the tags field commits a chip immediately', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    await harness.pump(tester, _entry.copyWith(entrySource: 1, tags: 'fruity'));

    await tester.ensureVisible(find.byKey(const Key('editTagsButton')));
    await tester.tap(find.byKey(const Key('editTagsButton')));
    await tester.pumpAndSettle();

    final tagsInputField = find.descendant(
      of: find.byKey(const Key('focusedTagsInput')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(tagsInputField, 'Home, brew');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(harness.stats.tagsCalls, 1);
    expect((await harness.stat()).tags, 'fruity, Home, brew');
  });

  testWidgets('typed-but-unsubmitted tag text is saved on a direct Save tap', (
    tester,
  ) async {
    final harness = await _WidgetHarness.create();
    addTearDown(harness.close);
    await harness.pump(tester, _entry.copyWith(entrySource: 1, tags: 'fruity'));

    await tester.ensureVisible(find.byKey(const Key('editTagsButton')));
    await tester.tap(find.byKey(const Key('editTagsButton')));
    await tester.pumpAndSettle();

    final tagsInputField = find.descendant(
      of: find.byKey(const Key('focusedTagsInput')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(tagsInputField, 'kettle');
    await tester.tap(find.byKey(const Key('focusedSaveButton')));
    await tester.pumpAndSettle();

    expect(harness.stats.tagsCalls, 1);
    expect((await harness.stat()).tags, 'fruity, kettle');
    expect(find.text('kettle'), findsOneWidget);
  });

  testWidgets(
    'tags dialog shows a quick-pick chip from suggestions and its confirm '
    'button reads Done',
    (tester) async {
      final harness = await _WidgetHarness.create();
      addTearDown(harness.close);
      // A second, unrelated stat so fetchAllDistinctTags() surfaces
      // 'kettle' as a suggestion the main entry doesn't already carry.
      await harness.db.userStatsDao.insertUserStat(
        UserStatsModel(
          statUuid: 'stat-2',
          recipeId: 'recipe-1',
          coffeeAmount: 15,
          waterAmount: 250,
          sweetnessSliderPosition: 1,
          strengthSliderPosition: 1,
          brewingMethodId: 'v60',
          createdAt: DateTime.utc(2026, 7, 13),
          tags: 'kettle',
          entrySource: 1,
          isMarked: false,
          versionVector: VersionVector.initial('stat-2-device').toString(),
          isDeleted: false,
        ),
      );
      await harness.pump(
        tester,
        _entry.copyWith(entrySource: 1, tags: 'fruity'),
      );

      await tester.ensureVisible(find.byKey(const Key('editTagsButton')));
      await tester.tap(find.byKey(const Key('editTagsButton')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AppElevatedButton>(
              find.byKey(const Key('focusedSaveButton')),
            )
            .label,
        'Done',
      );

      final quickPick = find.widgetWithText(ActionChip, 'kettle');
      expect(quickPick, findsOneWidget);
      await tester.tap(quickPick);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('focusedSaveButton')));
      await tester.pumpAndSettle();

      expect(harness.stats.tagsCalls, 1);
      expect((await harness.stat()).tags, 'fruity, kettle');
    },
  );
}

final _entry = DiaryEntry(
  statUuid: 'stat-1',
  recipeId: 'recipe-1',
  recipeName: 'Test recipe',
  brewingMethodId: 'v60',
  methodName: 'V60',
  createdAt: DateTime(2026, 7, 14, 10),
  coffeeAmount: 15,
  waterAmount: 250,
  isMarked: false,
  coffeeBeansUuid: 'bean-1',
  beanName: 'Test beans',
);

class _WidgetHarness {
  _WidgetHarness({
    required this.db,
    required this.database,
    required this.beans,
    required this.stats,
  });

  static const statUuid = 'stat-1';
  static const beanUuid = 'bean-1';
  static const beanBUuid = 'bean-2';
  final AppDatabase db;
  final _RecordingDatabaseProvider database;
  final CoffeeBeansProvider beans;
  final _RecordingUserStatProvider stats;

  static Future<_WidgetHarness> create({
    int? entrySource = 1,
    double? waterTemp = 93,
    double? rating = 4,
    String? initialBeanUuid = beanUuid,
    double? beanAWeight = 100,
    double? beanBWeight = 100,
  }) async {
    final db = openTestDatabase();
    await db.coffeeBeansDao.insertCoffeeBeans(
      CoffeeBeansModel(
        beansUuid: beanUuid,
        roaster: 'Test Roaster',
        name: 'Test beans',
        origin: 'Ethiopia',
        packageWeightGrams: beanAWeight,
        versionVector: VersionVector.initial('bean-a-device').toString(),
      ),
    );
    await db.coffeeBeansDao.insertCoffeeBeans(
      CoffeeBeansModel(
        beansUuid: beanBUuid,
        roaster: 'Second Roaster',
        name: 'Second beans',
        origin: 'Kenya',
        packageWeightGrams: beanBWeight,
        versionVector: VersionVector.initial('bean-b-device').toString(),
      ),
    );
    await db.userStatsDao.insertUserStat(
      UserStatsModel(
        statUuid: statUuid,
        recipeId: 'recipe-1',
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 1,
        brewingMethodId: 'v60',
        createdAt: DateTime.utc(2026, 7, 14),
        notes: 'Initial note',
        rating: rating,
        isMarked: false,
        coffeeBeansUuid: initialBeanUuid,
        grindSize: '24 clicks',
        waterTemp: waterTemp,
        tasteBalance: 0,
        entrySource: entrySource,
        versionVector: VersionVector.initial('stat-device').toString(),
        isDeleted: false,
      ),
    );
    final database = _RecordingDatabaseProvider(db);
    final beans = CoffeeBeansProvider(db, database);
    final stats = _RecordingUserStatProvider(db, beans);
    return _WidgetHarness(
      db: db,
      database: database,
      beans: beans,
      stats: stats,
    );
  }

  Future<void> pump(WidgetTester tester, DiaryEntry entry) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseProvider>.value(value: database),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
          ChangeNotifierProvider<UserStatProvider>.value(value: stats),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BrewDetailSheet(entry: entry)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSelector(
    WidgetTester tester,
    Future<void> Function(String uuid) onSelect,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DatabaseProvider>.value(value: database),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AddCoffeeBeansWidget(onSelect: onSelect)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<UserStatsModel> stat() async =>
      (await db.userStatsDao.fetchStatByUuid(statUuid))!;

  Future<double?> weight(String uuid) async =>
      (await db.coffeeBeansDao.fetchCoffeeBeansByUuid(
        uuid,
      ))?.packageWeightGrams;

  Future<void> close() async {
    stats.dispose();
    beans.dispose();
    await db.close();
  }
}

class _RecordingDatabaseProvider extends DatabaseProvider {
  _RecordingDatabaseProvider(super.db);

  final List<String> requestedRoasters = [];

  @override
  Future<Map<String, String?>> fetchCachedRoasterLogoUrls(
    String roasterName,
  ) async {
    requestedRoasters.add(roasterName);
    return {'original': 'https://example.com/$roasterName.png', 'mirror': null};
  }
}

class _RecordingUserStatProvider extends UserStatProvider {
  _RecordingUserStatProvider(super.db, super.coffeeBeansProvider);

  int amountCalls = 0;
  int grindCalls = 0;
  int temperatureCalls = 0;
  int tasteCalls = 0;
  int notesCalls = 0;
  int ratingCalls = 0;
  int beanCalls = 0;
  int tagsCalls = 0;
  bool failRating = false;
  bool failBean = false;
  Completer<void>? ratingGate;
  Completer<void>? beanGate;

  int get totalFocusedCalls =>
      amountCalls +
      grindCalls +
      temperatureCalls +
      tasteCalls +
      notesCalls +
      ratingCalls;

  @override
  Future<void> updateDiaryAmounts({
    required String statUuid,
    required double coffeeAmount,
    required double waterAmount,
  }) async {
    amountCalls++;
    await super.updateDiaryAmounts(
      statUuid: statUuid,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
    );
  }

  @override
  Future<void> updateDiaryGrindSize({
    required String statUuid,
    required String grindSize,
  }) async {
    grindCalls++;
    await super.updateDiaryGrindSize(statUuid: statUuid, grindSize: grindSize);
  }

  @override
  Future<void> updateDiaryWaterTemperature({
    required String statUuid,
    required double? waterTemp,
  }) async {
    temperatureCalls++;
    await super.updateDiaryWaterTemperature(
      statUuid: statUuid,
      waterTemp: waterTemp,
    );
  }

  @override
  Future<void> updateDiaryTasteBalance({
    required String statUuid,
    required int? tasteBalance,
  }) async {
    tasteCalls++;
    await super.updateDiaryTasteBalance(
      statUuid: statUuid,
      tasteBalance: tasteBalance,
    );
  }

  @override
  Future<void> updateDiaryNotes({
    required String statUuid,
    required String notes,
  }) async {
    notesCalls++;
    await super.updateDiaryNotes(statUuid: statUuid, notes: notes);
  }

  @override
  Future<void> updateDiaryTags({
    required String statUuid,
    required String? tags,
  }) async {
    tagsCalls++;
    await super.updateDiaryTags(statUuid: statUuid, tags: tags);
  }

  @override
  Future<void> updateDiaryRating({
    required String statUuid,
    required double? rating,
  }) async {
    ratingCalls++;
    if (failRating) throw StateError('forced rating failure');
    if (ratingGate != null) await ratingGate!.future;
    await super.updateDiaryRating(statUuid: statUuid, rating: rating);
  }

  @override
  Future<void> updateDiaryBean({
    required String statUuid,
    required String? nextBeanUuid,
  }) async {
    beanCalls++;
    if (beanGate != null) await beanGate!.future;
    if (failBean) throw StateError('forced bean failure');
    await super.updateDiaryBean(statUuid: statUuid, nextBeanUuid: nextBeanUuid);
  }
}
