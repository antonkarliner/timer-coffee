import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import 'analytics_service.dart';

/// Per-UTC-hour minimum match count for the in-sync brew celebration.
///
/// Calibrated against 30 days of `global_stats` (~17,146 brews) to target a
/// ~10–25% trigger rate per hour. Quiet hours use a low threshold so off-peak
/// users still get the moment occasionally; peak hours use a higher threshold
/// so the celebration stays meaningful at high traffic.
const Map<int, int> kInSyncThresholdByHour = <int, int>{
  // Quiet (UTC)
  0: 1, 1: 1, 2: 1, 3: 1,
  // Shoulder (early)
  4: 2, 5: 2,
  // Peak
  6: 3, 7: 3, 8: 3, 9: 3, 10: 3, 11: 3,
  12: 3, 13: 3, 14: 3,
  // Shoulder (late)
  15: 2, 16: 2, 17: 2,
  // Quiet
  18: 1, 19: 1, 20: 1, 21: 1, 22: 1, 23: 1,
};

/// Payload used by the debug screen to force an in-sync celebration on the
/// next Finish screen visit. [count] is the number of "coffee lovers"
/// reported; [countries] is an optional list of ISO 3166-1 alpha-2 codes
/// (e.g. `['US', 'DE', 'RU']`) that drive the "from …" subtitle.
class ForcedInSync {
  const ForcedInSync({required this.count, required this.countries});
  final int count;
  final List<String> countries;
}

/// All trackable moment IDs (kept in source order so progress lists are stable).
const List<String> kAllMomentIds = <String>[
  'anniversary',
  'coffee_day',
  'in_sync',
];

/// Centralises "moments worth marking" — the date-based triggers and discovery
/// tracking that power small surprise-and-delight touches across the app.
///
/// Cover-named: file/symbol names read as "moments" so a casual reader of the
/// codebase doesn't immediately see a list of secrets.
class MomentsService extends ChangeNotifier {
  MomentsService({
    required SharedPreferences prefs,
    required AppDatabase database,
  })  : _prefs = prefs,
        _database = database;

  final SharedPreferences _prefs;
  final AppDatabase _database;

  // SharedPreferences keys.
  static const String _keyFirstBrewAt = 'mts_first_brew_at';
  static String _keyMomentDiscovered(String id) => 'moment_$id';
  static String _keyAnniversaryShown(int year) => 'mts_anniversary_shown_$year';
  static String _keyCoffeeDayDismissed(int year) =>
      'mts_coffee_day_dismissed_$year';

  // ---------------------------------------------------------------------------
  // First-brew cache
  // ---------------------------------------------------------------------------

  DateTime? _firstBrewAtCache;
  bool _firstBrewAtLoaded = false;

  /// Override hook for tests; null in production.
  @visibleForTesting
  DateTime? testNowOverride;

  DateTime _now() => testNowOverride ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // Date-based flags
  // ---------------------------------------------------------------------------

  /// True if today (local) is October 1st — International Coffee Day.
  bool get isInternationalCoffeeDay {
    final now = _now();
    return now.month == DateTime.october && now.day == 1;
  }

  /// True iff today's local month+day matches the user's first brew anniversary
  /// AND at least one full year has passed since that brew.
  ///
  /// Returns false until [earliestBrewAt] has been awaited at least once.
  bool get isFirstBrewAnniversary {
    final first = _firstBrewAtCache;
    if (first == null) return false;
    final now = _now();
    if (now.year <= first.year) return false; // need ≥1 full year elapsed
    return now.month == first.month && now.day == first.day;
  }

  // ---------------------------------------------------------------------------
  // First brew lookup
  // ---------------------------------------------------------------------------

  /// Returns the user's earliest brew timestamp (cached after first lookup).
  ///
  /// On a cold start this hits SharedPreferences first (fast path); on a miss
  /// it queries [UserStatsDao.earliestBrewAt] and writes back to prefs so
  /// subsequent calls are cheap.
  Future<DateTime?> earliestBrewAt() async {
    if (_firstBrewAtLoaded) return _firstBrewAtCache;

    final cachedMs = _prefs.getInt(_keyFirstBrewAt);
    if (cachedMs != null) {
      _firstBrewAtCache = DateTime.fromMillisecondsSinceEpoch(cachedMs);
      _firstBrewAtLoaded = true;
      return _firstBrewAtCache;
    }

    final dt = await _database.userStatsDao.earliestBrewAt();
    if (dt != null) {
      await _prefs.setInt(_keyFirstBrewAt, dt.millisecondsSinceEpoch);
    }
    _firstBrewAtCache = dt;
    _firstBrewAtLoaded = true;
    return dt;
  }

  /// Drop the cache and reload from the DAO. Useful right after a fresh user's
  /// very first brew lands in the database.
  Future<void> refreshEarliestBrewAt() async {
    _firstBrewAtLoaded = false;
    _firstBrewAtCache = null;
    await _prefs.remove(_keyFirstBrewAt);
    await earliestBrewAt();
  }

  // ---------------------------------------------------------------------------
  // Discovery tracking
  // ---------------------------------------------------------------------------

  bool isDiscovered(String id) =>
      _prefs.getBool(_keyMomentDiscovered(id)) ?? false;

  /// First call for [id] flips the bit and notifies; subsequent calls are
  /// idempotent.
  Future<void> markDiscovered(String id) async {
    if (isDiscovered(id)) return;
    await _prefs.setBool(_keyMomentDiscovered(id), true);
    // First-ever discovery of this moment (fire-and-forget). maybeInstance
    // no-ops if analytics isn't initialised (e.g. unit tests).
    AnalyticsService.maybeInstance
        ?.track('moment_discovered', properties: {'moment_id': id});
    notifyListeners();
  }

  Set<String> get discovered => kAllMomentIds.where(isDiscovered).toSet();

  int get discoveredCount => discovered.length;

  int get totalMoments => kAllMomentIds.length;

  // ---------------------------------------------------------------------------
  // Per-year shown / dismissed markers
  // ---------------------------------------------------------------------------

  /// True if the anniversary card has already been shown this calendar year.
  /// Year is taken from the local clock so the moment fires once per year.
  bool isAnniversaryShownThisYear() {
    final now = _now();
    return _prefs.getBool(_keyAnniversaryShown(now.year)) ?? false;
  }

  Future<void> markAnniversaryShownThisYear() async {
    final now = _now();
    await _prefs.setBool(_keyAnniversaryShown(now.year), true);
  }

  bool isCoffeeDayDismissedThisYear() {
    final now = _now();
    return _prefs.getBool(_keyCoffeeDayDismissed(now.year)) ?? false;
  }

  Future<void> dismissCoffeeDayThisYear() async {
    final now = _now();
    await _prefs.setBool(_keyCoffeeDayDismissed(now.year), true);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Debug helpers (used by the in-app debug screen at /debug/moments)
  // ---------------------------------------------------------------------------

  /// Override the clock used by date-based flags. Pass null to clear.
  /// Notifies listeners so consumers re-render against the new "now".
  void debugSetNow(DateTime? dt) {
    testNowOverride = dt;
    notifyListeners();
  }

  /// Public read-side of the test-clock override (the underlying field is
  /// `@visibleForTesting`; this is the runtime-safe way to inspect it).
  DateTime? get debugNowOverride => testNowOverride;

  /// Force the cached first-brew timestamp (also writes to SharedPreferences).
  /// Pass null to clear both cache and pref.
  Future<void> debugSetFirstBrewAt(DateTime? at) async {
    if (at == null) {
      await _prefs.remove(_keyFirstBrewAt);
      _firstBrewAtCache = null;
    } else {
      await _prefs.setInt(_keyFirstBrewAt, at.millisecondsSinceEpoch);
      _firstBrewAtCache = at;
    }
    _firstBrewAtLoaded = true;
    notifyListeners();
  }

  /// Currently cached first brew timestamp (no DAO hit).
  DateTime? get debugCachedFirstBrewAt => _firstBrewAtCache;

  /// Synchronously read the persisted version of the first-brew cache.
  DateTime? debugReadPersistedFirstBrewAt() {
    final ms = _prefs.getInt(_keyFirstBrewAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> debugUnmarkDiscovered(String id) async {
    await _prefs.remove(_keyMomentDiscovered(id));
    notifyListeners();
  }

  Future<void> debugMarkAllDiscovered() async {
    for (final id in kAllMomentIds) {
      await _prefs.setBool(_keyMomentDiscovered(id), true);
    }
    notifyListeners();
  }

  Future<void> debugResetAllDiscoveries() async {
    for (final id in kAllMomentIds) {
      await _prefs.remove(_keyMomentDiscovered(id));
    }
    notifyListeners();
  }

  Future<void> debugResetAnniversaryShown() async {
    final now = _now();
    await _prefs.remove(_keyAnniversaryShown(now.year));
    notifyListeners();
  }

  Future<void> debugResetCoffeeDayDismissed() async {
    final now = _now();
    await _prefs.remove(_keyCoffeeDayDismissed(now.year));
    notifyListeners();
  }

  /// In-sync threshold for the current "now" hour (UTC).
  int get debugInSyncThresholdNow {
    final hour = _now().toUtc().hour;
    return kInSyncThresholdByHour[hour] ?? 3;
  }

  /// Single-shot override used by the debug screen to force the in-sync
  /// celebration on the *next* Finish screen visit.
  ///
  /// The Finish screen reads (and clears) this via [consumeForcedInSync]
  /// before issuing its Supabase query. `null` = no force; otherwise the
  /// payload's count + country list are used in place of the real query.
  ForcedInSync? _forcedInSync;

  ForcedInSync? get debugForcedInSync => _forcedInSync;

  /// Schedule a forced in-sync result for the next brew. Pass null to clear.
  /// `countries` is an optional list of ISO 3166-1 alpha-2 codes — when
  /// provided, the in-sync card renders the "from X, Y and Z" subtitle.
  void debugForceInSyncOnNextBrew(
    int? count, {
    List<String> countries = const [],
  }) {
    _forcedInSync = count == null
        ? null
        : ForcedInSync(count: count, countries: List.unmodifiable(countries));
    notifyListeners();
  }

  /// Read & clear the pending force. Returns null if nothing is pending.
  /// Called by the Finish screen at the start of its in-sync resolution.
  /// Deliberately does NOT notify — Finish screen is in a transient state
  /// during initState and we don't want to trigger a rebuild storm.
  ForcedInSync? consumeForcedInSync() {
    final v = _forcedInSync;
    _forcedInSync = null;
    return v;
  }
}
