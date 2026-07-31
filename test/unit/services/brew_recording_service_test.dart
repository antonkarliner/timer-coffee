// Unit tests for `BrewRecordingService` (plan 042, Item B, Phase B1) — the
// context-free extraction of `finish_screen.dart`'s three brew-completion
// side effects (`insertBrewingDataToAppDatabase`, `insertBrewingDataToSupabase`,
// `_updateBeanWeightAfterBrew`), plus `BrewCompletionWriteGate`, which moved
// into the same file unchanged.
//
// Collaborators that can't be faked by subclassing (LocalNotificationScheduler
// Service has a private constructor) are taken by the service as plain
// function parameters, so tests substitute simple counting closures instead
// of a real scheduler or a mockito mock.

import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/brew_recording_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _RecordingUserStatProvider extends UserStatProvider {
  _RecordingUserStatProvider(super.db, super.coffeeBeansProvider);

  int insertCalls = 0;
  Map<String, dynamic>? lastCall;
  Object? throwOnInsert;

  @override
  Future<void> insertUserStat({
    required String recipeId,
    required double coffeeAmount,
    required double waterAmount,
    required int sweetnessSliderPosition,
    required int strengthSliderPosition,
    required String brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
    int? coffeeBeansId,
    bool isMarked = false,
    String? coffeeBeansUuid,
    String? grindSize,
    double? waterTemp,
    int? tasteBalance,
    int? entrySource,
    String? tags,
    String? statUuid,
    DateTime? createdAt,
  }) async {
    insertCalls++;
    lastCall = {
      'recipeId': recipeId,
      'coffeeAmount': coffeeAmount,
      'waterAmount': waterAmount,
      'sweetnessSliderPosition': sweetnessSliderPosition,
      'strengthSliderPosition': strengthSliderPosition,
      'brewingMethodId': brewingMethodId,
      'coffeeBeansUuid': coffeeBeansUuid,
      'grindSize': grindSize,
      'waterTemp': waterTemp,
      'entrySource': entrySource,
      'statUuid': statUuid,
    };
    final err = throwOnInsert;
    if (err != null) throw err;
  }
}

class _RecordingCoffeeBeansProvider extends CoffeeBeansProvider {
  _RecordingCoffeeBeansProvider(super.db, super.databaseProvider);

  int updateCalls = 0;
  double? nextWeight;

  @override
  Future<double?> updateBeanWeightAfterBrew(
    String beansUuid,
    double usedAmount,
  ) async {
    updateCalls++;
    return nextWeight;
  }
}

BrewRecordingRequest _request({
  String statUuid = 'stat-1',
  String? coffeeBeansUuid,
  double coffeeAmount = 15,
  String? countryCode,
  String? userId = 'user-1',
}) {
  return BrewRecordingRequest(
    statUuid: statUuid,
    recipeId: 'recipe-1',
    brewingMethodId: 'v60',
    brewingMethodName: 'V60',
    coffeeAmount: coffeeAmount,
    waterAmount: 250,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    grindSize: '20 clicks',
    waterTemp: 93,
    coffeeBeansUuid: coffeeBeansUuid,
    localeCode: 'en-US',
    languageCode: 'en',
    entrySource: 0,
    countryCode: countryCode,
    userId: userId,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late _RecordingUserStatProvider userStatProvider;
  late _RecordingCoffeeBeansProvider coffeeBeansProvider;

  setUp(() async {
    db = openTestDatabase();
    final databaseProvider = DatabaseProvider(db);
    coffeeBeansProvider = _RecordingCoffeeBeansProvider(db, databaseProvider);
    userStatProvider = _RecordingUserStatProvider(db, coffeeBeansProvider);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
  });

  tearDown(() async {
    AnalyticsService.resetForTesting();
    userStatProvider.dispose();
    coffeeBeansProvider.dispose();
    await db.close();
  });

  group('recordLocalBrew', () {
    test(
      'inserts the stat row and schedules both nudges once when a bean is '
      'attached',
      () async {
        final service = BrewRecordingService();
        var reviewCalls = 0;
        var roasterCalls = 0;

        await service.recordLocalBrew(
          request: _request(coffeeBeansUuid: 'bean-1'),
          userStatProvider: userStatProvider,
          database: db,
          scheduleBeanReviewNudge:
              ({required database, required beansUuid, required locale}) async {
                reviewCalls++;
              },
          scheduleRoasterContribNudge:
              ({required database, required beansUuid, required locale}) async {
                roasterCalls++;
              },
        );

        expect(userStatProvider.insertCalls, 1);
        expect(userStatProvider.lastCall?['statUuid'], 'stat-1');
        expect(userStatProvider.lastCall?['coffeeBeansUuid'], 'bean-1');
        expect(userStatProvider.lastCall?['entrySource'], 0);
        expect(reviewCalls, 1);
        expect(roasterCalls, 1);
        final events = AnalyticsService.instance.bufferedEventsForTesting
            .where((e) => e['event_name'] == 'beans_attached');
        expect(events, hasLength(1));
      },
    );

    test('skips nudges and beans_attached when no bean is attached', () async {
      final service = BrewRecordingService();
      var reviewCalls = 0;
      var roasterCalls = 0;

      await service.recordLocalBrew(
        request: _request(),
        userStatProvider: userStatProvider,
        database: db,
        scheduleBeanReviewNudge:
            ({required database, required beansUuid, required locale}) async {
              reviewCalls++;
            },
        scheduleRoasterContribNudge:
            ({required database, required beansUuid, required locale}) async {
              roasterCalls++;
            },
      );

      expect(userStatProvider.insertCalls, 1);
      expect(reviewCalls, 0);
      expect(roasterCalls, 0);
      final events = AnalyticsService.instance.bufferedEventsForTesting
          .where((e) => e['event_name'] == 'beans_attached');
      expect(events, isEmpty);
    });

    test('does nothing when no user is signed in', () async {
      final service = BrewRecordingService();

      await service.recordLocalBrew(
        request: _request(userId: null, coffeeBeansUuid: 'bean-1'),
        userStatProvider: userStatProvider,
        database: db,
        scheduleBeanReviewNudge:
            ({required database, required beansUuid, required locale}) async {},
        scheduleRoasterContribNudge:
            ({required database, required beansUuid, required locale}) async {},
      );

      expect(userStatProvider.insertCalls, 0);
    });

    test('rethrows on insert failure and does not mark the UUID recorded', () async {
      final service = BrewRecordingService();
      userStatProvider.throwOnInsert = StateError('boom');

      await expectLater(
        service.recordLocalBrew(
          request: _request(coffeeBeansUuid: 'bean-1'),
          userStatProvider: userStatProvider,
          database: db,
          scheduleBeanReviewNudge:
              ({required database, required beansUuid, required locale}) async {},
          scheduleRoasterContribNudge:
              ({required database, required beansUuid, required locale}) async {},
        ),
        throwsStateError,
      );
      // A failed insert must not be marked "recorded" — a retry (e.g. B2's
      // orphan recovery) must still be attempted, not silently skipped.
      expect(service.hasRecordedForTesting('stat-1'), isFalse);
    });

    test(
      'called twice with the same statUuid inserts once, schedules nudges '
      'once, emits beans_attached once',
      () async {
        final service = BrewRecordingService();
        var reviewCalls = 0;
        var roasterCalls = 0;

        Future<void> call() => service.recordLocalBrew(
          request: _request(coffeeBeansUuid: 'bean-1'),
          userStatProvider: userStatProvider,
          database: db,
          scheduleBeanReviewNudge:
              ({required database, required beansUuid, required locale}) async {
                reviewCalls++;
              },
          scheduleRoasterContribNudge:
              ({required database, required beansUuid, required locale}) async {
                roasterCalls++;
              },
        );

        await call();
        await call();

        expect(userStatProvider.insertCalls, 1);
        expect(reviewCalls, 1);
        expect(roasterCalls, 1);
        final events = AnalyticsService.instance.bufferedEventsForTesting
            .where((e) => e['event_name'] == 'beans_attached');
        expect(events, hasLength(1));
        expect(service.hasRecordedForTesting('stat-1'), isTrue);
      },
    );
  });

  group('recordRemoteBrew', () {
    test('inserts the resolved payload once', () async {
      final service = BrewRecordingService();
      var insertCalls = 0;
      Map<String, dynamic>? lastData;

      await service.recordRemoteBrew(
        request: _request(countryCode: 'US'),
        insertGlobalStat: (data) async {
          insertCalls++;
          lastData = data;
        },
      );

      expect(insertCalls, 1);
      expect(lastData, {
        'user_id': 'user-1',
        'brewing_method': 'V60',
        'recipe_id': 'recipe-1',
        'water_amount': 250.0,
        'country_code': 'US',
      });
    });

    test('omits country_code when unresolved', () async {
      final service = BrewRecordingService();
      Map<String, dynamic>? lastData;

      await service.recordRemoteBrew(
        request: _request(countryCode: null),
        insertGlobalStat: (data) async {
          lastData = data;
        },
      );

      expect(lastData!.containsKey('country_code'), isFalse);
    });

    test('does nothing when no user is signed in', () async {
      final service = BrewRecordingService();
      var insertCalls = 0;

      await service.recordRemoteBrew(
        request: _request(userId: null),
        insertGlobalStat: (data) async {
          insertCalls++;
        },
      );

      expect(insertCalls, 0);
    });

    test('swallows a timeout without rethrowing', () async {
      final service = BrewRecordingService();

      await service.recordRemoteBrew(
        request: _request(),
        insertGlobalStat: (data) =>
            Future<void>.error(TimeoutException('slow')),
      );
      // Reaching this line means recordRemoteBrew did not rethrow.
    });

    test('swallows a generic error without rethrowing', () async {
      final service = BrewRecordingService();

      await service.recordRemoteBrew(
        request: _request(),
        insertGlobalStat: (data) => Future<void>.error(StateError('boom')),
      );
    });
  });

  group('updateBeanWeight', () {
    test('decrements weight and returns false when not depleted', () async {
      final service = BrewRecordingService();
      coffeeBeansProvider.nextWeight = 150;
      var depletionCalls = 0;

      final result = await service.updateBeanWeight(
        request: _request(coffeeBeansUuid: 'bean-1'),
        coffeeBeansProvider: coffeeBeansProvider,
        database: db,
        scheduleBeanReviewNudgeOnDepletion:
            ({required database, required beansUuid, required locale}) async {
              depletionCalls++;
            },
      );

      expect(result, isFalse);
      expect(coffeeBeansProvider.updateCalls, 1);
      expect(depletionCalls, 0);
    });

    test(
      'returns true and schedules the depletion nudge when the bag empties',
      () async {
        final service = BrewRecordingService();
        coffeeBeansProvider.nextWeight = 0.0;
        var depletionCalls = 0;

        final result = await service.updateBeanWeight(
          request: _request(coffeeBeansUuid: 'bean-1'),
          coffeeBeansProvider: coffeeBeansProvider,
          database: db,
          scheduleBeanReviewNudgeOnDepletion:
              ({required database, required beansUuid, required locale}) async {
                depletionCalls++;
              },
        );

        expect(result, isTrue);
        expect(depletionCalls, 1);
      },
    );

    test(
      'returns false without touching the provider when coffeeAmount <= 0',
      () async {
        final service = BrewRecordingService();

        final result = await service.updateBeanWeight(
          request: _request(coffeeBeansUuid: 'bean-1', coffeeAmount: 0),
          coffeeBeansProvider: coffeeBeansProvider,
          database: db,
          scheduleBeanReviewNudgeOnDepletion:
              ({
                required database,
                required beansUuid,
                required locale,
              }) async {},
        );

        expect(result, isFalse);
        expect(coffeeBeansProvider.updateCalls, 0);
      },
    );

    test(
      'returns false without touching the provider when no bean uuid is set',
      () async {
        final service = BrewRecordingService();

        final result = await service.updateBeanWeight(
          request: _request(),
          coffeeBeansProvider: coffeeBeansProvider,
          database: db,
          scheduleBeanReviewNudgeOnDepletion:
              ({
                required database,
                required beansUuid,
                required locale,
              }) async {},
        );

        expect(result, isFalse);
        expect(coffeeBeansProvider.updateCalls, 0);
      },
    );

    test('returns false when the provider reports no applicable update', () async {
      final service = BrewRecordingService();
      coffeeBeansProvider.nextWeight = null;

      final result = await service.updateBeanWeight(
        request: _request(coffeeBeansUuid: 'bean-1'),
        coffeeBeansProvider: coffeeBeansProvider,
        database: db,
        scheduleBeanReviewNudgeOnDepletion:
            ({required database, required beansUuid, required locale}) async {},
      );

      expect(result, isFalse);
    });

    test(
      'does not double-decrement when the same statUuid was already recorded',
      () async {
        final service = BrewRecordingService();
        coffeeBeansProvider.nextWeight = 150;

        // First, record the local brew for this statUuid — marks it done.
        await service.recordLocalBrew(
          request: _request(coffeeBeansUuid: 'bean-1'),
          userStatProvider: userStatProvider,
          database: db,
          scheduleBeanReviewNudge:
              ({
                required database,
                required beansUuid,
                required locale,
              }) async {},
          scheduleRoasterContribNudge:
              ({
                required database,
                required beansUuid,
                required locale,
              }) async {},
        );

        final result = await service.updateBeanWeight(
          request: _request(coffeeBeansUuid: 'bean-1'),
          coffeeBeansProvider: coffeeBeansProvider,
          database: db,
          scheduleBeanReviewNudgeOnDepletion:
              ({
                required database,
                required beansUuid,
                required locale,
              }) async {},
        );

        expect(result, isFalse);
        expect(coffeeBeansProvider.updateCalls, 0);
      },
    );
  });

  group('BrewCompletionWriteGate', () {
    test('starts exactly once and exposes stable results', () async {
      final gate = BrewCompletionWriteGate();
      var insertCalls = 0;
      var beanWeightCalls = 0;

      Future<void> insert() async {
        insertCalls++;
      }

      Future<bool> updateBeanWeight() async {
        beanWeightCalls++;
        return true;
      }

      gate.start(insertBrew: insert, updateBeanWeight: updateBeanWeight);
      gate.start(insertBrew: insert, updateBeanWeight: updateBeanWeight);

      await gate.insertFuture;
      expect(await gate.beanWeightFuture, isTrue);
      expect(insertCalls, 1);
      expect(beanWeightCalls, 1);
    });

    test('insert failure remains observable to dependent writes', () async {
      final gate = BrewCompletionWriteGate();

      gate.start(
        insertBrew: () => Future<void>.error(StateError('insert failed')),
        updateBeanWeight: () async => false,
      );

      await expectLater(gate.insertFuture, throwsStateError);
      expect(await gate.beanWeightFuture, isFalse);
    });
  });
}
