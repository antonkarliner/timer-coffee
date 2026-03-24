import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

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
  static const _keyMilestoneTryMethod = 'onboarding_milestone_try_method';
  static const _keyMilestoneAddBeans = 'onboarding_milestone_add_beans';
  static const _keyMilestoneFavorite = 'onboarding_milestone_favorite';
  static const _keyMilestoneStats = 'onboarding_milestone_stats';
  static const _keyMilestonePulse = 'onboarding_milestone_pulse';
  static const _keyFirstBrewMethodId = 'onboarding_first_brew_method_id';

  bool _onboardingComplete = false;
  bool _firstBrewDone = false;
  bool _journeyDismissed = false;
  bool _journeyCollapsed = false;
  bool _hubJourneyCollapsed = true; // collapsed by default in hub
  bool _journeyFullyDone = false;
  bool _milestoneTryMethod = false;
  bool _milestoneAddBeans = false;
  bool _milestoneFavorite = false;
  bool _milestoneStats = false;
  bool _milestonePulse = false;
  String? _firstBrewMethodId;

  // Public getters
  bool get onboardingComplete => _onboardingComplete;
  bool get firstBrewDone => _firstBrewDone;
  bool get journeyDismissed => _journeyDismissed;
  bool get journeyCollapsed => _journeyCollapsed;
  bool get hubJourneyCollapsed => _hubJourneyCollapsed;
  bool get journeyFullyDone => _journeyFullyDone;
  bool get milestoneFirstBrew => _firstBrewDone;
  bool get milestoneTryMethod => _milestoneTryMethod;
  bool get milestoneAddBeans => _milestoneAddBeans;
  bool get milestoneFavorite => _milestoneFavorite;
  bool get milestoneStats => _milestoneStats;
  bool get milestonePulse => _milestonePulse;

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
      _milestoneTryMethod &&
      _milestoneAddBeans &&
      _milestoneFavorite &&
      _milestoneStats &&
      _milestonePulse;

  int get completedMilestoneCount {
    int count = 0;
    if (_firstBrewDone) count++;
    if (_milestoneTryMethod) count++;
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
    _milestoneTryMethod = _prefs.getBool(_keyMilestoneTryMethod) ?? false;
    _milestoneAddBeans = _prefs.getBool(_keyMilestoneAddBeans) ?? false;
    _milestoneFavorite = _prefs.getBool(_keyMilestoneFavorite) ?? false;
    _milestoneStats = _prefs.getBool(_keyMilestoneStats) ?? false;
    _milestonePulse = _prefs.getBool(_keyMilestonePulse) ?? false;
    _firstBrewMethodId = _prefs.getString(_keyFirstBrewMethodId);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    await _prefs.setBool(_keyOnboardingComplete, true);
    notifyListeners();
  }

  Future<void> completeFirstBrew(String brewingMethodId) async {
    if (!_firstBrewDone) {
      _firstBrewDone = true;
      _firstBrewMethodId = brewingMethodId;
      await _prefs.setBool(_keyFirstBrewDone, true);
      await _prefs.setString(_keyFirstBrewMethodId, brewingMethodId);
      AnalyticsService.instance.track('journey_started', properties: {
        'brewing_method_id': brewingMethodId,
      });
      notifyListeners();
    }
  }

  Future<void> recordBrew(String brewingMethodId) async {
    if (!_firstBrewDone) {
      await completeFirstBrew(brewingMethodId);
    } else if (!_milestoneTryMethod && brewingMethodId != _firstBrewMethodId) {
      _milestoneTryMethod = true;
      await _prefs.setBool(_keyMilestoneTryMethod, true);
      AnalyticsService.instance.track('journey_milestone_completed', properties: {
        'milestone': 'try_method',
      });
      notifyListeners();
    }
  }

  Future<void> completeMilestoneAddBeans() async {
    if (!_milestoneAddBeans) {
      _milestoneAddBeans = true;
      await _prefs.setBool(_keyMilestoneAddBeans, true);
      AnalyticsService.instance.track('journey_milestone_completed', properties: {
        'milestone': 'add_beans',
      });
      notifyListeners();
    }
  }

  Future<void> completeMilestoneFavorite() async {
    if (!_milestoneFavorite) {
      _milestoneFavorite = true;
      await _prefs.setBool(_keyMilestoneFavorite, true);
      AnalyticsService.instance.track('journey_milestone_completed', properties: {
        'milestone': 'favorite',
      });
      notifyListeners();
    }
  }

  Future<void> completeMilestoneStats() async {
    if (!_milestoneStats) {
      _milestoneStats = true;
      await _prefs.setBool(_keyMilestoneStats, true);
      AnalyticsService.instance.track('journey_milestone_completed', properties: {
        'milestone': 'stats',
      });
      notifyListeners();
    }
  }

  Future<void> completeMilestonePulse() async {
    if (!_milestonePulse) {
      _milestonePulse = true;
      await _prefs.setBool(_keyMilestonePulse, true);
      AnalyticsService.instance.track('journey_milestone_completed', properties: {
        'milestone': 'pulse',
      });
      notifyListeners();
    }
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
