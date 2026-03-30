import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import 'analytics_service.dart';

class OnboardingReconciliationSnapshot {
  const OnboardingReconciliationSnapshot({
    required this.isFirstLaunch,
    required this.previousAppVersion,
    required this.earliestBrewRecipeId,
    required this.earliestBrewMethodId,
    required this.distinctBrewedRecipeCount,
    required this.beansCount,
    required this.favoriteRecipeCount,
    required this.recipePreferenceCount,
    required this.hasCustomBrewingMethodPreferences,
  });

  final bool isFirstLaunch;
  final String? previousAppVersion;
  final String? earliestBrewRecipeId;
  final String? earliestBrewMethodId;
  final int distinctBrewedRecipeCount;
  final int beansCount;
  final int favoriteRecipeCount;
  final int recipePreferenceCount;
  final bool hasCustomBrewingMethodPreferences;

  bool get hasLegacyEvidence =>
      earliestBrewRecipeId != null ||
      beansCount > 0 ||
      recipePreferenceCount > 0 ||
      hasCustomBrewingMethodPreferences;

  static Future<OnboardingReconciliationSnapshot> fromPersistence({
    required AppDatabase database,
    required SharedPreferences prefs,
    required bool isFirstLaunch,
    String? previousAppVersion,
  }) async {
    final earliestStat = await database.userStatsDao.fetchEarliestStat();
    final distinctBrewedRecipeCount = await database.userStatsDao
        .countDistinctBrewedRecipes();
    final beansCount = await database.coffeeBeansDao.countActiveCoffeeBeans();
    final favoriteRecipeCount = await database.userRecipePreferencesDao
        .countFavoritePreferences();
    final recipePreferenceCount = await database.userRecipePreferencesDao
        .countAllPreferences();
    final shownBrewingMethodIds =
        prefs.getStringList('shownBrewingMethodIds') ?? const <String>[];
    final hiddenBrewingMethodIds =
        prefs.getStringList('hiddenBrewingMethodIds') ?? const <String>[];

    return OnboardingReconciliationSnapshot(
      isFirstLaunch: isFirstLaunch,
      previousAppVersion: previousAppVersion,
      earliestBrewRecipeId: earliestStat?.recipeId,
      earliestBrewMethodId: earliestStat?.brewingMethodId,
      distinctBrewedRecipeCount: distinctBrewedRecipeCount,
      beansCount: beansCount,
      favoriteRecipeCount: favoriteRecipeCount,
      recipePreferenceCount: recipePreferenceCount,
      hasCustomBrewingMethodPreferences:
          shownBrewingMethodIds.isNotEmpty || hiddenBrewingMethodIds.isNotEmpty,
    );
  }
}

bool shouldRedirectToOnboarding(OnboardingService onboardingService) =>
    !onboardingService.onboardingComplete;

/// Tracks onboarding state: welcome screen completion, first-brew flag,
/// and Coffee Journey milestone progress.
class OnboardingService extends ChangeNotifier {
  OnboardingService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  // SharedPreferences keys
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyFirstBrewDone = 'onboarding_first_brew_done';
  static const _keyJourneyDismissed = 'onboarding_journey_dismissed';
  static const _keyJourneyCollapsed = 'onboarding_journey_collapsed';
  static const _keyHubJourneyCollapsed = 'onboarding_hub_journey_collapsed';
  static const _keyJourneyFullyDone = 'onboarding_journey_fully_done';
  static const _keyMilestoneTryRecipe = 'onboarding_milestone_try_method';
  static const _keyMilestoneAddBeans = 'onboarding_milestone_add_beans';
  static const _keyMilestoneFavorite = 'onboarding_milestone_favorite';
  static const _keyMilestoneStats = 'onboarding_milestone_stats';
  static const _keyMilestonePulse = 'onboarding_milestone_pulse';
  static const _keyFirstBrewRecipeId = 'onboarding_first_brew_recipe_id';
  static const _legacyKeyFirstBrewMethodId = 'onboarding_first_brew_method_id';
  static const String onboardingRolloutVersion = '3.6.3';

  bool _onboardingComplete = false;
  bool _firstBrewDone = false;
  bool _journeyDismissed = false;
  bool _journeyCollapsed = false;
  bool _hubJourneyCollapsed = true; // collapsed by default in hub
  bool _journeyFullyDone = false;
  bool _milestoneTryRecipe = false;
  bool _milestoneAddBeans = false;
  bool _milestoneFavorite = false;
  bool _milestoneStats = false;
  bool _milestonePulse = false;
  String? _firstBrewRecipeId;

  // Public getters
  bool get onboardingComplete => _onboardingComplete;
  bool get firstBrewDone => _firstBrewDone;
  bool get journeyDismissed => _journeyDismissed;
  bool get journeyCollapsed => _journeyCollapsed;
  bool get hubJourneyCollapsed => _hubJourneyCollapsed;
  bool get journeyFullyDone => _journeyFullyDone;
  bool get milestoneFirstBrew => _firstBrewDone;
  bool get milestoneTryRecipe => _milestoneTryRecipe;
  bool get milestoneAddBeans => _milestoneAddBeans;
  bool get milestoneFavorite => _milestoneFavorite;
  bool get milestoneStats => _milestoneStats;
  bool get milestonePulse => _milestonePulse;
  @visibleForTesting
  String? get firstBrewRecipeId => _firstBrewRecipeId;

  /// Whether to show the Journey Card on the brewing methods screen.
  bool get shouldShowJourneyCard =>
      _onboardingComplete &&
      _firstBrewDone &&
      !_journeyDismissed &&
      !_journeyFullyDone;

  /// Whether to show the Journey Card on the hub screen.
  /// Only appears after the user dismisses the card from the home screen.
  bool get shouldShowHubJourneyCard =>
      _onboardingComplete &&
      _firstBrewDone &&
      _journeyDismissed &&
      !_journeyFullyDone;

  bool get allMilestonesComplete =>
      _firstBrewDone &&
      _milestoneTryRecipe &&
      _milestoneAddBeans &&
      _milestoneFavorite &&
      _milestoneStats &&
      _milestonePulse;

  int get completedMilestoneCount {
    int count = 0;
    if (_firstBrewDone) count++;
    if (_milestoneTryRecipe) count++;
    if (_milestoneAddBeans) count++;
    if (_milestoneFavorite) count++;
    if (_milestoneStats) count++;
    if (_milestonePulse) count++;
    return count;
  }

  static const int totalMilestones = 6;

  void _load() {
    _onboardingComplete = _prefs.getBool(_keyOnboardingComplete) ?? false;
    _firstBrewDone = _prefs.getBool(_keyFirstBrewDone) ?? false;
    _journeyDismissed = _prefs.getBool(_keyJourneyDismissed) ?? false;
    _journeyCollapsed = _prefs.getBool(_keyJourneyCollapsed) ?? false;
    _hubJourneyCollapsed = _prefs.getBool(_keyHubJourneyCollapsed) ?? true;
    _journeyFullyDone = _prefs.getBool(_keyJourneyFullyDone) ?? false;
    _milestoneTryRecipe = _prefs.getBool(_keyMilestoneTryRecipe) ?? false;
    _milestoneAddBeans = _prefs.getBool(_keyMilestoneAddBeans) ?? false;
    _milestoneFavorite = _prefs.getBool(_keyMilestoneFavorite) ?? false;
    _milestoneStats = _prefs.getBool(_keyMilestoneStats) ?? false;
    _milestonePulse = _prefs.getBool(_keyMilestonePulse) ?? false;
    _firstBrewRecipeId = _prefs.getString(_keyFirstBrewRecipeId);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await _prefs.setBool(_keyOnboardingComplete, true);
    notifyListeners();
  }

  Future<void> completeFirstBrew({
    required String recipeId,
    required String brewingMethodId,
  }) async {
    if (!_firstBrewDone) {
      _firstBrewDone = true;
      _firstBrewRecipeId = recipeId;
      await _prefs.setBool(_keyFirstBrewDone, true);
      await _prefs.setString(_keyFirstBrewRecipeId, recipeId);
      AnalyticsService.instance.track(
        'journey_started',
        properties: {
          'recipe_id': recipeId,
          'brewing_method_id': brewingMethodId,
        },
      );
      notifyListeners();
    }
  }

  Future<void> recordBrew({
    required String recipeId,
    required String brewingMethodId,
  }) async {
    if (!_firstBrewDone) {
      await completeFirstBrew(
        recipeId: recipeId,
        brewingMethodId: brewingMethodId,
      );
      return;
    }

    if (_firstBrewRecipeId == null) {
      _firstBrewRecipeId = recipeId;
      await _prefs.setString(_keyFirstBrewRecipeId, recipeId);
      notifyListeners();
      return;
    }

    if (!_milestoneTryRecipe && recipeId != _firstBrewRecipeId) {
      _milestoneTryRecipe = true;
      await _prefs.setBool(_keyMilestoneTryRecipe, true);
      AnalyticsService.instance.track(
        'journey_milestone_completed',
        properties: {
          'milestone': 'try_recipe',
          'recipe_id': recipeId,
          'brewing_method_id': brewingMethodId,
        },
      );
      notifyListeners();
    }
  }

  Future<void> reconcileState(OnboardingReconciliationSnapshot snapshot) async {
    bool changed = false;
    bool backfilledJourneyProgress = false;
    final hasPersistedState = _hasPersistedOnboardingState;
    final isLegacyInstall = _shouldTreatAsLegacyInstall(snapshot);

    if (!hasPersistedState && isLegacyInstall) {
      changed = await _setOnboardingCompleteSilently() || changed;
    }

    if (snapshot.earliestBrewRecipeId != null) {
      final firstBrewChanged = await _setFirstBrewSilently(
        recipeId: snapshot.earliestBrewRecipeId!,
        persistRecipeId: !_prefs.containsKey(_keyFirstBrewRecipeId),
      );
      backfilledJourneyProgress = firstBrewChanged || backfilledJourneyProgress;
      changed = firstBrewChanged || changed;
    }

    if (!_milestoneTryRecipe && snapshot.distinctBrewedRecipeCount > 1) {
      _milestoneTryRecipe = true;
      await _prefs.setBool(_keyMilestoneTryRecipe, true);
      backfilledJourneyProgress = true;
      changed = true;
    }

    if (!_milestoneAddBeans && snapshot.beansCount > 0) {
      _milestoneAddBeans = true;
      await _prefs.setBool(_keyMilestoneAddBeans, true);
      backfilledJourneyProgress = true;
      changed = true;
    }

    if (!_milestoneFavorite && snapshot.favoriteRecipeCount > 0) {
      _milestoneFavorite = true;
      await _prefs.setBool(_keyMilestoneFavorite, true);
      backfilledJourneyProgress = true;
      changed = true;
    }

    if (backfilledJourneyProgress && _shouldSilentlyFinishReconciledJourney) {
      _journeyFullyDone = true;
      await _prefs.setBool(_keyJourneyFullyDone, true);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> completeMilestoneAddBeans() async {
    if (!_milestoneAddBeans) {
      _milestoneAddBeans = true;
      await _prefs.setBool(_keyMilestoneAddBeans, true);
      AnalyticsService.instance.track(
        'journey_milestone_completed',
        properties: {'milestone': 'add_beans'},
      );
      notifyListeners();
    }
  }

  Future<void> completeMilestoneFavorite() async {
    if (!_milestoneFavorite) {
      _milestoneFavorite = true;
      await _prefs.setBool(_keyMilestoneFavorite, true);
      AnalyticsService.instance.track(
        'journey_milestone_completed',
        properties: {'milestone': 'favorite'},
      );
      notifyListeners();
    }
  }

  Future<void> completeMilestoneStats() async {
    if (!_milestoneStats) {
      _milestoneStats = true;
      await _prefs.setBool(_keyMilestoneStats, true);
      AnalyticsService.instance.track(
        'journey_milestone_completed',
        properties: {'milestone': 'stats'},
      );
      notifyListeners();
    }
  }

  Future<void> completeMilestonePulse() async {
    if (!_milestonePulse) {
      _milestonePulse = true;
      await _prefs.setBool(_keyMilestonePulse, true);
      AnalyticsService.instance.track(
        'journey_milestone_completed',
        properties: {'milestone': 'pulse'},
      );
      notifyListeners();
    }
  }

  bool get _hasPersistedOnboardingState => [
    _keyOnboardingComplete,
    _keyFirstBrewDone,
    _keyJourneyDismissed,
    _keyJourneyCollapsed,
    _keyHubJourneyCollapsed,
    _keyJourneyFullyDone,
    _keyMilestoneTryRecipe,
    _keyMilestoneAddBeans,
    _keyMilestoneFavorite,
    _keyMilestoneStats,
    _keyMilestonePulse,
    _keyFirstBrewRecipeId,
    _legacyKeyFirstBrewMethodId,
  ].any(_prefs.containsKey);

  bool get _shouldSilentlyFinishReconciledJourney =>
      !_journeyFullyDone &&
      _firstBrewDone &&
      _milestoneTryRecipe &&
      _milestoneAddBeans &&
      _milestoneFavorite;

  bool _shouldTreatAsLegacyInstall(OnboardingReconciliationSnapshot snapshot) {
    if (snapshot.isFirstLaunch) {
      return false;
    }

    final previousAppVersion = snapshot.previousAppVersion;
    if (previousAppVersion == null || previousAppVersion.isEmpty) {
      return snapshot.hasLegacyEvidence;
    }

    if (_isVersionLessThan(previousAppVersion, onboardingRolloutVersion)) {
      return true;
    }

    if (previousAppVersion != onboardingRolloutVersion) {
      return false;
    }

    // previous_app_version stores only the semantic version, not the build
    // number, so fall back to legacy evidence for same-version migrations.
    return snapshot.hasLegacyEvidence;
  }

  Future<bool> _setOnboardingCompleteSilently() async {
    if (_onboardingComplete) return false;
    _onboardingComplete = true;
    await _prefs.setBool(_keyOnboardingComplete, true);
    return true;
  }

  Future<bool> _setFirstBrewSilently({
    required String recipeId,
    required bool persistRecipeId,
  }) async {
    bool changed = false;

    if (!_firstBrewDone) {
      _firstBrewDone = true;
      await _prefs.setBool(_keyFirstBrewDone, true);
      changed = true;
    }

    if ((_firstBrewRecipeId == null || persistRecipeId) &&
        _firstBrewRecipeId != recipeId) {
      _firstBrewRecipeId = recipeId;
      await _prefs.setString(_keyFirstBrewRecipeId, recipeId);
      changed = true;
    }

    return changed;
  }

  static bool _isVersionLessThan(String version1, String version2) {
    final v1Parts = version1
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final v2Parts = version2
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    while (v1Parts.length < 3) {
      v1Parts.add(0);
    }
    while (v2Parts.length < 3) {
      v2Parts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return true;
      if (v1Parts[i] > v2Parts[i]) return false;
    }
    return false;
  }

  Future<void> toggleJourneyCollapsed() async {
    _journeyCollapsed = !_journeyCollapsed;
    await _prefs.setBool(_keyJourneyCollapsed, _journeyCollapsed);
    notifyListeners();
  }

  Future<void> toggleHubJourneyCollapsed() async {
    _hubJourneyCollapsed = !_hubJourneyCollapsed;
    await _prefs.setBool(_keyHubJourneyCollapsed, _hubJourneyCollapsed);
    notifyListeners();
  }

  /// Dismiss from the brewing methods screen (× button).
  /// Card remains visible in hub.
  Future<void> dismissJourneyCard() async {
    _journeyDismissed = true;
    await _prefs.setBool(_keyJourneyDismissed, true);
    notifyListeners();
  }

  /// Fully dismiss the journey (Done button after all milestones complete).
  /// Card is removed from everywhere.
  Future<void> completeJourney() async {
    if (!_journeyFullyDone && allMilestonesComplete) {
      AnalyticsService.instance.track('journey_completed');
    }
    _journeyFullyDone = true;
    await _prefs.setBool(_keyJourneyFullyDone, true);
    notifyListeners();
  }
}
