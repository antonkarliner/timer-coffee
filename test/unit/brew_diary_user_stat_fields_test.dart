import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_database.dart';
import 'widgets/brew_flow_async_context_test.mocks.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  test('UserStatsModel new fields round-trip through Drift', () async {
    final db = openTestDatabase();
    final original = UserStatsModel(
      statUuid: 'brew-diary-fields',
      recipeId: 'recipe-1',
      coffeeAmount: 18,
      waterAmount: 300,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 2,
      brewingMethodId: 'method-1',
      createdAt: DateTime(2026, 7, 12),
      isMarked: false,
      waterTemp: 93.5,
      tasteBalance: -1,
      entrySource: 1,
      versionVector: VersionVector.initial('device-1').toString(),
      isDeleted: false,
    );

    await db.userStatsDao.insertUserStat(original);
    final restored = await db.userStatsDao.fetchStatByUuid(original.statUuid);

    expect(restored, isNotNull);
    expect(restored!.waterTemp, 93.5);
    expect(restored.tasteBalance, -1);
    expect(restored.entrySource, 1);
    await db.close();
  });

  test('UserStatProvider persists manual entry source and temperature', () async {
    final db = openTestDatabase();
    final provider = UserStatProvider(db, MockCoffeeBeansProvider());

    await provider.insertUserStat(
      statUuid: 'manual-provider-fields',
      recipeId: 'recipe-1',
      coffeeAmount: 18,
      waterAmount: 300,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 1,
      brewingMethodId: 'method-1',
      waterTemp: 92.5,
      entrySource: 1,
    );
    final restored = await db.userStatsDao.fetchStatByUuid(
      'manual-provider-fields',
    );

    expect(restored, isNotNull);
    expect(restored!.waterTemp, 92.5);
    expect(restored.entrySource, 1);
    provider.dispose();
    await db.close();
  });

  test('tags round-trip through Drift and DiaryEntry.tagList parses them', () async {
    final db = openTestDatabase();
    await db
        .into(db.brewingMethods)
        .insert(
          BrewingMethodsCompanion.insert(
            brewingMethodId: 'method-1',
            brewingMethod: 'V60',
          ),
        );

    final original = UserStatsModel(
      statUuid: 'brew-diary-tags',
      recipeId: 'recipe-1',
      coffeeAmount: 18,
      waterAmount: 300,
      sweetnessSliderPosition: 1,
      strengthSliderPosition: 2,
      brewingMethodId: 'method-1',
      createdAt: DateTime(2026, 7, 16),
      isMarked: false,
      tags: 'fruity, new kettle',
      versionVector: VersionVector.initial('device-1').toString(),
      isDeleted: false,
    );

    await db.userStatsDao.insertUserStat(original);
    final restored = await db.userStatsDao.fetchStatByUuid(original.statUuid);

    expect(restored, isNotNull);
    expect(restored!.tags, 'fruity, new kettle');

    final diaryEntries = await db.userStatsDao.fetchDiaryEntries('en');
    final diaryEntry = diaryEntries.single;

    expect(diaryEntry.tags, 'fruity, new kettle');
    expect(diaryEntry.tagList, ['fruity', 'new kettle']);

    await db.close();
  });
}
