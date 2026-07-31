import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/bean_review_prompt_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/finish/brew_eval_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_database.dart';

CoffeeBeansModel _makeBean({
  String uuid = 'bean-1',
  String name = 'Ethiopia Yirgacheffe',
  String roaster = 'Blue Bottle',
}) {
  return CoffeeBeansModel(
    beansUuid: uuid,
    roaster: roaster,
    name: name,
    origin: 'Ethiopia',
    isDeleted: false,
    versionVector: VersionVector.initial('test').toString(),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  const statUuid = 'eval-stat-1';

  Future<AppDatabase> seedDatabase() async {
    final db = openTestDatabase();
    await db.userStatsDao.insertUserStat(
      UserStatsModel(
        statUuid: statUuid,
        recipeId: 'recipe-1',
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 1,
        brewingMethodId: 'v60',
        createdAt: DateTime.utc(2026, 7, 30),
        rating: 3.5,
        isMarked: false,
        entrySource: 0,
        versionVector: VersionVector.initial('eval-device').toString(),
        isDeleted: false,
      ),
    );
    return db;
  }

  Future<UserStatsModel> readStat(AppDatabase db) async =>
      (await db.userStatsDao.fetchStatByUuid(statUuid))!;

  Future<void> pumpSheet(
    WidgetTester tester, {
    required AppDatabase db,
    required UserStatProvider userStatProvider,
    double? initialRating = 3.5,
    int? initialTasteBalance,
    String? initialNotes,
    List<String> initialTags = const [],
    List<Map<String, Object?>>? trackedEvents,
    ValueChanged<double>? onRatingChanged,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatProvider>.value(
            value: userStatProvider,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BrewEvalSheet(
              statUuid: statUuid,
              entrySource: 'timer',
              initialRating: initialRating,
              initialTasteBalance: initialTasteBalance,
              initialNotes: initialNotes,
              initialTags: initialTags,
              onRatingChanged: onRatingChanged,
              tagSuggestionsFuture: Future.value(const ['kettle']),
              trackEvent: trackedEvents == null
                  ? null
                  : (event, properties) => trackedEvents.add({
                      'event': event,
                      ...properties,
                    }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  UserStatProvider buildProvider(AppDatabase db) =>
      UserStatProvider(db, CoffeeBeansProvider(db, DatabaseProvider(db)));

  tearDown(() {});

  testWidgets('renders pre-seeded rating', (tester) async {
    final db = await seedDatabase();
    final stats = buildProvider(db);
    addTearDown(() async {
      stats.dispose();
      await db.close();
    });

    await pumpSheet(tester, db: db, userStatProvider: stats);

    final ratingBar = tester.widget<RatingBar>(
      find.descendant(
        of: find.byKey(const Key('evalSheetRatingBar')),
        matching: find.byType(RatingBar),
      ),
    );
    expect(ratingBar.initialRating, 3.5);
  });

  testWidgets(
    'in-sheet rating edits are reported back via onRatingChanged so the '
    'finish screen star row does not strand the originally tapped value',
    (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });

      final reported = <double>[];
      await pumpSheet(
        tester,
        db: db,
        userStatProvider: stats,
        initialRating: 3.5,
        onRatingChanged: reported.add,
      );

      final bar = find.descendant(
        of: find.byKey(const Key('evalSheetRatingBar')),
        matching: find.byType(RatingBar),
      );
      // Tap the 5th star: a rating edit made inside the sheet, not on the
      // finish screen's own row.
      await tester.tapAt(tester.getCenter(bar).translate(
            tester.getSize(bar).width / 2 - 8,
            0,
          ));
      await tester.pumpAndSettle();

      expect(
        reported,
        isNotEmpty,
        reason: 'the sheet must push in-sheet rating edits back to its opener',
      );
      expect(reported.last, isNot(3.5));
    },
  );

  testWidgets(
    'rating change calls updateDiaryRating and emits diary_entry_edited '
    'with source finish_eval_sheet',
    (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });
      final tracked = <Map<String, Object?>>[];

      await pumpSheet(
        tester,
        db: db,
        userStatProvider: stats,
        trackedEvents: tracked,
      );

      final ratingBar = tester.widget<RatingBar>(
        find.descendant(
          of: find.byKey(const Key('evalSheetRatingBar')),
          matching: find.byType(RatingBar),
        ),
      );
      ratingBar.onRatingUpdate(5);
      await tester.pumpAndSettle();

      expect((await readStat(db)).rating, 5);
      expect(tracked, [
        {
          'event': 'diary_entry_edited',
          'field': 'rating',
          'entry_source': 'timer',
          'source': 'finish_eval_sheet',
        },
      ]);
    },
  );

  testWidgets(
    'taste change calls updateDiaryTasteBalance and emits the taste event',
    (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });
      final tracked = <Map<String, Object?>>[];

      await pumpSheet(
        tester,
        db: db,
        userStatProvider: stats,
        trackedEvents: tracked,
      );

      await tester.tap(find.text('Sour'));
      await tester.pumpAndSettle();

      expect((await readStat(db)).tasteBalance, -1);
      expect(
        tracked.where((e) => e['field'] == 'taste').single,
        {
          'event': 'diary_entry_edited',
          'field': 'taste',
          'entry_source': 'timer',
          'source': 'finish_eval_sheet',
        },
      );
    },
  );

  testWidgets(
    'notes change debounces then calls updateDiaryNotes and emits the '
    'notes event',
    (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });
      final tracked = <Map<String, Object?>>[];

      await pumpSheet(
        tester,
        db: db,
        userStatProvider: stats,
        trackedEvents: tracked,
      );

      await tester.enterText(
        find.byKey(const Key('evalSheetNotesInput')),
        'Bright and juicy',
      );
      // Before the debounce fires, nothing should be written yet.
      await tester.pump(const Duration(milliseconds: 200));
      expect(tracked.where((e) => e['field'] == 'notes'), isEmpty);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect((await readStat(db)).notes, 'Bright and juicy');
      expect(
        tracked.where((e) => e['field'] == 'notes').single,
        {
          'event': 'diary_entry_edited',
          'field': 'notes',
          'entry_source': 'timer',
          'source': 'finish_eval_sheet',
        },
      );
    },
  );

  testWidgets(
    'tag change calls updateDiaryTags and emits the tags event',
    (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });
      final tracked = <Map<String, Object?>>[];

      await pumpSheet(
        tester,
        db: db,
        userStatProvider: stats,
        trackedEvents: tracked,
      );

      final quickPick = find.widgetWithText(ActionChip, 'kettle');
      expect(quickPick, findsOneWidget);
      await tester.tap(quickPick);
      await tester.pumpAndSettle();

      expect((await readStat(db)).tags, 'kettle');
      expect(
        tracked.where((e) => e['field'] == 'tags').single,
        {
          'event': 'diary_entry_edited',
          'field': 'tags',
          'entry_source': 'timer',
          'source': 'finish_eval_sheet',
        },
      );
    },
  );

  testWidgets(
    'dismissing the sheet does not lose the already-saved rating',
    (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });
      final tracked = <Map<String, Object?>>[];

      // Presented as a real modal route (not embedded directly in the test
      // Scaffold) so the close button's `Navigator.pop()` has an actual
      // route to dismiss, matching real usage via `showBrewEvalSheet`.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserStatProvider>.value(value: stats),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => BrewEvalSheet(
                        statUuid: statUuid,
                        entrySource: 'timer',
                        initialRating: 3.5,
                        tagSuggestionsFuture: Future.value(const []),
                        trackEvent: (event, properties) => tracked.add({
                          'event': event,
                          ...properties,
                        }),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final ratingBar = tester.widget<RatingBar>(
        find.descendant(
          of: find.byKey(const Key('evalSheetRatingBar')),
          matching: find.byType(RatingBar),
        ),
      );
      ratingBar.onRatingUpdate(2);
      await tester.pumpAndSettle();
      expect((await readStat(db)).rating, 2);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(BrewEvalSheet), findsNothing);
      expect((await readStat(db)).rating, 2);
    },
  );

  // ---------------------------------------------------------------------
  // "Rate the beans" step (plan 039, Phase B2 — bean review shares the
  // per-visit impression guard with `BeanReviewNudgeCard`, the finish-slot
  // card).
  // ---------------------------------------------------------------------

  group('bean-review step (Phase B2 shared guard)', () {
    testWidgets('no injected decision → no bean-review step', (tester) async {
      final db = await seedDatabase();
      final stats = buildProvider(db);
      addTearDown(() async {
        stats.dispose();
        await db.close();
      });

      await pumpSheet(tester, db: db, userStatProvider: stats);

      expect(find.text('Rate the beans'), findsNothing);
    });

    testWidgets(
      'eligible decision + guard not yet tripped → step renders and '
      'records exactly one impression through the shared guard',
      (tester) async {
        final db = await seedDatabase();
        final stats = buildProvider(db);
        addTearDown(() async {
          stats.dispose();
          await db.close();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final promptService = BeanReviewPromptService(prefs: prefs);
        final bean = _makeBean(uuid: 'bean-shared-eligible');
        final decision = BeanReviewPromptDecision(
          show: true,
          trigger: 'brew_count',
          bean: bean,
        );

        var sharedRecorded = false;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserStatProvider>.value(value: stats),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: BrewEvalSheet(
                  statUuid: statUuid,
                  entrySource: 'timer',
                  initialRating: 3.5,
                  tagSuggestionsFuture: Future.value(const []),
                  reviewDecision: decision,
                  reviewPromptService: promptService,
                  hasBeanReviewImpressionRecorded: () => sharedRecorded,
                  onBeanReviewImpressionRecorded: () =>
                      sharedRecorded = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rate the beans'), findsOneWidget);
        expect(find.text('How was ${bean.name}?'), findsOneWidget);
        expect(sharedRecorded, isTrue);
        expect(prefs.getInt('review_card_imp_bean-shared-eligible'), 1);
      },
    );

    testWidgets(
      'MANDATORY (plan 039 D9): depletion trigger already recorded by the '
      'slot card this visit → the sheet must NOT show "Rate the beans", '
      'even though depletion bypasses the global cooldown and the '
      'per-bean cap still has room (impression 1 of 3)',
      (tester) async {
        final db = await seedDatabase();
        final stats = buildProvider(db);
        addTearDown(() async {
          stats.dispose();
          await db.close();
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final promptService = BeanReviewPromptService(prefs: prefs);
        final bean = _makeBean(uuid: 'bean-depletion-shared');
        final decision = BeanReviewPromptDecision(
          show: true,
          trigger: 'depletion',
          bean: bean,
        );

        // Simulates `BeanReviewNudgeCard` having already rendered and
        // recorded the impression earlier in the same finish-screen visit
        // (as it would for a depletion trigger, which is eligible on
        // impression 1 of the per-bean cap of 3 and bypasses the 3-day
        // global cooldown entirely).
        await promptService.recordImpression(bean.beansUuid);
        var sharedRecorded = true;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserStatProvider>.value(value: stats),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: BrewEvalSheet(
                  statUuid: statUuid,
                  entrySource: 'timer',
                  initialRating: 3.5,
                  tagSuggestionsFuture: Future.value(const []),
                  reviewDecision: decision,
                  reviewPromptService: promptService,
                  hasBeanReviewImpressionRecorded: () => sharedRecorded,
                  onBeanReviewImpressionRecorded: () =>
                      sharedRecorded = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rate the beans'), findsNothing);
        expect(find.text('How was ${bean.name}?'), findsNothing);
        // The per-bean cap still has room (1 of 3) — this asserts the
        // suppression came from the shared guard, not from the service's
        // own (untouched) cap running out.
        expect(prefs.getInt('review_card_imp_bean-depletion-shared'), 1);
      },
    );
  });
}
