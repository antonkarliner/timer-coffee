import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/services/bean_review_prompt_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Stands in for [BeanReviewProvider] so tests never touch Supabase — the
/// real implementation short-circuits to null when signed out, which would
/// mask the cases this suite needs to distinguish (no review vs. signed out).
class _FakeBeanReviewProvider extends BeanReviewProvider {
  BeanReviewModel? review;
  int callCount = 0;

  @override
  Future<BeanReviewModel?> fetchUserReviewByBeanUuid(String beansUuid) async {
    callCount++;
    return review;
  }
}

CoffeeBeansModel _makeBean({
  String uuid = 'bean-1',
  String name = 'Test Bean',
  bool isDeleted = false,
}) {
  return CoffeeBeansModel(
    beansUuid: uuid,
    roaster: 'Test Roaster',
    name: name,
    origin: 'Ethiopia',
    isDeleted: isDeleted,
    versionVector: VersionVector.initial('test').toString(),
  );
}

UserStatsModel _makeStat({required String uuid, DateTime? createdAt}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: 'recipe-1',
    coffeeAmount: 15.0,
    waterAmount: 250.0,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: 'method-1',
    createdAt: createdAt ?? DateTime.now(),
    isMarked: false,
    versionVector: VersionVector.initial('test').toString(),
    isDeleted: false,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late _FakeBeanReviewProvider reviewProvider;

  Future<void> seedBrews({required String beansUuid, required int count}) async {
    for (var i = 0; i < count; i++) {
      await db.userStatsDao.insertUserStat(
        _makeStat(
          uuid: 'stat-$beansUuid-$i',
          createdAt: DateTime.now().subtract(Duration(days: 10 - i)),
        ).copyWith(coffeeBeansUuid: beansUuid),
      );
    }
  }

  BeanReviewPromptService buildService({
    DateTime Function()? now,
    bool signedIn = true,
  }) {
    return BeanReviewPromptService(
      now: now ?? DateTime.now,
      prefs: prefs,
      isSignedIn: () => signedIn,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = openTestDatabase();
    reviewProvider = _FakeBeanReviewProvider();
  });

  tearDown(() async {
    await db.close();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // No-bean / signed-out skip
  // ─────────────────────────────────────────────────────────────────────────

  group('no-bean / signed-out skip', () {
    test('skips when beansUuid is null', () async {
      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: null,
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
      expect(decision.trigger, isNull);
      expect(decision.bean, isNull);
    });

    test('skips when beansUuid is empty', () async {
      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: '',
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
    });

    test('skips when signed out even if otherwise eligible', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final service = buildService(signedIn: false);
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
      // Should not even reach the review-lookup network call.
      expect(reviewProvider.callCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Brew-count trigger boundary
  // ─────────────────────────────────────────────────────────────────────────

  group('brew-count trigger boundary', () {
    test('skips at 4 brews (below minBrews of 5)', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 4);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
    });

    test('shows with brew_count trigger at 5 brews', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isTrue);
      expect(decision.trigger, 'brew_count');
      expect(decision.bean?.beansUuid, 'bean-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Depletion trigger boundary
  // ─────────────────────────────────────────────────────────────────────────

  group('depletion trigger boundary', () {
    test('skips at 1 brew (below depletionMinBrews of 2)', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 1);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: true,
      );

      expect(decision.show, isFalse);
    });

    test('shows with depletion trigger at 2 brews', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 2);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: true,
      );

      expect(decision.show, isTrue);
      expect(decision.trigger, 'depletion');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Frequency caps
  // ─────────────────────────────────────────────────────────────────────────

  group('frequency caps', () {
    test(
        'depletion bypasses the global cooldown but not the per-bean cap',
        () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 2);

      // Global cooldown was tripped moments ago by some other bean.
      await prefs.setInt('review_card_last_shown_ms',
          DateTime.now().millisecondsSinceEpoch);

      final service = buildService();
      final withinCooldown = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: true,
      );
      expect(withinCooldown.show, isTrue,
          reason: 'depletion should bypass the global cooldown');
      expect(withinCooldown.trigger, 'depletion');

      // But the per-bean cap still applies to depletion.
      await prefs.setInt('review_card_imp_bean-1',
          BeanReviewPromptService.maxImpressionsPerBean);
      final atCap = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: true,
      );
      expect(atCap.show, isFalse,
          reason: 'per-bean cap must still gate the depletion trigger');
    });

    test('per-bean cap blocks the 4th impression', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      await prefs.setInt('review_card_imp_bean-1',
          BeanReviewPromptService.maxImpressionsPerBean);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
    });

    test('per-bean cap allows the 3rd impression (below the cap)', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      await prefs.setInt('review_card_imp_bean-1',
          BeanReviewPromptService.maxImpressionsPerBean - 1);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isTrue);
    });

    test('global 3-day cooldown blocks brew_count', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final fixedNow = DateTime(2026, 7, 10, 12);
      await prefs.setInt(
        'review_card_last_shown_ms',
        fixedNow.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      );

      final service = buildService(now: () => fixedNow);
      final blocked = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );
      expect(blocked.show, isFalse);

      // 4 days is past the 3-day cooldown window.
      await prefs.setInt(
        'review_card_last_shown_ms',
        fixedNow.subtract(const Duration(days: 4)).millisecondsSinceEpoch,
      );
      final allowed = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );
      expect(allowed.show, isTrue);
      expect(allowed.trigger, 'brew_count');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Existing review / deleted bean
  // ─────────────────────────────────────────────────────────────────────────

  group('existing review and deleted bean', () {
    test('never shows when the user already reviewed the bean', () async {
      await db.coffeeBeansDao.insertCoffeeBeans(_makeBean(uuid: 'bean-1'));
      await seedBrews(beansUuid: 'bean-1', count: 5);
      reviewProvider.review = BeanReviewModel(
        id: 'review-1',
        userId: 'user-1',
        roasterName: 'Test Roaster',
        beanName: 'Test Bean',
        coffeeBeansUuid: 'bean-1',
        rating: 5,
        isPublic: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
      expect(reviewProvider.callCount, 1);
    });

    test('never shows for a soft-deleted bean', () async {
      await db.coffeeBeansDao
          .insertCoffeeBeans(_makeBean(uuid: 'bean-1', isDeleted: true));
      await seedBrews(beansUuid: 'bean-1', count: 5);

      final service = buildService();
      final decision = await service.evaluate(
        database: db,
        reviewProvider: reviewProvider,
        beansUuid: 'bean-1',
        depletedThisBrew: false,
      );

      expect(decision.show, isFalse);
      // Bean fetch is filtered before the review lookup, so it never runs.
      expect(reviewProvider.callCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Impression bookkeeping
  // ─────────────────────────────────────────────────────────────────────────

  group('recordImpression', () {
    test('bumps the per-bean counter and sets the global timestamp', () async {
      final fixedNow = DateTime(2026, 7, 10, 9);
      final service = buildService(now: () => fixedNow);

      expect(prefs.getInt('review_card_imp_bean-1'), isNull);

      final first = await service.recordImpression('bean-1');
      expect(first, 1);
      expect(prefs.getInt('review_card_imp_bean-1'), 1);
      expect(prefs.getInt('review_card_last_shown_ms'),
          fixedNow.millisecondsSinceEpoch);

      final second = await service.recordImpression('bean-1');
      expect(second, 2);
      expect(prefs.getInt('review_card_imp_bean-1'), 2);
    });

    test('tracks separate counters per bean', () async {
      final service = buildService();

      final bean1First = await service.recordImpression('bean-1');
      final bean2First = await service.recordImpression('bean-2');
      final bean2Second = await service.recordImpression('bean-2');

      expect(bean1First, 1);
      expect(bean2First, 1);
      expect(bean2Second, 2);
      expect(prefs.getInt('review_card_imp_bean-1'), 1);
      expect(prefs.getInt('review_card_imp_bean-2'), 2);
    });
  });
}
