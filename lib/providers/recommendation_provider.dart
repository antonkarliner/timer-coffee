import 'dart:async';

import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifecycle of the "For You" bean recommendations (plan 017).
///
/// [hidden] deliberately covers every reason not to show the card: flag
/// off, no signed-in user, opted out, "nothing to show right now" from the
/// server, generation not possible (`insufficient_history` / `no_supply`),
/// and any error. The UI never renders an error or an empty state — it only
/// ever sees [hidden].
enum RecommendationState { idle, loading, ready, hidden }

/// Provides the "For You" bean recommendations. Phase 4 is data-layer only:
/// nothing reads this provider yet, and it loads nothing on its own — the
/// card (a later phase) calls [ensureLoaded] on first build.
///
/// All dependencies are injected so unit tests can fake them; this class
/// never touches `Supabase.instance` directly.
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({
    required BeanRecommendationClient client,
    required String? Function() currentUserId,
    required bool Function() featureFlagEnabled,
    required Future<String?> Function(String localeCode) countryCodeLookup,
    required SharedPreferences prefs,
    DateTime Function()? clock,
  }) : _client = client,
       _currentUserId = currentUserId,
       _featureFlagEnabled = featureFlagEnabled,
       _countryCodeLookup = countryCodeLookup,
       _prefs = prefs,
       _clock = clock ?? DateTime.now {
    // SharedPreferences is already loaded by the time main() constructs this
    // provider, so a synchronous read is safe.
    _optedOut = _prefs.getBool(optOutPrefKey) ?? false;
  }

  static const optOutPrefKey = 'bean_recommendations_opt_out';

  static const _lastGenerateKeyPrefix = 'bean_recs_last_generate_';

  /// At most one `generate` edge-function invocation per user per 6 hours.
  /// The server stores nothing for `insufficient_history`, so without this
  /// every hub open would re-invoke the function for those users.
  static const generateThrottle = Duration(hours: 6);

  final BeanRecommendationClient _client;
  final String? Function() _currentUserId;
  final bool Function() _featureFlagEnabled;
  final Future<String?> Function(String localeCode) _countryCodeLookup;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  RecommendationState _state = RecommendationState.idle;
  List<BeanRecommendation> _items = const [];
  bool _isFirstLoad = false;
  String? _unavailableStatus;
  String? _lastCountryCode;
  bool _optedOut = false;
  bool _disposed = false;
  Future<void>? _inFlight;

  /// Set once the server has decided the state for
  /// [_loadedUserId]/[_loadedLocale]. Gate-hiding (flag off, anonymous,
  /// opted out) is NOT a decision, so the next [ensureLoaded] after e.g.
  /// the flag flips on loads for real.
  bool _decided = false;
  String? _loadedUserId;
  String? _loadedLocale;

  /// Stock ids dismissed this session, so a stale-while-revalidate refresh
  /// cannot resurrect them.
  final Set<String> _sessionDismissals = {};

  RecommendationState get state => _state;

  /// Unmodifiable view of the current picks.
  List<BeanRecommendation> get items => List.unmodifiable(_items);

  /// True only while the very first generation for this user is running —
  /// the card shows skeleton rows only then.
  bool get isFirstLoad => _isFirstLoad;

  /// `insufficient_history`, `no_supply`, `error`, or null — for later
  /// analytics; never surfaced in the UI.
  String? get unavailableStatus => _unavailableStatus;

  /// Last successful country lookup, normalised to a two-letter code.
  /// Unknown until a lookup returns a valid code; lookup failures keep it.
  String? get lastCountryCode => _lastCountryCode;

  bool get optedOut => _optedOut;

  /// Called by the card on first build. Safe to call repeatedly; concurrent
  /// calls share one in-flight load. Never throws.
  Future<void> ensureLoaded(String localeCode) async {
    if (_disposed) return;
    // The card calls this while it is being built. Everything below can
    // notify listeners synchronously (the gates do), and notifying during a
    // build throws "setState() or markNeedsBuild() called during build".
    // Yield once so the first notification always lands after the build.
    await Future<void>.microtask(() {});
    if (_disposed) return;
    try {
      final userId = _currentUserId();
      // Gates: flag off, opted out, or anonymous → hidden, no network.
      if (!_featureFlagEnabled() || _optedOut || userId == null) {
        if (_state != RecommendationState.hidden) _applyHidden();
        return;
      }
      final inFlight = _inFlight;
      if (inFlight != null) {
        await inFlight;
        return;
      }
      if (_decided &&
          _loadedUserId == userId &&
          _loadedLocale == localeCode &&
          (_state == RecommendationState.ready ||
              _state == RecommendationState.hidden)) {
        // Already loaded (or definitively hidden by a server answer) for
        // this user and locale.
        return;
      }
      final load = _load(localeCode, userId);
      _inFlight = load;
      await load.whenComplete(() => _inFlight = null);
    } catch (e, st) {
      AppLogger.error(
        'ensureLoaded failed',
        errorObject: e,
        stackTrace: st,
      );
    }
  }

  /// Removes a pick optimistically and notifies the server best-effort. A
  /// failed network call is logged; the item stays removed for this
  /// session. When the last item goes, the state becomes [hidden].
  Future<void> dismiss(String stockId) async {
    final remaining = _items
        .where((item) => item.stockId != stockId)
        .toList(growable: false);
    if (remaining.length == _items.length) {
      // Item not present (or already empty); still report server-side.
      await _dismissOnServer(stockId);
      return;
    }
    _items = remaining;
    _sessionDismissals.add(stockId);
    if (_items.isEmpty) {
      _state = RecommendationState.hidden;
      _unavailableStatus = null;
    }
    _notify();
    await _dismissOnServer(stockId);
  }

  /// Fire-and-forget click attribution. Never throws.
  Future<void> logLinkOpened(
    String stockId, {
    String surface = 'for_you_card',
  }) async {
    try {
      await _client.logReferredClick(stockId, surface);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to log referred click',
        errorObject: e,
        stackTrace: st,
      );
    }
  }

  /// Opts the user out of recommendations. The preference is persisted
  /// first; `deleteMine()` runs best-effort afterwards (its failure does
  /// not undo the opt-out). Re-enabling resets to [RecommendationState.idle]
  /// so the next [ensureLoaded] loads fresh.
  Future<void> setOptedOut(bool value) async {
    if (value == _optedOut) return;
    _optedOut = value;
    await _prefs.setBool(optOutPrefKey, value);
    if (_disposed) return;
    if (value) {
      _items = const [];
      _sessionDismissals.clear();
      _state = RecommendationState.hidden;
      _isFirstLoad = false;
      _unavailableStatus = null;
      _notify();
      try {
        await _client.deleteMine();
      } catch (e, st) {
        AppLogger.error(
          'Failed to delete stored recommendations on opt-out',
          errorObject: e,
          stackTrace: st,
        );
      }
    } else {
      _state = RecommendationState.idle;
      _items = const [];
      _isFirstLoad = false;
      _unavailableStatus = null;
      _decided = false;
      _loadedUserId = null;
      _loadedLocale = null;
      _notify();
    }
  }

  /// One cold load for (user, locale). Never throws; never notifies after
  /// dispose; bails out quietly if the user opted out mid-flight.
  Future<void> _load(String localeCode, String userId) async {
    try {
      _state = RecommendationState.loading;
      _isFirstLoad = false;
      _unavailableStatus = null;
      _notify();

      final result = await _client.fetch(locale: localeCode);
      if (_aborted) return;

      if (result == null) {
        _decide(userId, localeCode);
        _applyHidden(unavailableStatus: 'error');
        return;
      }

      if (result.items.isNotEmpty) {
        _decide(userId, localeCode);
        _applyReady(_filterDismissed(result.items));
        if (result.stale) {
          // Stale-while-revalidate: keep showing the old list and refresh
          // in the background. Failure changes nothing.
          unawaited(_backgroundRefresh(localeCode, userId));
        }
        return;
      }

      if (result.hasRecommendations && !result.stale) {
        // The server already said "nothing to show right now" — do not
        // regenerate.
        _decide(userId, localeCode);
        _applyHidden();
        return;
      }

      if (result.hasRecommendations && result.stale) {
        // Nothing to show and stale: regenerate in the background, staying
        // hidden unless items come back.
        _decide(userId, localeCode);
        _applyHidden();
        unawaited(_backgroundRefresh(localeCode, userId));
        return;
      }

      // hasRecommendations == false: nothing was ever generated for this
      // user. Skeleton rows while the (slow) first generation runs.
      _isFirstLoad = true;
      _notify();

      final (status, fresh) = await _generateAndRefetch(localeCode, userId);
      if (_aborted) return;
      _decide(userId, localeCode);
      if (fresh != null && fresh.items.isNotEmpty) {
        _applyReady(_filterDismissed(fresh.items));
      } else if (status == BeanRecommendationStatus.insufficientHistory) {
        _applyHidden(unavailableStatus: 'insufficient_history');
      } else if (status == BeanRecommendationStatus.noSupply) {
        _applyHidden(unavailableStatus: 'no_supply');
      } else {
        // Throttled, rate limited, or ok-but-empty: behave as if nothing
        // new came back.
        _applyHidden();
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to load bean recommendations',
        errorObject: e,
        stackTrace: st,
      );
      _decide(userId, localeCode);
      _applyHidden(unavailableStatus: 'error');
    }
  }

  /// Stale-while-revalidate refresh: generate (subject to the throttle) and
  /// fetch again, replacing the items only when fresh ones exist. Never
  /// surfaces errors — on any failure the current state stands.
  Future<void> _backgroundRefresh(String localeCode, String userId) async {
    final (_, fresh) = await _generateAndRefetch(localeCode, userId);
    if (_aborted) return;
    if (fresh != null && fresh.items.isNotEmpty) {
      _items = _filterDismissed(fresh.items);
      _state = RecommendationState.ready;
      _isFirstLoad = false;
      _unavailableStatus = null;
      _notify();
    }
  }

  /// Runs one throttled `generate` + refetch. Returns the terminal generate
  /// status and the fresh result (null unless generate returned ok and the
  /// refetch succeeded). The throttle timestamp is recorded *before* the
  /// call so a slow in-flight generate also blocks re-entry.
  Future<(BeanRecommendationStatus, RecommendationResult?)>
  _generateAndRefetch(String localeCode, String userId) async {
    if (_isThrottled(userId)) {
      return (BeanRecommendationStatus.unknown, null);
    }
    await _prefs.setInt(
      _throttleKey(userId),
      _clock().millisecondsSinceEpoch,
    );
    String? countryCode;
    try {
      countryCode = await _countryCodeLookup(localeCode);
      final normalized = countryCode?.toUpperCase();
      _lastCountryCode =
          normalized != null && RegExp(r'^[A-Z]{2}$').hasMatch(normalized)
          ? normalized
          : null;
    } catch (e, st) {
      AppLogger.warning(
        'Country lookup for recommendations failed',
        errorObject: e,
        stackTrace: st,
      );
    }
    BeanRecommendationStatus status;
    try {
      status = await _client.generate(
        locale: localeCode,
        countryCode: countryCode,
      );
    } catch (e, st) {
      AppLogger.warning(
        'recommend-beans invocation failed',
        errorObject: e,
        stackTrace: st,
      );
      return (BeanRecommendationStatus.unknown, null);
    }
    if (status != BeanRecommendationStatus.ok) {
      return (status, null);
    }
    try {
      return (status, await _client.fetch(locale: localeCode));
    } catch (e, st) {
      AppLogger.warning(
        'Refetch after generate failed',
        errorObject: e,
        stackTrace: st,
      );
      return (status, null);
    }
  }

  Future<void> _dismissOnServer(String stockId) async {
    try {
      await _client.dismiss(stockId);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to persist recommendation dismissal',
        errorObject: e,
        stackTrace: st,
      );
    }
  }

  String _throttleKey(String userId) => '$_lastGenerateKeyPrefix$userId';

  bool _isThrottled(String userId) {
    final last = _prefs.getInt(_throttleKey(userId));
    if (last == null) return false;
    final elapsed = _clock().difference(
      DateTime.fromMillisecondsSinceEpoch(last),
    );
    return elapsed < generateThrottle;
  }

  List<BeanRecommendation> _filterDismissed(List<BeanRecommendation> items) =>
      _sessionDismissals.isEmpty
      ? items
      : items.where((item) => !_sessionDismissals.contains(item.stockId)).toList();

  /// Whether the provider should stop applying results (disposed, or the
  /// user opted out mid-flight — in which case setOptedOut already put the
  /// state where it belongs).
  bool get _aborted => _disposed || _optedOut;

  void _decide(String userId, String localeCode) {
    _decided = true;
    _loadedUserId = userId;
    _loadedLocale = localeCode;
  }

  void _applyReady(List<BeanRecommendation> newItems) {
    _items = newItems;
    _state = RecommendationState.ready;
    _isFirstLoad = false;
    _unavailableStatus = null;
    _notify();
  }

  void _applyHidden({String? unavailableStatus}) {
    _state = RecommendationState.hidden;
    _isFirstLoad = false;
    _unavailableStatus = unavailableStatus;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
