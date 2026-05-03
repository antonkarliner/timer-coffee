import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late OnboardingService service;

  OnboardingReconciliationSnapshot snapshot({
    bool isFirstLaunch = false,
    String? previousAppVersion,
    String? earliestBrewRecipeId,
    String? earliestBrewMethodId = 'v60',
    int distinctBrewedRecipeCount = 0,
    int beansCount = 0,
    int favoriteRecipeCount = 0,
    int recipePreferenceCount = 0,
    bool hasCustomBrewingMethodPreferences = false,
  }) {
    return OnboardingReconciliationSnapshot(
      isFirstLaunch: isFirstLaunch,
      previousAppVersion: previousAppVersion,
      earliestBrewRecipeId: earliestBrewRecipeId,
      earliestBrewMethodId: earliestBrewMethodId,
      distinctBrewedRecipeCount: distinctBrewedRecipeCount,
      beansCount: beansCount,
      favoriteRecipeCount: favoriteRecipeCount,
      recipePreferenceCount: recipePreferenceCount,
      hasCustomBrewingMethodPreferences: hasCustomBrewingMethodPreferences,
    );
  }

  Future<void> loadService([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
    service = OnboardingService(prefs);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
    service = OnboardingService(prefs);
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('reconcileState', () {
    test('fresh install with no evidence keeps onboarding enabled', () async {
      await service.reconcileState(snapshot(isFirstLaunch: true));

      expect(service.onboardingComplete, isFalse);
      expect(service.completedMilestoneCount, 0);
    });

    test(
      'pre-rollout upgrade skips onboarding even without legacy evidence',
      () async {
        await service.reconcileState(snapshot(previousAppVersion: '3.6.2'));

        expect(service.onboardingComplete, isTrue);
      },
    );

    test(
      'ambiguous 3.6.3 upgrade skips onboarding only with legacy evidence',
      () async {
        await service.reconcileState(
          snapshot(previousAppVersion: '3.6.3', recipePreferenceCount: 1),
        );

        expect(service.onboardingComplete, isTrue);
      },
    );

    test('3.6.3 upgrade with no evidence still shows onboarding', () async {
      await service.reconcileState(snapshot(previousAppVersion: '3.6.3'));

      expect(service.onboardingComplete, isFalse);
    });

    test('missing version key plus legacy evidence skips onboarding', () async {
      await service.reconcileState(
        snapshot(previousAppVersion: null, recipePreferenceCount: 1),
      );

      expect(service.onboardingComplete, isTrue);
    });

    test(
      'missing version key with no evidence still shows onboarding',
      () async {
        await service.reconcileState(snapshot(previousAppVersion: null));

        expect(service.onboardingComplete, isFalse);
      },
    );

    test('one brewed recipe repeated completes only first brew', () async {
      await service.reconcileState(
        snapshot(
          previousAppVersion: '3.6.2',
          earliestBrewRecipeId: 'recipe-1',
          distinctBrewedRecipeCount: 1,
        ),
      );

      expect(service.firstBrewDone, isTrue);
      expect(service.firstBrewRecipeId, 'recipe-1');
      expect(service.milestoneTryRecipe, isFalse);
    });

    test(
      'two distinct recipes on the same brewer complete second milestone',
      () async {
        await service.reconcileState(
          snapshot(
            previousAppVersion: '3.6.2',
            earliestBrewRecipeId: 'recipe-1',
            earliestBrewMethodId: 'v60',
            distinctBrewedRecipeCount: 2,
          ),
        );

        expect(service.firstBrewDone, isTrue);
        expect(service.milestoneTryRecipe, isTrue);
      },
    );

    test('beans present complete beans milestone', () async {
      await service.reconcileState(
        snapshot(previousAppVersion: '3.6.2', beansCount: 1),
      );

      expect(service.milestoneAddBeans, isTrue);
    });

    test('favorite prefs present complete favorite milestone', () async {
      await service.reconcileState(
        snapshot(
          previousAppVersion: '3.6.2',
          favoriteRecipeCount: 1,
          recipePreferenceCount: 1,
        ),
      );

      expect(service.milestoneFavorite, isTrue);
    });

    test('stats and pulse remain false for legacy users', () async {
      await service.reconcileState(
        snapshot(
          previousAppVersion: '3.6.2',
          earliestBrewRecipeId: 'recipe-1',
          distinctBrewedRecipeCount: 2,
          beansCount: 1,
          favoriteRecipeCount: 1,
          recipePreferenceCount: 1,
        ),
      );

      expect(service.milestoneStats, isFalse);
      expect(service.milestonePulse, isFalse);
    });

    test(
      'legacy users with only screen-view milestones remaining are hidden',
      () async {
        await service.reconcileState(
          snapshot(
            previousAppVersion: '3.6.2',
            earliestBrewRecipeId: 'recipe-1',
            distinctBrewedRecipeCount: 2,
            beansCount: 1,
            favoriteRecipeCount: 1,
            recipePreferenceCount: 1,
          ),
        );

        expect(service.journeyFullyDone, isTrue);
        expect(service.milestoneStats, isFalse);
        expect(service.milestonePulse, isFalse);
        expect(service.shouldShowJourneyCard, isFalse);
        expect(service.shouldShowHubJourneyCard, isFalse);
      },
    );

    test(
      'reconciled synced users with first 4 milestones are hidden',
      () async {
        await service.reconcileState(
          snapshot(
            previousAppVersion: '3.6.4',
            earliestBrewRecipeId: 'recipe-1',
            distinctBrewedRecipeCount: 2,
            beansCount: 1,
            favoriteRecipeCount: 1,
            recipePreferenceCount: 1,
          ),
        );

        expect(service.journeyFullyDone, isTrue);
        expect(service.milestoneStats, isFalse);
        expect(service.milestonePulse, isFalse);
      },
    );

    test(
      'later launches do not hide users who already completed milestones live',
      () async {
        await loadService({
          'onboarding_complete': true,
          'onboarding_first_brew_done': true,
          'onboarding_first_brew_recipe_id': 'recipe-1',
          'onboarding_milestone_try_method': true,
          'onboarding_milestone_add_beans': true,
          'onboarding_milestone_favorite': true,
        });

        await service.reconcileState(
          snapshot(
            previousAppVersion: '3.6.4',
            earliestBrewRecipeId: 'recipe-1',
            distinctBrewedRecipeCount: 2,
            beansCount: 1,
            favoriteRecipeCount: 1,
            recipePreferenceCount: 1,
          ),
        );

        expect(service.journeyFullyDone, isFalse);
        expect(service.shouldShowJourneyCard, isTrue);
      },
    );

    test('silent reconciliation does not enqueue analytics events', () async {
      await service.reconcileState(
        snapshot(
          previousAppVersion: '3.6.2',
          earliestBrewRecipeId: 'recipe-1',
          distinctBrewedRecipeCount: 2,
          beansCount: 1,
          favoriteRecipeCount: 1,
          recipePreferenceCount: 1,
        ),
      );

      expect(AnalyticsService.instance.bufferLength, 0);
    });

    test('dismiss and fully-done flags are preserved', () async {
      await loadService({
        'onboarding_complete': true,
        'onboarding_journey_dismissed': true,
        'onboarding_journey_fully_done': true,
      });

      await service.reconcileState(
        snapshot(
          previousAppVersion: '3.6.2',
          earliestBrewRecipeId: 'recipe-1',
          distinctBrewedRecipeCount: 2,
          beansCount: 1,
          favoriteRecipeCount: 1,
          recipePreferenceCount: 1,
        ),
      );

      expect(service.onboardingComplete, isTrue);
      expect(service.journeyDismissed, isTrue);
      expect(service.journeyFullyDone, isTrue);
    });

    test('running reconciliation repeatedly is idempotent', () async {
      final state = snapshot(
        previousAppVersion: '3.6.2',
        earliestBrewRecipeId: 'recipe-1',
        distinctBrewedRecipeCount: 2,
        beansCount: 1,
        favoriteRecipeCount: 1,
        recipePreferenceCount: 1,
      );

      await service.reconcileState(state);
      final firstMilestoneCount = service.completedMilestoneCount;
      final firstRecipeId = service.firstBrewRecipeId;

      await service.reconcileState(state);

      expect(service.completedMilestoneCount, firstMilestoneCount);
      expect(service.firstBrewRecipeId, firstRecipeId);
      expect(AnalyticsService.instance.bufferLength, 0);
    });
  });

  group('route gate', () {
    test('redirects to onboarding when onboarding is incomplete', () async {
      expect(shouldRedirectToOnboarding(service), isTrue);
    });

    test('redirects to onboarding for root route', () {
      expect(
        service.routeGateDecisionForUri(
          Uri.parse('/'),
          isValidInternalRoute: true,
        ),
        OnboardingRouteGateDecision.showOnboarding,
      );
    });

    test('redirects to onboarding for onboarding route', () {
      expect(
        service.routeGateDecisionForUri(
          Uri.parse('/onboarding'),
          isValidInternalRoute: true,
        ),
        OnboardingRouteGateDecision.showOnboarding,
      );
    });

    test('skips onboarding for valid recipe links', () {
      expect(
        service.routeGateDecisionForUri(
          Uri.parse('/recipes/v60/recipe-1'),
          isValidInternalRoute: true,
        ),
        OnboardingRouteGateDecision.skipOnboarding,
      );
    });

    test('skips onboarding for valid links with query parameters', () {
      final uri = Uri.parse('/stats?period=thisWeek');

      expect(
        service.routeGateDecisionForUri(uri, isValidInternalRoute: true),
        OnboardingRouteGateDecision.skipOnboarding,
      );
      expect(OnboardingService.normalizedRoutePath(uri), '/stats');
    });

    test('does not skip onboarding for invalid internal links', () {
      expect(
        service.routeGateDecisionForUri(
          Uri.parse('/unknown-route'),
          isValidInternalRoute: false,
        ),
        OnboardingRouteGateDecision.showOnboarding,
      );
    });

    test('does not redirect after onboarding completion', () async {
      await service.completeOnboarding();

      expect(shouldRedirectToOnboarding(service), isFalse);
      expect(
        service.routeGateDecisionForUri(
          Uri.parse('/'),
          isValidInternalRoute: true,
        ),
        OnboardingRouteGateDecision.continueNavigation,
      );
    });
  });

  group('recordBrew', () {
    test('first brew stores the first brewed recipe', () async {
      await service.recordBrew(recipeId: 'recipe-1', brewingMethodId: 'v60');

      expect(service.firstBrewDone, isTrue);
      expect(service.firstBrewRecipeId, 'recipe-1');
      expect(service.milestoneTryRecipe, isFalse);
    });

    test(
      'brewing the same recipe again does not complete the milestone',
      () async {
        await service.recordBrew(recipeId: 'recipe-1', brewingMethodId: 'v60');
        await service.recordBrew(recipeId: 'recipe-1', brewingMethodId: 'v60');

        expect(service.milestoneTryRecipe, isFalse);
      },
    );

    test(
      'brewing another recipe completes the milestone even on the same brewer',
      () async {
        await service.recordBrew(recipeId: 'recipe-1', brewingMethodId: 'v60');
        await service.recordBrew(recipeId: 'recipe-2', brewingMethodId: 'v60');

        expect(service.milestoneTryRecipe, isTrue);
      },
    );
  });
}
