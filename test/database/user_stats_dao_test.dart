import 'dart:io';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../helpers/test_database.dart';
import '../unit/widgets/brew_flow_async_context_test.mocks.dart';

UserStatsModel _makeStat({
  String uuid = 'stat-uuid-1',
  String recipeId = 'recipe-1',
  String brewingMethodId = 'method-1',
  double coffeeAmount = 20.0,
  double waterAmount = 320.0,
  bool isDeleted = false,
  String? roaster,
  String? beans,
  String? coffeeBeansUuid,
  String? grindSize,
  double? waterTemp,
  double? tdsPercent,
  double? extractionYieldPercent,
  int? tasteBalance,
  int? entrySource,
  String? tags,
  double? rating,
  bool isMarked = false,
  String? notes,
  DateTime? createdAt,
}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: recipeId,
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: brewingMethodId,
    createdAt: createdAt ?? DateTime(2024, 1, 15),
    isMarked: isMarked,
    versionVector: VersionVector.initial('device-1').toString(),
    isDeleted: isDeleted,
    roaster: roaster,
    beans: beans,
    coffeeBeansUuid: coffeeBeansUuid,
    grindSize: grindSize,
    waterTemp: waterTemp,
    tdsPercent: tdsPercent,
    extractionYieldPercent: extractionYieldPercent,
    tasteBalance: tasteBalance,
    entrySource: entrySource,
    tags: tags,
    rating: rating,
    notes: notes,
  );
}

Future<void> _seedDiaryCatalog(AppDatabase db) async {
  await db
      .into(db.brewingMethods)
      .insert(
        BrewingMethodsCompanion.insert(
          brewingMethodId: 'method-1',
          brewingMethod: 'V60',
        ),
      );
  await db
      .into(db.recipes)
      .insert(
        RecipesCompanion.insert(
          id: 'recipe-1',
          brewingMethodId: 'method-1',
          coffeeAmount: 15,
          waterAmount: 250,
          waterTemp: 93,
          brewTime: 180,
        ),
      );
  await db
      .into(db.recipeLocalizations)
      .insert(
        RecipeLocalizationsCompanion.insert(
          id: 'recipe-1-en',
          recipeId: 'recipe-1',
          locale: 'en',
          name: 'English recipe',
          grindSize: 'Medium-fine',
          shortDescription: 'English description',
        ),
      );
}

DiaryEntry _makeDiaryEntry({String recipeName = 'Screen recipe'}) {
  return DiaryEntry(
    statUuid: 'stat-screen',
    recipeId: 'recipe-1',
    recipeName: recipeName,
    brewingMethodId: 'method-1',
    methodName: 'V60',
    createdAt: DateTime.now().toUtc(),
    coffeeAmount: 15,
    waterAmount: 250,
    waterTemp: 93,
    entrySource: 1,
    isMarked: false,
  );
}

Widget _diaryApp(UserStatProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatProvider>.value(value: provider),
      ChangeNotifierProvider<DateTimeFormatService>(
        create: (_) => DateTimeFormatService(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const BrewDiaryScreen(),
    ),
  );
}

void _useDiarySurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('insertUserStat / fetchStatByUuid', () {
    test('inserts and retrieves by UUID', () async {
      await db.userStatsDao.insertUserStat(_makeStat());

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');

      expect(result, isNotNull);
      expect(result!.statUuid, 'stat-uuid-1');
      expect(result.coffeeAmount, 20.0);
      expect(result.waterAmount, 320.0);
    });

    test('returns null for missing UUID', () async {
      final result = await db.userStatsDao.fetchStatByUuid('nonexistent');
      expect(result, isNull);
    });

    test('returns null for soft-deleted record', () async {
      await db.userStatsDao.insertUserStat(_makeStat(isDeleted: true));

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(result, isNull);
    });
  });

  group('fetchAllStats', () {
    test('returns only non-deleted records', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'a'));
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'b', isDeleted: true),
      );
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'c'));

      final results = await db.userStatsDao.fetchAllStats();

      expect(results.length, 2);
      expect(results.map((s) => s.statUuid), containsAll(['a', 'c']));
      expect(results.map((s) => s.statUuid), isNot(contains('b')));
    });

    test('returns records ordered by createdAt descending', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'older', createdAt: DateTime(2024, 1, 1)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'newer', createdAt: DateTime(2024, 6, 1)),
      );

      final results = await db.userStatsDao.fetchAllStats();

      expect(results.first.statUuid, 'newer');
      expect(results.last.statUuid, 'older');
    });

    test('returns empty list when no stats exist', () async {
      final results = await db.userStatsDao.fetchAllStats();
      expect(results, isEmpty);
    });
  });

  group('latestGrindSuggestionForBeanAndMethod', () {
    Future<GrindSuggestionResult?> fetch() => db.userStatsDao
        .latestGrindSuggestionForBeanAndMethod('bean-1', 'method-1');

    test('returns null when no matching stat exists', () async {
      expect(await fetch(), isNull);
    });

    test('excludes deleted rows', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(coffeeBeansUuid: 'bean-1', grindSize: '24', isDeleted: true),
      );

      expect(await fetch(), isNull);
    });

    test('excludes empty grind strings', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(coffeeBeansUuid: 'bean-1', grindSize: ''),
      );

      expect(await fetch(), isNull);
    });

    test('returns the newest matching grind and its taste balance', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'older',
          coffeeBeansUuid: 'bean-1',
          grindSize: '22',
          tasteBalance: 1,
          createdAt: DateTime(2024, 1, 1),
        ),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'newer',
          coffeeBeansUuid: 'bean-1',
          grindSize: '24',
          tasteBalance: -1,
          createdAt: DateTime(2024, 2, 1),
        ),
      );

      final result = await fetch();

      expect(result?.grindSize, '24');
      expect(result?.tasteBalance, -1);
    });
  });

  group('fetchDiaryEntries', () {
    setUp(() async {
      await _seedDiaryCatalog(db);
    });

    test('returns newest entries first with all joined card fields', () async {
      await db
          .into(db.coffeeBeans)
          .insert(
            CoffeeBeansCompanion.insert(
              beansUuid: 'bean-1',
              roaster: 'Test Roaster',
              name: 'Kayon Mountain',
              origin: 'Ethiopia',
              versionVector: VersionVector.initial('device-1').toString(),
            ),
          );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'older', createdAt: DateTime(2024, 1, 1)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'newer',
          coffeeAmount: 15,
          waterAmount: 250,
          coffeeBeansUuid: 'bean-1',
          grindSize: '24 clicks',
          waterTemp: 93,
          tdsPercent: 1.35,
          extractionYieldPercent: 20.4,
          tasteBalance: 0,
          entrySource: 1,
          rating: 4.5,
          isMarked: true,
          notes: 'Sweet and clear',
          createdAt: DateTime(2024, 6, 1),
        ),
      );

      final results = await db.userStatsDao.fetchDiaryEntries('en');

      expect(results.map((entry) => entry.statUuid), ['newer', 'older']);
      final entry = results.first;
      expect(entry.recipeName, 'English recipe');
      expect(entry.methodName, 'V60');
      expect(entry.ratio, '1:16.7');
      expect(entry.beanName, 'Kayon Mountain');
      expect(entry.roaster, 'Test Roaster');
      expect(entry.grindSize, '24 clicks');
      expect(entry.waterTemp, 93);
      expect(entry.tdsPercent, 1.35);
      expect(entry.extractionYieldPercent, 20.4);
      expect(entry.tasteBalance, 0);
      expect(entry.entrySource, 1);
      expect(entry.rating, 4.5);
      expect(entry.isMarked, isTrue);
      expect(entry.notes, 'Sweet and clear');
    });

    test(
      'falls back to English when requested localization is missing',
      () async {
        await db.userStatsDao.insertUserStat(_makeStat());

        final results = await db.userStatsDao.fetchDiaryEntries('fr');

        expect(results.single.recipeName, 'English recipe');
      },
    );

    test(
      'returns an empty recipe name when requested and English localizations are missing',
      () async {
        await db.delete(db.recipeLocalizations).go();
        await db.userStatsDao.insertUserStat(_makeStat());

        final results = await db.userStatsDao.fetchDiaryEntries('fr');
        final source = File(
          'lib/database/user_stats_dao.dart',
        ).readAsStringSync();

        expect(results.single.recipeName, isEmpty);
        expect(source, contains("COALESCE(localized.name, english.name, '')"));
        expect(source, isNot(contains('Unknown Recipe')));
      },
    );

    test('keeps bean-less rows with null bean fields', () async {
      await db.userStatsDao.insertUserStat(_makeStat(coffeeAmount: 0));

      final results = await db.userStatsDao.fetchDiaryEntries('en');

      expect(results.single.coffeeBeansUuid, isNull);
      expect(results.single.beanName, isNull);
      expect(results.single.roaster, isNull);
      expect(results.single.ratio, isNull);
    });

    test('excludes soft-deleted rows', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'active'));
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'deleted', isDeleted: true),
      );

      final results = await db.userStatsDao.fetchDiaryEntries('en');

      expect(results.map((entry) => entry.statUuid), ['active']);
    });

    test(
      'derives water temp from the recipe when the entry has none stored',
      () async {
        await db.userStatsDao.insertUserStat(
          _makeStat(uuid: 'no-temp', waterTemp: null),
        );

        final results = await db.userStatsDao.fetchDiaryEntries('en');

        expect(results.single.waterTemp, 93);
        expect(results.single.waterTempIsDerived, isTrue);
      },
    );

    test(
      'reports a stored water temp as not derived, even if it matches the recipe default',
      () async {
        await db.userStatsDao.insertUserStat(
          _makeStat(uuid: 'has-temp', waterTemp: 85),
        );

        final results = await db.userStatsDao.fetchDiaryEntries('en');

        expect(results.single.waterTemp, 85);
        expect(results.single.waterTempIsDerived, isFalse);
      },
    );
  });

  group('BrewDiaryScreen localization and load errors', () {
    testWidgets('localizes an empty DAO recipe name before rendering', (
      tester,
    ) async {
      _useDiarySurface(tester);
      final provider = MockUserStatProvider();
      when(
        provider.fetchDiaryEntries('en'),
      ).thenAnswer((_) async => [_makeDiaryEntry(recipeName: '')]);
      when(
        provider.topMethodsLast90Days('en'),
      ).thenAnswer((_) async => const []);

      await tester.pumpWidget(_diaryApp(provider));
      await tester.pumpAndSettle();
      final loc = AppLocalizations.of(
        tester.element(find.byType(BrewDiaryScreen)),
      )!;

      expect(find.text(loc.unknownRecipe), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('userStatCard_stat-screen'),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows generic localized failure copy and retry starts a successful future',
      (tester) async {
        _useDiarySurface(tester);
        final provider = MockUserStatProvider();
        var fetchCalls = 0;
        when(provider.fetchDiaryEntries('en')).thenAnswer((_) async {
          fetchCalls++;
          if (fetchCalls == 1) {
            throw StateError('raw-private-diary-error');
          }
          return [_makeDiaryEntry()];
        });
        when(
          provider.topMethodsLast90Days('en'),
        ).thenAnswer((_) async => const []);

        await tester.pumpWidget(_diaryApp(provider));
        await tester.pumpAndSettle();
        final loc = AppLocalizations.of(
          tester.element(find.byType(BrewDiaryScreen)),
        )!;

        expect(
          find.bySemanticsIdentifier('brewDiaryLoadError'),
          findsOneWidget,
        );
        expect(find.text(loc.diaryLoadError), findsOneWidget);
        expect(find.text(loc.retry), findsOneWidget);
        expect(find.textContaining('raw-private-diary-error'), findsNothing);
        expect(fetchCalls, 1);

        await tester.tap(find.text(loc.retry));
        await tester.pumpAndSettle();

        expect(fetchCalls, 2);
        expect(find.bySemanticsIdentifier('brewDiaryLoadError'), findsNothing);
        expect(
          find.bySemanticsIdentifier('userStatCard_stat-screen'),
          findsOneWidget,
        );
      },
    );
  });

  group('updateUserStat', () {
    test('updates record fields', () async {
      final original = _makeStat(coffeeAmount: 20.0);
      await db.userStatsDao.insertUserStat(original);

      final updated = original.copyWith(coffeeAmount: 25.0, rating: 4.5);
      await db.userStatsDao.updateUserStat(updated);

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(result!.coffeeAmount, 25.0);
      expect(result.rating, 4.5);
    });

    test('soft-delete via updateUserStat hides from fetchStatByUuid', () async {
      await db.userStatsDao.insertUserStat(_makeStat());

      final deleted = _makeStat(isDeleted: true);
      await db.userStatsDao.updateUserStat(deleted);

      final result = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(result, isNull);
    });
  });

  group('deleteUserStat (hard delete)', () {
    test('removes record permanently', () async {
      await db.userStatsDao.insertUserStat(_makeStat());

      await db.userStatsDao.deleteUserStat('stat-uuid-1');

      final all = await db.userStatsDao.fetchAllStatsWithVersionVectors();
      expect(all, isEmpty);
    });

    test('silently succeeds when UUID does not exist', () async {
      await db.userStatsDao.deleteUserStat('nonexistent');
      // Passes if no exception is thrown
    });
  });

  group('insertUserStat - upsert on conflict', () {
    test('overwrites existing record when UUID matches', () async {
      await db.userStatsDao.insertUserStat(_makeStat(coffeeAmount: 20.0));

      await db.userStatsDao.insertUserStat(_makeStat(coffeeAmount: 30.0));

      final all = await db.userStatsDao.fetchAllStats();
      expect(all.length, 1);
      expect(all.first.coffeeAmount, 30.0);
    });
  });

  group('fetchBrewedCoffeeAmount', () {
    test('sums water amounts within date range', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: '1',
          waterAmount: 300.0,
          createdAt: DateTime(2024, 3, 15),
        ),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: '2',
          waterAmount: 400.0,
          createdAt: DateTime(2024, 3, 20),
        ),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: '3',
          waterAmount: 500.0,
          createdAt: DateTime(2024, 5, 1),
        ),
      );

      final total = await db.userStatsDao.fetchBrewedCoffeeAmount(
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 31),
      );

      expect(total, closeTo(700.0, 0.001));
    });

    test('excludes soft-deleted records', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: '1',
          waterAmount: 300.0,
          createdAt: DateTime(2024, 3, 15),
        ),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: '2',
          waterAmount: 400.0,
          isDeleted: true,
          createdAt: DateTime(2024, 3, 16),
        ),
      );

      final total = await db.userStatsDao.fetchBrewedCoffeeAmount(
        DateTime(2024, 3, 1),
        DateTime(2024, 3, 31),
      );

      expect(total, closeTo(300.0, 0.001));
    });

    test('returns 0.0 when no stats exist in range', () async {
      final total = await db.userStatsDao.fetchBrewedCoffeeAmount(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(total, 0.0);
    });
  });

  group('insertOrUpdateMultipleStats', () {
    test('batch inserts multiple stats', () async {
      final stats = [
        _makeStat(uuid: 'a'),
        _makeStat(uuid: 'b'),
        _makeStat(uuid: 'c'),
      ];

      await db.userStatsDao.insertOrUpdateMultipleStats(stats);

      final all = await db.userStatsDao.fetchAllStats();
      expect(all.length, 3);
    });

    test('empty list completes without error', () async {
      await db.userStatsDao.insertOrUpdateMultipleStats([]);
      // Passes if no exception is thrown
    });

    test('upserts existing records', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: 'x', coffeeAmount: 20.0),
      );

      await db.userStatsDao.insertOrUpdateMultipleStats([
        _makeStat(uuid: 'x', coffeeAmount: 35.0),
      ]);

      final all = await db.userStatsDao.fetchAllStats();
      expect(all.length, 1);
      expect(all.first.coffeeAmount, 35.0);
    });
  });

  group('fetchAllDistinctRoasters', () {
    test('returns distinct roaster names', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', roaster: 'Roaster A'),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', roaster: 'Roaster B'),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '3', roaster: 'Roaster A'),
      );

      final roasters = await db.userStatsDao.fetchAllDistinctRoasters();

      expect(roasters.toSet().length, 2);
      expect(roasters, containsAll(['Roaster A', 'Roaster B']));
    });

    test('excludes null roasters', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '1', roaster: null));

      final roasters = await db.userStatsDao.fetchAllDistinctRoasters();
      expect(roasters, isEmpty);
    });

    test('excludes deleted records', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', roaster: 'Active'),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', roaster: 'Deleted', isDeleted: true),
      );

      final roasters = await db.userStatsDao.fetchAllDistinctRoasters();

      expect(roasters, contains('Active'));
      expect(roasters, isNot(contains('Deleted')));
    });
  });

  group('fetchAllDistinctTags', () {
    test('dedupes overlapping tags across stats, preserving first-seen order', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', tags: 'fruity, new kettle'),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', tags: 'new kettle, home'),
      );

      final tags = await db.userStatsDao.fetchAllDistinctTags();

      expect(tags, ['fruity', 'new kettle', 'home']);
    });

    test('excludes tags from deleted stats', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', tags: 'fruity'),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', tags: 'deleted-tag', isDeleted: true),
      );

      final tags = await db.userStatsDao.fetchAllDistinctTags();

      expect(tags, ['fruity']);
    });

    test('returns empty list when no stats have tags', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: '1'));

      final tags = await db.userStatsDao.fetchAllDistinctTags();

      expect(tags, isEmpty);
    });

    test('orders tags by recency, newest stat first', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', tags: 'alpha', createdAt: DateTime(2024, 1, 1)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', tags: 'beta', createdAt: DateTime(2024, 6, 1)),
      );

      final tags = await db.userStatsDao.fetchAllDistinctTags();

      expect(tags, ['beta', 'alpha']);
    });

    test('dedupes case-insensitively, keeping the most recent casing', () async {
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '1', tags: 'Fruity', createdAt: DateTime(2024, 1, 1)),
      );
      await db.userStatsDao.insertUserStat(
        _makeStat(uuid: '2', tags: 'fruity', createdAt: DateTime(2024, 6, 1)),
      );

      final tags = await db.userStatsDao.fetchAllDistinctTags();

      expect(tags, ['fruity']);
    });
  });

  group('fetchStatsByUuids', () {
    test('returns stats for given UUIDs', () async {
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'a'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'b'));
      await db.userStatsDao.insertUserStat(_makeStat(uuid: 'c'));

      final results = await db.userStatsDao.fetchStatsByUuids(['a', 'c']);

      expect(results.length, 2);
      expect(results.map((s) => s.statUuid), containsAll(['a', 'c']));
    });

    test('empty UUID list returns empty result', () async {
      final results = await db.userStatsDao.fetchStatsByUuids([]);
      expect(results, isEmpty);
    });
  });
}
