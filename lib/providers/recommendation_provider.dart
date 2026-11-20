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

/// Plan 086: lifecycle of the taste profile on its own screen. Unlike the
/// card, the screen does show an error state (with retry).
enum TasteProfileLoadState { idle, loading, ready, error }

/// Outcome of [RecommendationProvider.setTastePreference].
enum TastePreferenceWriteResult {
  ok,

  /// The server refused: the user already has the maximum number of
  /// adjustments. The change was rolled back.
  limitReached,

  /// Network or server error. The change was rolled back.
  failed,
}

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
    TasteProfileClient? tasteClient,
    DateTime Function()? clock,
    bool debugMode = false,
  }) : _client = client,
       _tasteClient =
           tasteClient ??
           (client is TasteProfileClient ? client as TasteProfileClient : null),
       _currentUserId = currentUserId,
       _featureFlagEnabled = featureFlagEnabled,
       _countryCodeLookup = countryCodeLookup,
       _prefs = prefs,
       _debugMode = debugMode,
       _clock = clock ?? DateTime.now {
    final ownerId = _refreshOwner();
    if (ownerId != null && _hasPendingDelete(ownerId)) {
      unawaited(completePendingOptOut());
    }
  }

  static const optOutPrefKey = 'bean_recommendations_opt_out';
  static const pendingDeleteKey = 'bean_recommendations_pending_delete';

  static String optOutKeyFor(String userId) => '$optOutPrefKey.$userId';
  static String pendingDeleteKeyFor(String userId) =>
      '$pendingDeleteKey.$userId';

  static const _lastGenerateKeyPrefix = 'bean_recs_last_generate_';

  /// At most one `generate` edge-function invocation per user per 6 hours.
  /// The server stores nothing for `insufficient_history`, so without this
  /// every hub open would re-invoke the function for those users.
  static const generateThrottle = Duration(hours: 6);

  final BeanRecommendationClient _client;
  final TasteProfileClient? _tasteClient;
  final String? Function() _currentUserId;
  final bool Function() _featureFlagEnabled;
  final Future<String?> Function(String localeCode) _countryCodeLookup;
  final SharedPreferences _prefs;
  final bool _debugMode;
  final DateTime Function() _clock;

  RecommendationPreferenceClient? get _preferencesClient {
    final client = _client;
    return client is RecommendationPreferenceClient
        ? client as RecommendationPreferenceClient
        : null;
  }

  String? _ownerId;
  bool _preferenceKnown = false;
  Future<void>? _preferenceLoad;
  Future<void> _preferenceWrites = Future.value();
  int _preferenceRevision = 0;

  String? _refreshOwner() {
    final owner = _currentUserId();
    if (_ownerId == owner) return owner;
    _ownerId = owner;
    _preferenceKnown = _preferencesClient == null;
    _preferenceLoad = null;
    _preferenceRevision++;
    // An older installation opt-out remains a local fallback only. Pending
    // deletions without an initiating account can never be safely replayed.
    _optedOut =
        owner != null &&
        (_prefs.getBool(optOutKeyFor(owner)) ??
            _prefs.getBool(optOutPrefKey) ??
            false);
    _items = const [];
    _sessionDismissals.clear();
    _state = RecommendationState.idle;
    _isFirstLoad = false;
    _unavailableStatus = null;
    _lastCountryCode = null;
    _lastGenerateAt = null;
    _lastGenerateStatus = null;
    _lastGenerateFailed = false;
    _decided = false;
    _loadedUserId = null;
    _loadedLocale = null;
    _inFlight = null;
    _backgroundInFlight = null;
    return owner;
  }

  bool _hasPendingDelete(String owner) =>
      _prefs.getBool(pendingDeleteKeyFor(owner)) == true;

  bool _isOwner(String owner) =>
      !_disposed && _ownerId == owner && _currentUserId() == owner;

  bool get _isActive => _ownerId == _currentUserId();

  bool get preferenceKnown => _isActive && _ownerId != null && _preferenceKnown;

  Future<void> ensurePreferenceLoaded() async {
    // Also called from Settings during build.
    await Future<void>.microtask(() {});
    if (_disposed) return;
    final owner = _refreshOwner();
    final preferencesClient = _preferencesClient;
    if (owner == null || _preferenceKnown || preferencesClient == null) return;
    final inFlight = _preferenceLoad;
    if (inFlight != null) return inFlight;
    final revision = _preferenceRevision;
    final load = () async {
      try {
        final remoteOptedOut = await preferencesClient.fetchOptOut();
        if (!_isOwner(owner) || revision != _preferenceRevision) return;
        final localOptedOut = _prefs.getBool(optOutKeyFor(owner));
        final legacyOptedOut =
            localOptedOut == null && _prefs.getBool(optOutPrefKey) == true;
        _optedOut =
            remoteOptedOut || _hasPendingDelete(owner) || legacyOptedOut;
        _preferenceKnown = true;
        _notify();
        if (_hasPendingDelete(owner)) unawaited(completePendingOptOut());
      } catch (error) {
        AppLogger.warning(
          'Could not load recommendation preference',
          errorObject: error,
        );
      }
    }();
    _preferenceLoad = load;
    await load.whenComplete(() {
      if (identical(_preferenceLoad, load)) _preferenceLoad = null;
    });
  }

  RecommendationState _state = RecommendationState.idle;
  List<BeanRecommendation> _items = const [];
  bool _isFirstLoad = false;
  String? _unavailableStatus;
  String? _lastCountryCode;
  bool _optedOut = false;
  bool _disposed = false;
  Future<void>? _inFlight;
  Future<void>? _backgroundInFlight;
  BeanRecommendationStatus? _lastGenerateStatus;
  DateTime? _lastGenerateAt;
  bool _lastGenerateFailed = false;

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

  // Plan 086: the visible, editable taste profile.
  TasteProfile? _tasteProfile;

  /// What the server last confirmed; [_tasteProfile] is this plus any
  /// optimistic writes still in flight.
  TasteProfile? _tasteConfirmed;
  String? _tasteProfileUserId;
  TasteProfileLoadState _tasteProfileState = TasteProfileLoadState.idle;
  Future<void>? _tasteProfileInFlight;

  /// Latest write token per `dimension:value`; a value with a token still has
  /// a write in flight, so its display is not settled yet.
  final Map<String, int> _tasteWriteTokens = {};
  int _nextTasteWriteToken = 0;

  RecommendationState get state =>
      _isActive ? _state : RecommendationState.hidden;

  /// Unmodifiable view of the current picks.
  List<BeanRecommendation> get items =>
      _isActive ? List.unmodifiable(_items) : const [];

  /// True only while the very first generation for this user is running —
  /// the card shows skeleton rows only then.
  bool get isFirstLoad => _isActive && _isFirstLoad;

  /// `insufficient_history`, `no_supply`, `error`, or null — for later
  /// analytics; never surfaced in the UI.
  String? get unavailableStatus => _isActive ? _unavailableStatus : null;

  /// Last successful country lookup, normalised to a two-letter code.
  /// Unknown until a lookup returns a valid code; lookup failures keep it.
  String? get lastCountryCode => _lastCountryCode;

  bool get optedOut => !_isActive || _optedOut;

  /// Last generate answer; null before any call or when the call threw.
  BeanRecommendationStatus? get lastGenerateStatus => _lastGenerateStatus;

  /// Start time of the last generate call, from the injected clock.
  DateTime? get lastGenerateAt => _lastGenerateAt;

  /// Whether the last generate call threw (as opposed to a non-ok answer).
  bool get lastGenerateFailed => _lastGenerateFailed;

  /// The signed-in user's taste profile, or null before it loaded (or after
  /// the user changed).
  TasteProfile? get tasteProfile =>
      _tasteProfileUserId != null && _tasteProfileUserId == _currentUserId()
      ? _tasteProfile
      : null;

  TasteProfileLoadState get tasteProfileState =>
      _tasteProfileUserId == null || _tasteProfileUserId == _currentUserId()
      ? _tasteProfileState
      : TasteProfileLoadState.idle;

  /// Loads the taste profile (plan 086). Concurrent calls share one request.
  /// Keeps a previously loaded profile visible while reloading; on failure
  /// the state becomes [TasteProfileLoadState.error]. Never throws.
  Future<void> loadTasteProfile() {
    return _tasteProfileInFlight ??= _loadTasteProfile().whenComplete(
      () => _tasteProfileInFlight = null,
    );
  }

  Future<void> _loadTasteProfile() async {
    final tasteClient = _tasteClient;
    final userId = _currentUserId();
    if (tasteClient == null || userId == null) {
      _tasteProfile = null;
      _tasteProfileUserId = null;
      _tasteProfileState = TasteProfileLoadState.error;
      _notify();
      return;
    }
    if (_tasteProfileUserId != userId) {
      _tasteProfile = null;
      _tasteConfirmed = null;
      _tasteWriteTokens.clear();
    }
    _tasteProfileUserId = userId;
    _tasteProfileState = TasteProfileLoadState.loading;
    _notify();
    try {
      final profile = await tasteClient.fetchTasteProfile();
      if (_disposed || _currentUserId() != userId) return;
      if (profile == null) {
        _tasteProfileState = TasteProfileLoadState.error;
      } else {
        _tasteProfile = profile;
        _tasteConfirmed = profile;
        _tasteProfileState = TasteProfileLoadState.ready;
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to load taste profile',
        errorObject: e,
        stackTrace: st,
      );
      if (_disposed || _currentUserId() != userId) return;
      _tasteProfileState = TasteProfileLoadState.error;
    }
    _notify();
  }

  /// Sets (or clears, with null) one taste adjustment. The change shows at
  /// once; once no newer write to the same value is pending, the display
  /// settles on what the server confirmed (so a refusal rolls back to the
  /// last confirmed value). After a successful Never, picks
  /// that match it leave the in-memory suggestions, using the same rules as
  /// the server. Never throws.
  Future<TastePreferenceWriteResult> setTastePreference(
    TasteDimension dimension,
    String value,
    TastePreference? preference,
  ) async {
    final tasteClient = _tasteClient;
    final userId = _currentUserId();
    final profile = tasteProfile;
    final key = dimension.normalize(value);
    if (tasteClient == null ||
        userId == null ||
        profile == null ||
        key.isEmpty) {
      return TastePreferenceWriteResult.failed;
    }
    final previous = profile.preferenceFor(dimension, key);
    if (previous == preference) return TastePreferenceWriteResult.ok;

    final tokenKey = '${dimension.wire}:$key';
    final token = ++_nextTasteWriteToken;
    _tasteWriteTokens[tokenKey] = token;
    _tasteProfile = profile.withPreference(dimension, key, preference);
    _notify();

    TastePreferenceWriteResult result;
    try {
      await tasteClient.setTastePreference(dimension, key, preference);
      result = TastePreferenceWriteResult.ok;
    } on TastePreferenceLimitException {
      result = TastePreferenceWriteResult.limitReached;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to save taste preference',
        errorObject: e,
        stackTrace: st,
      );
      result = TastePreferenceWriteResult.failed;
    }
    if (_disposed || _currentUserId() != userId) return result;

    if (_tasteWriteTokens[tokenKey] == token) {
      _tasteWriteTokens.remove(tokenKey);
    }
    final confirmed = _tasteConfirmed;
    if (result == TastePreferenceWriteResult.ok && confirmed != null) {
      _tasteConfirmed = confirmed.withPreference(dimension, key, preference);
    }
    // Once no newer write to this value is pending, show what the server
    // holds: a failure rolls back to the last confirmed value, never to an
    // earlier optimistic one.
    if (!_tasteWriteTokens.containsKey(tokenKey)) {
      final current = _tasteProfile;
      final settled = _tasteConfirmed?.preferenceFor(dimension, key);
      if (current != null && current.preferenceFor(dimension, key) != settled) {
        _tasteProfile = current.withPreference(dimension, key, settled);
        _notify();
      }
      if (result == TastePreferenceWriteResult.ok &&
          settled == TastePreference.never) {
        _dropNeverMatches();
      }
    }
    return result;
  }

  /// Removes picks the current Never adjustments exclude. Mirrors
  /// `score_stock_for_user` / `get_my_recommendations`: an origin excludes a
  /// bean only when every one of its origins is Never; process and roast by
  /// exact match; flavour on any overlap.
  void _dropNeverMatches() {
    final profile = _tasteProfile;
    if (profile == null || _items.isEmpty) return;
    final origins = profile.neverValues(TasteDimension.origin);
    final processes = profile.neverValues(TasteDimension.process);
    final roasts = profile.neverValues(TasteDimension.roast);
    final flavors = profile.neverValues(TasteDimension.flavor);
    bool excluded(BeanRecommendation item) {
      final itemOrigins = item.originCountryCodes
          .map((c) => c.toUpperCase())
          .toList();
      if (itemOrigins.isNotEmpty && itemOrigins.every(origins.contains)) {
        return true;
      }
      final process = item.processFamily?.toLowerCase();
      if (process != null && processes.contains(process)) return true;
      final roast = item.roastLevel?.toLowerCase();
      if (roast != null && roasts.contains(roast)) return true;
      return item.flavorFamilies.any((f) => flavors.contains(f.toLowerCase()));
    }

    final remaining = _items.where((i) => !excluded(i)).toList(growable: false);
    if (remaining.length == _items.length) return;
    _items = remaining;
    if (_items.isEmpty) {
      _state = RecommendationState.hidden;
      _unavailableStatus = null;
    }
    _notify();
  }

  /// Called by the card on first build. Safe to call repeatedly; concurrent
  /// calls share one in-flight load. Never throws.
  Future<void> ensureLoaded(String localeCode) => _ensureLoaded(localeCode);

  /// Explicitly regenerates picks, bypassing the client throttle and asking
  /// the server for fresh picks. Shares the normal load's gates and guard.
  Future<void> refresh(String localeCode) =>
      _ensureLoaded(localeCode, forceRefresh: true);

  Future<void> _ensureLoaded(
    String localeCode, {
    bool forceRefresh = false,
  }) async {
    if (_disposed) return;
    // The card calls this while it is being built. Everything below can
    // notify listeners synchronously (the gates do), and notifying during a
    // build throws "setState() or markNeedsBuild() called during build".
    // Yield once so the first notification always lands after the build.
    await Future<void>.microtask(() {});
    if (_disposed) return;
    try {
      final userId = _refreshOwner();
      // Gates: flag off, opted out, or anonymous → hidden, no network.
      if (!_featureFlagEnabled() || userId == null) {
        if (_state != RecommendationState.hidden) _applyHidden();
        return;
      }
      await ensurePreferenceLoaded();
      if (_abortedFor(userId) || !_preferenceKnown) {
        if (_isOwner(userId) && _state != RecommendationState.hidden) {
          _applyHidden();
        }
        return;
      }
      final inFlight = _inFlight ?? _backgroundInFlight;
      if (inFlight != null) {
        await inFlight;
        return;
      }
      if (!forceRefresh &&
          _decided &&
          _loadedUserId == userId &&
          _loadedLocale == localeCode &&
          (_state == RecommendationState.ready ||
              _state == RecommendationState.hidden)) {
        // Already loaded (or definitively hidden by a server answer) for
        // this user and locale.
        return;
      }
      final load = _load(localeCode, userId, forceRefresh: forceRefresh);
      _inFlight = load;
      await load.whenComplete(() {
        if (identical(_inFlight, load)) _inFlight = null;
      });
    } catch (e, st) {
      AppLogger.error('ensureLoaded failed', errorObject: e, stackTrace: st);
    }
  }

  /// Removes a pick optimistically and notifies the server best-effort. A
  /// failed network call is logged; the item stays removed for this
  /// session. When the last item goes, the state becomes [hidden].
  Future<void> dismiss(String stockId) async {
    if (!_isActive || _optedOut || _disposed) return;
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
    if (!_isActive || _optedOut || _disposed) return;
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
  /// not undo the opt-out) and deletes the stored picks, dismissals and
  /// taste-profile adjustments, whose local copy is dropped here too. Re-enabling resets to [RecommendationState.idle]
  /// so the next [ensureLoaded] loads fresh — and clears the current user's
  /// generate-throttle entry: `deleteMine()` erased the server-side picks,
  /// so without the reset the 6-hour client throttle would keep the
  /// re-enabled card empty until the window elapsed.
  ///
  /// With [deferServerDelete] the card can be hidden at once while the
  /// server deletion waits for [completePendingOptOut] — the card's Undo
  /// snackbar uses this so Undo loses nothing. Either way the deletion is
  /// recorded as owed first, so it is retried on the next launch if it never
  /// runs or fails.
  Future<void> setOptedOut(bool value, {bool deferServerDelete = false}) {
    final owner = _refreshOwner();
    if (owner == null) return Future.value();
    return _writePreference(() async {
      if (!_isOwner(owner) || value == _optedOut) return;
      final client = _preferencesClient;
      if (!value && client != null) {
        try {
          await client.setOptOut(false);
        } catch (error) {
          AppLogger.warning(
            'Could not re-enable recommendations',
            errorObject: error,
          );
          return;
        }
      }
      if (!_isOwner(owner)) return;
      _preferenceRevision++;
      _optedOut = value;
      _preferenceKnown = true;
      await _prefs.setBool(optOutKeyFor(owner), value);
      if (value) {
        await _prefs.setBool(pendingDeleteKeyFor(owner), true);
      } else {
        await _prefs.remove(pendingDeleteKeyFor(owner));
        if (!_debugMode) await _prefs.remove(_throttleKey(owner));
      }
      if (!_isOwner(owner)) return;

      _items = const [];
      _sessionDismissals.clear();
      _state = value ? RecommendationState.hidden : RecommendationState.idle;
      _isFirstLoad = false;
      _unavailableStatus = null;
      _decided = false;
      _loadedUserId = null;
      _loadedLocale = null;
      if (value) {
        _tasteProfile = null;
        _tasteConfirmed = null;
        _tasteProfileUserId = null;
        _tasteProfileState = TasteProfileLoadState.idle;
        _tasteWriteTokens.clear();
      }
      _notify();
      if (!value) return;
      if (!deferServerDelete) {
        await _commitPendingOptOut(owner);
      } else if (client != null) {
        try {
          await client.setOptOut(true);
        } catch (error) {
          AppLogger.warning(
            'Could not pause recommendations',
            errorObject: error,
          );
        }
      }
    });
  }

  /// Retains failed or unsent deletes for the account that authorized them.
  Future<void> completePendingOptOut() {
    final owner = _ownerId;
    if (owner == null) return Future.value();
    return _writePreference(() => _commitPendingOptOut(owner));
  }

  Future<void> _writePreference(Future<void> Function() write) {
    return _preferenceWrites = _preferenceWrites.then((_) async {
      try {
        await write();
      } catch (error, stackTrace) {
        AppLogger.error(
          'Could not save recommendation preference',
          errorObject: error,
          stackTrace: stackTrace,
        );
      }
    });
  }

  Future<void> _commitPendingOptOut(String owner) async {
    if (!_isOwner(owner) || !_optedOut || !_hasPendingDelete(owner)) return;
    try {
      await _client.deleteMine();
      if (_isOwner(owner) && _optedOut) {
        await _prefs.remove(pendingDeleteKeyFor(owner));
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete stored recommendations on opt-out',
        errorObject: e,
        stackTrace: st,
      );
    }
  }

  /// One cold load for (user, locale). Never throws; never notifies after
  /// dispose; bails out quietly if the user opted out mid-flight.
  Future<void> _load(
    String localeCode,
    String userId, {
    bool forceRefresh = false,
  }) async {
    try {
      _state = RecommendationState.loading;
      _isFirstLoad = false;
      _unavailableStatus = null;
      _notify();

      if (forceRefresh) {
        final (status, fresh) = await _generateAndRefetch(
          localeCode,
          userId,
          forceRefresh: true,
        );
        if (_abortedFor(userId)) return;
        _decide(userId, localeCode);
        _applyGenerated(status, fresh);
        return;
      }

      final result = await _client.fetch(locale: localeCode);
      if (_abortedFor(userId)) return;

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
          _startBackgroundRefresh(localeCode, userId);
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
        _startBackgroundRefresh(localeCode, userId);
        return;
      }

      // hasRecommendations == false: nothing was ever generated for this
      // user. Skeleton rows while the (slow) first generation runs.
      _isFirstLoad = true;
      _notify();

      final (status, fresh) = await _generateAndRefetch(localeCode, userId);
      if (_abortedFor(userId)) return;
      _decide(userId, localeCode);
      _applyGenerated(status, fresh);
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

  /// Both first generation and explicit refresh apply the same terminal state.
  void _applyGenerated(
    BeanRecommendationStatus status,
    RecommendationResult? fresh,
  ) {
    final items = _filterDismissed(fresh?.items ?? const []);
    if (items.isNotEmpty) {
      _applyReady(items);
    } else {
      _items = const [];
      _applyHidden(
        unavailableStatus: switch (status) {
          BeanRecommendationStatus.insufficientHistory =>
            'insufficient_history',
          BeanRecommendationStatus.noSupply => 'no_supply',
          _ => null,
        },
      );
    }
  }

  // Keep background generation inside the shared guard too: debug mode has
  // no throttle to prevent a manual refresh racing an ongoing revalidation.
  void _startBackgroundRefresh(String localeCode, String userId) {
    final refresh = _backgroundRefresh(localeCode, userId);
    _backgroundInFlight = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_backgroundInFlight, refresh)) _backgroundInFlight = null;
      }),
    );
  }

  /// Stale-while-revalidate refresh: generate (subject to the throttle) and
  /// fetch again, replacing the items only when fresh ones exist. Never
  /// surfaces errors — on any failure the current state stands.
  Future<void> _backgroundRefresh(String localeCode, String userId) async {
    final (_, fresh) = await _generateAndRefetch(localeCode, userId);
    if (_abortedFor(userId)) return;
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
  Future<(BeanRecommendationStatus, RecommendationResult?)> _generateAndRefetch(
    String localeCode,
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!_debugMode && !forceRefresh && _isThrottled(userId)) {
      return (BeanRecommendationStatus.unknown, null);
    }
    if (!_debugMode) {
      await _prefs.setInt(
        _throttleKey(userId),
        _clock().millisecondsSinceEpoch,
      );
    }
    String? countryCode;
    try {
      countryCode = await _countryCodeLookup(localeCode);
      if (_abortedFor(userId)) return (BeanRecommendationStatus.unknown, null);
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
    if (_abortedFor(userId)) return (BeanRecommendationStatus.unknown, null);
    BeanRecommendationStatus status;
    _lastGenerateAt = _clock();
    _lastGenerateStatus = null;
    _lastGenerateFailed = false;
    try {
      status = await _client.generate(
        locale: localeCode,
        countryCode: countryCode,
        forceRefresh: forceRefresh,
      );
      if (_abortedFor(userId)) return (status, null);
      _lastGenerateStatus = status;
      if (!_abortedFor(userId)) _notify();
    } catch (e, st) {
      if (_abortedFor(userId)) return (BeanRecommendationStatus.unknown, null);
      _lastGenerateFailed = true;
      if (!_abortedFor(userId)) _notify();
      AppLogger.warning(
        'recommend-beans invocation failed',
        errorObject: e,
        stackTrace: st,
      );
      return (BeanRecommendationStatus.unknown, null);
    }
    if (_abortedFor(userId) || status != BeanRecommendationStatus.ok) {
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
      : items
            .where((item) => !_sessionDismissals.contains(item.stockId))
            .toList();

  /// Whether the provider should stop applying results (disposed, or the
  /// user opted out mid-flight — in which case setOptedOut already put the
  /// state where it belongs).
  bool _abortedFor(String owner) => !_isOwner(owner) || _optedOut;

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
