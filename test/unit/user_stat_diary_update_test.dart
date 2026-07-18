import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_database.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  test('15 g to 20 g then delete is inventory-neutral', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    expect(
      await harness.beans.updateBeanWeightAfterBrew(_Harness.beanUuid, 15),
      85,
    );
    await harness.updateAmounts(coffeeAmount: 20);
    expect(await harness.weight(), 80);
    expect((await harness.stat())!.coffeeAmount, 20);

    final savedDose = (await harness.stat())!.coffeeAmount;
    await harness.beans.updateBeanWeightAfterBrewModification(
      _Harness.beanUuid,
      savedDose,
    );
    await harness.stats.deleteUserStat(_Harness.statUuid);

    expect(await harness.weight(), 100);
  });

  test('15 g to 10 g then delete is inventory-neutral', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);

    await harness.beans.updateBeanWeightAfterBrew(_Harness.beanUuid, 15);
    await harness.updateAmounts(coffeeAmount: 10);
    expect(await harness.weight(), 90);
    expect((await harness.stat())!.coffeeAmount, 10);

    final savedDose = (await harness.stat())!.coffeeAmount;
    await harness.beans.updateBeanWeightAfterBrewModification(
      _Harness.beanUuid,
      savedDose,
    );
    await harness.stats.deleteUserStat(_Harness.statUuid);

    expect(await harness.weight(), 100);
  });

  test('same dose skips bean write and notifies stat listeners once', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    final beforeBean = await harness.bean();
    final beforeStat = await harness.stat();
    var notifications = 0;
    harness.stats.addListener(() => notifications++);

    await harness.updateAmounts(coffeeAmount: 15);

    final afterBean = await harness.bean();
    final afterStat = await harness.stat();
    expect(afterBean!.versionVector, beforeBean!.versionVector);
    expect(
      VersionVector.fromString(afterStat!.versionVector).version,
      VersionVector.fromString(beforeStat!.versionVector).version + 1,
    );
    expect(notifications, 1);
  });

  for (final entrySource in <int?>[0, null]) {
    test('entry source $entrySource cannot mutate dose or inventory', () async {
      final harness = await _Harness.create(entrySource: entrySource);
      addTearDown(harness.close);

      await harness.updateAmounts(coffeeAmount: 30, waterAmount: 500);

      final stat = await harness.stat();
      expect(stat!.coffeeAmount, 15);
      expect(stat.waterAmount, 250);
      expect(await harness.weight(), 100);
    });
  }

  test('null package weight permits the stat edit and stays null', () async {
    final harness = await _Harness.create(packageWeight: null);
    addTearDown(harness.close);

    await harness.updateAmounts(coffeeAmount: 20);

    expect((await harness.stat())!.coffeeAmount, 20);
    expect((await harness.bean())!.packageWeightGrams, isNull);
  });

  test('failed stat write compensates the earlier bean delta', () async {
    final harness = await _Harness.create();
    addTearDown(harness.close);
    await harness.beans.updateBeanWeightAfterBrew(_Harness.beanUuid, 15);
    await harness.db.customStatement('''
      CREATE TRIGGER fail_diary_stat_update
      BEFORE UPDATE ON user_stats
      BEGIN
        SELECT RAISE(FAIL, 'forced stat update failure');
      END;
    ''');

    await expectLater(
      harness.updateAmounts(coffeeAmount: 20),
      throwsA(anything),
    );

    expect(await harness.weight(), 85);
    expect((await harness.stat())!.coffeeAmount, 15);
  });

  test('water temperature can be cleared or replaced explicitly', () async {
    final harness = await _Harness.create(waterTemp: 93);
    addTearDown(harness.close);

    await harness.stats.updateDiaryWaterTemperature(
      statUuid: _Harness.statUuid,
      waterTemp: null,
    );
    var stat = await harness.stat();
    expect(stat!.waterTemp, isNull);
    expect(
      harness.stats.serializeUserStatForTesting(stat),
      containsPair('water_temp', null),
    );

    await harness.stats.updateDiaryWaterTemperature(
      statUuid: _Harness.statUuid,
      waterTemp: 94.5,
    );
    stat = await harness.stat();
    expect(stat!.waterTemp, 94.5);
    expect(harness.stats.serializeUserStatForTesting(stat)['water_temp'], 94.5);
  });

  test(
    'each focused mutation changes only its named field and notifies once',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);

      await harness.expectFocusedUpdate(
        changedFields: {'grindSize'},
        update: () => harness.stats.updateDiaryGrindSize(
          statUuid: _Harness.statUuid,
          grindSize: '30 clicks',
        ),
        verify: (stat) => expect(stat.grindSize, '30 clicks'),
      );
      await harness.expectFocusedUpdate(
        changedFields: {'waterTemp'},
        update: () => harness.stats.updateDiaryWaterTemperature(
          statUuid: _Harness.statUuid,
          waterTemp: null,
        ),
        verify: (stat) => expect(stat.waterTemp, isNull),
      );
      await harness.expectFocusedUpdate(
        changedFields: {'tasteBalance'},
        update: () => harness.stats.updateDiaryTasteBalance(
          statUuid: _Harness.statUuid,
          tasteBalance: null,
        ),
        verify: (stat) => expect(stat.tasteBalance, isNull),
      );
      await harness.expectFocusedUpdate(
        changedFields: {'notes'},
        update: () => harness.stats.updateDiaryNotes(
          statUuid: _Harness.statUuid,
          notes: 'Focused note',
        ),
        verify: (stat) => expect(stat.notes, 'Focused note'),
      );
      await harness.expectFocusedUpdate(
        changedFields: {'rating'},
        update: () => harness.stats.updateDiaryRating(
          statUuid: _Harness.statUuid,
          rating: null,
        ),
        verify: (stat) => expect(stat.rating, isNull),
      );
      await harness.expectFocusedUpdate(
        changedFields: {'rating'},
        update: () => harness.stats.updateDiaryRating(
          statUuid: _Harness.statUuid,
          rating: 4.5,
        ),
        verify: (stat) => expect(stat.rating, 4.5),
      );
    },
  );

  test(
    'focused amounts change only dose and water with one notification',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.close);

      await harness.expectFocusedUpdate(
        changedFields: {'coffeeAmount', 'waterAmount'},
        update: () => harness.updateAmounts(coffeeAmount: 18, waterAmount: 300),
        verify: (stat) {
          expect(stat.coffeeAmount, 18);
          expect(stat.waterAmount, 300);
        },
      );
      expect(await harness.weight(), 97);
    },
  );

  test('15 g detach restores tracked inventory and persists null', () async {
    final harness = await _Harness.create(packageWeight: 85);
    addTearDown(harness.close);

    await harness.stats.updateDiaryBean(
      statUuid: _Harness.statUuid,
      nextBeanUuid: null,
    );

    expect((await harness.stat())!.coffeeBeansUuid, isNull);
    expect(await harness.weight(), 100);
  });

  test(
    '15 g attach deducts tracked inventory for every entry source',
    () async {
      for (final entrySource in <int?>[0, 1, null]) {
        final harness = await _Harness.create(
          initialBeanUuid: null,
          entrySource: entrySource,
          includeBeanB: true,
        );
        addTearDown(harness.close);

        await harness.stats.updateDiaryBean(
          statUuid: _Harness.statUuid,
          nextBeanUuid: _Harness.beanBUuid,
        );

        expect((await harness.stat())!.coffeeBeansUuid, _Harness.beanBUuid);
        expect(await harness.weight(_Harness.beanBUuid), 85);
      }
    },
  );

  test('15 g A to B replacement returns A and deducts B', () async {
    final harness = await _Harness.create(
      packageWeight: 85,
      includeBeanB: true,
    );
    addTearDown(harness.close);

    await harness.stats.updateDiaryBean(
      statUuid: _Harness.statUuid,
      nextBeanUuid: _Harness.beanBUuid,
    );

    expect((await harness.stat())!.coffeeBeansUuid, _Harness.beanBUuid);
    expect(await harness.weight(), 100);
    expect(await harness.weight(_Harness.beanBUuid), 85);
  });

  test('same bean UUID is a complete no-op', () async {
    final harness = await _Harness.create(packageWeight: 85);
    addTearDown(harness.close);
    final before = (await harness.stat())!;
    final beforeBean = (await harness.bean())!;
    var notifications = 0;
    harness.stats.addListener(() => notifications++);

    await harness.stats.updateDiaryBean(
      statUuid: _Harness.statUuid,
      nextBeanUuid: _Harness.beanUuid,
    );

    final after = (await harness.stat())!;
    final afterBean = (await harness.bean())!;
    expect(after.versionVector, before.versionVector);
    expect(afterBean.versionVector, beforeBean.versionVector);
    expect(await harness.weight(), 85);
    expect(notifications, 0);
    expect(harness.beans.adjustments, isEmpty);
  });

  test('untracked detach and attach still persist the association', () async {
    final harness = await _Harness.create(
      packageWeight: null,
      includeBeanB: true,
      beanBWeight: null,
    );
    addTearDown(harness.close);

    await harness.stats.updateDiaryBean(
      statUuid: _Harness.statUuid,
      nextBeanUuid: _Harness.beanBUuid,
    );

    expect((await harness.stat())!.coffeeBeansUuid, _Harness.beanBUuid);
    expect((await harness.bean())!.packageWeightGrams, isNull);
    expect(
      (await harness.bean(_Harness.beanBUuid))!.packageWeightGrams,
      isNull,
    );
  });

  test('low-stock target clamps at zero and still attaches', () async {
    final harness = await _Harness.create(
      initialBeanUuid: null,
      includeBeanB: true,
      beanBWeight: 5,
    );
    addTearDown(harness.close);

    await harness.stats.updateDiaryBean(
      statUuid: _Harness.statUuid,
      nextBeanUuid: _Harness.beanBUuid,
    );

    expect((await harness.stat())!.coffeeBeansUuid, _Harness.beanBUuid);
    expect(await harness.weight(_Harness.beanBUuid), 0);
    expect(harness.beans.adjustments.single.$3, 5);
  });

  test(
    'missing or deleted target fails before inventory or stat mutation',
    () async {
      for (final target in <String>['missing-bean', _Harness.beanBUuid]) {
        final harness = await _Harness.create(
          packageWeight: 85,
          includeBeanB: target == _Harness.beanBUuid,
          beanBDeleted: true,
        );
        addTearDown(harness.close);
        final before = (await harness.stat())!;

        await expectLater(
          harness.stats.updateDiaryBean(
            statUuid: _Harness.statUuid,
            nextBeanUuid: target,
          ),
          throwsA(isA<StateError>()),
        );

        expect((await harness.stat())!.coffeeBeansUuid, before.coffeeBeansUuid);
        expect(await harness.weight(), 85);
        expect(harness.beans.adjustments, isEmpty);
      }
    },
  );

  test('second adjustment failure compensates A in exact reverse', () async {
    final harness = await _Harness.create(
      packageWeight: 85,
      includeBeanB: true,
      failAdjustmentCall: 2,
    );
    addTearDown(harness.close);

    await expectLater(
      harness.stats.updateDiaryBean(
        statUuid: _Harness.statUuid,
        nextBeanUuid: _Harness.beanBUuid,
      ),
      throwsA(isA<BeanWeightAdjustmentException>()),
    );

    expect((await harness.stat())!.coffeeBeansUuid, _Harness.beanUuid);
    expect(await harness.weight(), 85);
    expect(await harness.weight(_Harness.beanBUuid), 100);
    expect(
      harness.beans.adjustments.map((call) => (call.$1, call.$2)).toList(),
      [
        (_Harness.beanUuid, -15),
        (_Harness.beanBUuid, 15),
        (_Harness.beanUuid, 15),
      ],
    );
  });

  test('failed attach stat write restores B to persisted 100 g', () async {
    final harness = await _Harness.create(
      initialBeanUuid: null,
      includeBeanB: true,
    );
    addTearDown(harness.close);
    await harness.installFailingStatTrigger();

    await expectLater(
      harness.stats.updateDiaryBean(
        statUuid: _Harness.statUuid,
        nextBeanUuid: _Harness.beanBUuid,
      ),
      throwsA(anything),
    );

    expect((await harness.stat())!.coffeeBeansUuid, isNull);
    expect(await harness.weight(_Harness.beanBUuid), 100);
    expect(
      harness.beans.adjustments.map((call) => (call.$1, call.$2)).toList(),
      [(_Harness.beanBUuid, 15), (_Harness.beanBUuid, -15)],
    );
  });

  test('failed replacement compensates B then A with exact deltas', () async {
    final harness = await _Harness.create(
      packageWeight: 85,
      includeBeanB: true,
    );
    addTearDown(harness.close);
    await harness.installFailingStatTrigger();

    await expectLater(
      harness.stats.updateDiaryBean(
        statUuid: _Harness.statUuid,
        nextBeanUuid: _Harness.beanBUuid,
      ),
      throwsA(anything),
    );

    expect((await harness.stat())!.coffeeBeansUuid, _Harness.beanUuid);
    expect(await harness.weight(), 85);
    expect(await harness.weight(_Harness.beanBUuid), 100);
    expect(
      harness.beans.adjustments.map((call) => (call.$1, call.$2)).toList(),
      [
        (_Harness.beanUuid, -15),
        (_Harness.beanBUuid, 15),
        (_Harness.beanBUuid, -15),
        (_Harness.beanUuid, 15),
      ],
    );
  });

  test(
    'successful association increments one version and notifies once',
    () async {
      final harness = await _Harness.create(
        initialBeanUuid: null,
        includeBeanB: true,
      );
      addTearDown(harness.close);
      final before = (await harness.stat())!;
      var notifications = 0;
      harness.stats.addListener(() => notifications++);

      await harness.stats.updateDiaryBean(
        statUuid: _Harness.statUuid,
        nextBeanUuid: _Harness.beanBUuid,
      );

      final after = (await harness.stat())!;
      expect(
        VersionVector.fromString(after.versionVector).version,
        VersionVector.fromString(before.versionVector).version + 1,
      );
      expect(notifications, 1);
    },
  );
}

class _Harness {
  _Harness({required this.db, required this.beans, required this.stats});

  static const beanUuid = 'bean-1';
  static const beanBUuid = 'bean-2';
  static const statUuid = 'stat-1';

  final AppDatabase db;
  final _RecordingCoffeeBeansProvider beans;
  final UserStatProvider stats;

  static Future<_Harness> create({
    double? packageWeight = 100,
    int? entrySource = 1,
    double? waterTemp = 93,
    String? initialBeanUuid = beanUuid,
    bool includeBeanB = false,
    double? beanBWeight = 100,
    bool beanBDeleted = false,
    int? failAdjustmentCall,
  }) async {
    final db = openTestDatabase();
    await db.coffeeBeansDao.insertCoffeeBeans(
      CoffeeBeansModel(
        beansUuid: beanUuid,
        roaster: 'Test Roaster',
        name: 'Test Beans',
        origin: 'Test Origin',
        packageWeightGrams: packageWeight,
        versionVector: VersionVector.initial('bean-device').toString(),
      ),
    );
    if (includeBeanB) {
      await db.coffeeBeansDao.insertCoffeeBeans(
        CoffeeBeansModel(
          beansUuid: beanBUuid,
          roaster: 'Second Roaster',
          name: 'Second Beans',
          origin: 'Kenya',
          packageWeightGrams: beanBWeight,
          isDeleted: beanBDeleted,
          versionVector: VersionVector.initial('bean-b-device').toString(),
        ),
      );
    }
    await db.userStatsDao.insertUserStat(
      UserStatsModel(
        statUuid: statUuid,
        recipeId: 'recipe-1',
        coffeeAmount: 15,
        waterAmount: 250,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 1,
        brewingMethodId: 'method-1',
        createdAt: DateTime.utc(2026, 7, 14),
        notes: 'Initial note',
        rating: 4,
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
    final beans = _RecordingCoffeeBeansProvider(
      db,
      DatabaseProvider(db),
      failAdjustmentCall: failAdjustmentCall,
    );
    return _Harness(db: db, beans: beans, stats: UserStatProvider(db, beans));
  }

  Future<void> updateAmounts({
    double coffeeAmount = 15,
    double waterAmount = 250,
  }) => stats.updateDiaryAmounts(
    statUuid: statUuid,
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
  );

  Future<void> expectFocusedUpdate({
    required Set<String> changedFields,
    required Future<void> Function() update,
    required void Function(UserStatsModel stat) verify,
  }) async {
    final before = (await stat())!;
    final beforeSnapshot = _snapshot(before);
    var notifications = 0;
    void listener() => notifications++;
    stats.addListener(listener);
    await update();
    stats.removeListener(listener);

    final after = (await stat())!;
    verify(after);
    expect(notifications, 1);
    expect(
      VersionVector.fromString(after.versionVector).version,
      VersionVector.fromString(before.versionVector).version + 1,
    );
    final afterSnapshot = _snapshot(after);
    for (final field in changedFields) {
      beforeSnapshot.remove(field);
      afterSnapshot.remove(field);
    }
    beforeSnapshot.remove('versionVector');
    afterSnapshot.remove('versionVector');
    expect(afterSnapshot, beforeSnapshot);
  }

  static Map<String, Object?> _snapshot(UserStatsModel stat) => {
    'statUuid': stat.statUuid,
    'id': stat.id,
    'recipeId': stat.recipeId,
    'coffeeAmount': stat.coffeeAmount,
    'waterAmount': stat.waterAmount,
    'sweetnessSliderPosition': stat.sweetnessSliderPosition,
    'strengthSliderPosition': stat.strengthSliderPosition,
    'brewingMethodId': stat.brewingMethodId,
    'createdAt': stat.createdAt,
    'notes': stat.notes,
    'beans': stat.beans,
    'roaster': stat.roaster,
    'rating': stat.rating,
    'coffeeBeansId': stat.coffeeBeansId,
    'isMarked': stat.isMarked,
    'coffeeBeansUuid': stat.coffeeBeansUuid,
    'grindSize': stat.grindSize,
    'tdsPercent': stat.tdsPercent,
    'extractionYieldPercent': stat.extractionYieldPercent,
    'waterTemp': stat.waterTemp,
    'tasteBalance': stat.tasteBalance,
    'entrySource': stat.entrySource,
    'versionVector': stat.versionVector,
    'isDeleted': stat.isDeleted,
  };

  Future<UserStatsModel?> stat() => db.userStatsDao.fetchStatByUuid(statUuid);

  Future<CoffeeBeansModel?> bean([String uuid = beanUuid]) =>
      db.coffeeBeansDao.fetchCoffeeBeansByUuid(uuid);

  Future<double?> weight([String uuid = beanUuid]) async =>
      (await bean(uuid))?.packageWeightGrams;

  Future<void> installFailingStatTrigger() => db.customStatement('''
    CREATE TRIGGER fail_diary_bean_stat_update
    BEFORE UPDATE ON user_stats
    BEGIN
      SELECT RAISE(FAIL, 'forced stat update failure');
    END;
  ''');

  Future<void> close() async {
    stats.dispose();
    beans.dispose();
    await db.close();
  }
}

class _RecordingCoffeeBeansProvider extends CoffeeBeansProvider {
  _RecordingCoffeeBeansProvider(
    super.db,
    super.databaseProvider, {
    this.failAdjustmentCall,
  });

  final int? failAdjustmentCall;
  final List<(String, double, double)> adjustments = [];
  int _callCount = 0;

  @override
  Future<BeanWeightAdjustmentResult> adjustBeanWeightForDoseDelta(
    String beansUuid,
    double doseDelta,
  ) async {
    _callCount++;
    if (_callCount == failAdjustmentCall) {
      adjustments.add((beansUuid, doseDelta, 0));
      return BeanWeightAdjustmentResult.failed(
        StateError('forced adjustment failure'),
        StackTrace.current,
      );
    }
    final result = await super.adjustBeanWeightForDoseDelta(
      beansUuid,
      doseDelta,
    );
    adjustments.add((beansUuid, doseDelta, result.appliedDoseDelta));
    return result;
  }
}
