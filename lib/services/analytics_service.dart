import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, kIsWeb, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_endpoint_resolver.dart';
import '../env/env.dart';
import '../utils/app_logger.dart';
import 'feature_flags/feature_flags_repository.dart';

/// Lightweight, fire-and-forget analytics service.
///
/// Events are buffered in memory and flushed to a Supabase Edge Function
/// in batches. All operations on the hot path ([track]) are synchronous
/// so they never block the UI.
///
/// Three privacy categories let users opt-in/out granularly:
/// - **brews**: brew_started, brew_completed, brew_abandoned
/// - **beans**: beans_added, beans_scan_used, beans_attached,
///   review_form_opened, review_added, review_added_after_notification,
///   review_edited, review_deleted, review_translated,
///   reviews_translated_batch, review_nudge_card_shown, bean_deleted
/// - **general**: app_opened, screen_viewed, recipe_created, recipe_shared,
///   collection interactions and sharing, donation_screen_viewed,
///   donation_button_tapped, donation_completed, donation_failed,
///   donation_cancelled,
///   notification_permission_shown, notification_permission_result,
///   notification_tapped, notification_scheduled,
///   notification_presumed_delivered, notification_cancelled,
///   notification_setting_toggled,
///   brew_later_shown, brew_later_tapped, brew_later_scheduled,
///   brew_later_permission_denied, brew_later_settings_opened,
///   notification_schedule_failed,
///   roaster_profile_viewed, roaster_link_tapped, roaster_contribution_shown/
///   _submitted/_dismissed, roaster_report_opened, roaster_report_submitted,
///   roaster_claim_link_tapped, the "moments" (surprise-and-delight) events
///   moment_shown, moment_interacted, moment_discovered, the finish-
///   screen engagement budget (plan 039, shadow mode) events
///   engagement_ask_shown, engagement_ask_suppressed, the store-review
///   request event native_review_requested (plan 070), and the launch popup
///   events popup_shown, popup_dismissed, popup_link_tapped, and the
///   layout adoption events layout_arm_assigned, layout_choice_shown,
///   layout_choice_made, layout_switch_back_reason, and the deletion events
///   user_recipe_deleted, delete_undo_tapped, and the coffee journey
///   milestone suggestion event journey_milestone_suggested
class AnalyticsService extends ChangeNotifier {
  AnalyticsService._();

  static AnalyticsService? _instance;

  /// The singleton instance. Call [initialize] before accessing.
  static AnalyticsService get instance {
    assert(
      _instance != null,
      'AnalyticsService.initialize() must be called first',
    );
    return _instance!;
  }

  /// Null-safe accessor — returns null before [initialize]. Use from contexts
  /// that may run before init (e.g. services, widget tests) where tripping the
  /// [instance] assert is undesirable.
  static AnalyticsService? get maybeInstance => _instance;

  // ──────────────────── Constants ────────────────────

  static const int _maxBufferSize = 500;
  static const int _maxBatchSize = 100;
  static const int _flushThreshold = 50;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _flushInterval = Duration(seconds: 60);
  static const String _edgeFunctionName = 'ingest-analytics';

  // SharedPreferences keys
  static const String _keyInstallId = 'analytics_install_id';
  static const String _keyBrewsEnabled = 'analytics_brews_enabled';
  static const String _keyBeansEnabled = 'analytics_beans_enabled';
  static const String _keyGeneralEnabled = 'analytics_general_enabled';

  // Event → category mapping
  static const Map<String, String> _eventCategory = {
    // Brews
    'brew_started': 'brews',
    'brew_completed': 'brews',
    'brew_abandoned': 'brews',
    'brew_finished': 'brews',
    'last_step_reached': 'brews',
    'last_step_skipped': 'brews',
    // Brew diary (plan 029)
    'manual_brew_logged': 'brews',
    'diary_entry_opened': 'brews',
    'diary_entry_edited': 'brews',
    'diary_entry_deleted': 'brews',
    'diary_bookmark_toggled': 'brews',
    'diary_brew_again_tapped': 'brews',
    'diary_search_used': 'brews',
    'diary_filters_changed': 'brews',
    'diary_axis_changed': 'brews',
    'diary_compare_opened': 'brews',
    'diary_month_strip_used': 'brews',
    'diary_extraction_opened': 'brews',
    // Brew notes portability (plan 036)
    'diary_export_shared': 'brews',
    // Beans
    'beans_added': 'beans',
    'beans_scan_used': 'beans',
    'beans_attached': 'beans',
    'review_form_opened': 'beans',
    'review_added': 'beans',
    'review_added_after_notification': 'beans',
    'review_edited': 'beans',
    'review_deleted': 'beans',
    'review_translated': 'beans',
    'reviews_translated_batch': 'beans',
    'review_nudge_card_shown': 'beans',
    // Deletion instrumentation (plan 056 Phase 5)
    'bean_deleted': 'beans',
    // Personalised bean suggestions (plan 017 Phase 5b)
    'for_you_shown': 'beans',
    'for_you_pick_tapped': 'beans',
    'for_you_link_opened': 'beans',
    'for_you_dismissed': 'beans',
    'for_you_unavailable': 'beans',
    'for_you_setting_toggled': 'beans',
    'for_you_expanded': 'beans',
    // Taste profile screen (plan 086 D3) — never the taste values
    'taste_profile_viewed': 'beans',
    'taste_preference_changed': 'beans',
    // Roaster profile "In stock now" (plan 017 Phase 5d)
    'roaster_stock_shown': 'beans',
    'roaster_stock_link_opened': 'beans',
    // General
    'app_opened': 'general',
    'screen_viewed': 'general',
    'account_email_change_requested': 'general',
    'account_email_changed': 'general',
    'account_email_change_failed': 'general',
    'account_identity_linked': 'general',
    'account_identity_link_failed': 'general',
    'account_identity_unlinked': 'general',
    'sign_in_prompt_shown': 'general',
    'sign_in_method_chosen': 'general',
    'sign_in_completed': 'general',
    'sign_in_failed': 'general',
    'sign_in_sync_failed': 'general',
    'recipe_created': 'general',
    'recipe_shared': 'general',
    'collection_card_tapped': 'general',
    'collection_detail_viewed': 'general',
    'collection_recipe_tapped': 'general',
    'collection_shared': 'general',
    'collections_section_toggled': 'general',
    'collections_visibility_changed': 'general',
    'blog_opened': 'general',
    'donation_screen_viewed': 'general',
    'donation_button_tapped': 'general',
    'donation_completed': 'general',
    'donation_failed': 'general',
    'donation_cancelled': 'general',
    // Roaster profiles
    'roaster_profile_viewed': 'general',
    'roaster_link_tapped': 'general',
    // Roaster website crowdsourcing (plan 011)
    'roaster_contribution_prompt_shown': 'general',
    'roaster_contribution_submitted': 'general',
    'roaster_contribution_dismissed': 'general',
    // Roaster page reports & claims (plan 078)
    'roaster_report_opened': 'general',
    'roaster_report_submitted': 'general',
    'roaster_claim_link_tapped': 'general',
    // Onboarding & journey
    'onboarding_completed': 'general',
    'year_story_opened': 'general',
    'year_story_last_slide_viewed': 'general',
    'journey_started': 'general',
    'journey_milestone_completed': 'general',
    'journey_milestone_suggested': 'general',
    'journey_completed': 'general',
    'journey_dismissed': 'general',
    // Notification permission prompt
    'notification_permission_shown': 'general',
    'notification_permission_result': 'general',
    // Notification engagement
    'notification_tapped': 'general',
    'notification_scheduled': 'general',
    'notification_presumed_delivered': 'general',
    'notification_cancelled': 'general',
    // Notification settings activation
    'notification_setting_toggled': 'general',
    // Brew later reminder (plan 065)
    'brew_later_shown': 'general',
    'brew_later_tapped': 'general',
    'brew_later_scheduled': 'general',
    'brew_later_permission_denied': 'general',
    'brew_later_settings_opened': 'general',
    'notification_schedule_failed': 'general',
    // Advanced / beta feature toggles
    'beta_feature_toggled': 'general',
    // Immersive layout adoption (plan 067)
    'layout_arm_assigned': 'general',
    'layout_choice_shown': 'general',
    'layout_choice_made': 'general',
    'layout_switch_back_reason': 'general',
    // Moments (surprise-and-delight / easter eggs)
    'moment_shown': 'general',
    'moment_interacted': 'general',
    'moment_discovered': 'general',
    // Engagement budget (plan 039, shadow mode)
    'engagement_ask_shown': 'general',
    'engagement_ask_suppressed': 'general',
    // Our OS store-review request, not whether the sheet showed (plan 070)
    'native_review_requested': 'general',
    // Launch popup analytics (plan 039, Item C)
    'popup_shown': 'general',
    'popup_dismissed': 'general',
    'popup_link_tapped': 'general',
    // Campaign support prompt in the launch popup (plan 052, Item A)
    'support_prompt_shown': 'general',
    'support_prompt_tapped': 'general',
    'support_prompt_dismissed': 'general',
    // Deletion + undo instrumentation (plan 056 Phase 5)
    'user_recipe_deleted': 'general',
    'delete_undo_tapped': 'general',
    // Settings reorganization (plan 074 Part B)
    'setting_changed': 'general',
    'settings_shortcut_tapped': 'general',
    'account_entry_tapped': 'general',
    'profile_updated': 'general',
    'signed_out': 'general',
    'account_deleted': 'general',
    'account_deletion_failed': 'general',
    'data_export_started': 'general',
    'data_export_code_sent': 'general',
    'data_export_completed': 'general',
    'data_export_failed': 'general',
  };

  // ──────────────────── State ────────────────────

  late final SharedPreferences _prefs;
  Set<String> _catalogRecipeIds = const {};
  late final Uri _ingestionUri;
  late final String _publicApiKey;
  FeatureFlagsRepository? _featureFlags;
  StreamSubscription<Map<String, bool>>? _flagSubscription;
  late final String _installId;
  late final String _sessionId;
  late final String _platform;
  late String _appVersion;

  /// Client-side country fallback, read from RegionService geoip cache.
  /// Server-side detection (via x-forwarded-for + country.is) takes priority.
  String? _country;

  bool _brewsEnabled = true;
  bool _beansEnabled = true;
  bool _generalEnabled = true;

  /// Server-side kill switch. Set externally from [FeatureFlagsRepository].
  bool _globalKillSwitch = false;

  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;
  int _consecutiveFailures = 0;
  Future<void>? _inFlight;
  bool _flushAgain = false;

  @visibleForTesting
  static Future<void> Function(List<Map<String, dynamic>> events)? sendOverride;

  @visibleForTesting
  static http.Client Function() httpClientFactory = http.Client.new;

  // ──────────────────── Initialization ────────────────────

  /// Initializes the singleton. Must be called once during app startup,
  /// after [SharedPreferences] is available.
  static Future<AnalyticsService> initialize(
    SharedPreferences prefs, {
    FeatureFlagsRepository? featureFlags,
    Iterable<String> catalogRecipeIds = const [],
    String? ingestionBaseUrl,
    String? publicApiKey,
  }) async {
    if (_instance != null) return _instance!;

    final service = AnalyticsService._();
    service._prefs = prefs;
    service.setCatalogRecipeIds(catalogRecipeIds);
    service._ingestionUri = Uri.parse(
      '${ingestionBaseUrl ?? SupabaseEndpointResolver.activeUrl}/functions/v1/$_edgeFunctionName',
    );
    service._publicApiKey = publicApiKey ?? Env.supaKey;
    service._featureFlags = featureFlags;
    service._flagSubscription = featureFlags?.stream.listen((flags) {
      if (flags[FeatureFlagKeys.analyticsEnabled] == false) {
        service._buffer.clear();
      }
    });

    // Install ID: persisted anonymous UUID
    var installId = prefs.getString(_keyInstallId);
    if (installId == null || installId.isEmpty) {
      installId = const Uuid().v4();
      await prefs.setString(_keyInstallId, installId);
    }
    service._installId = installId;

    // Session ID: new per cold start
    service._sessionId = const Uuid().v4();

    // Platform
    if (kIsWeb) {
      service._platform = 'web';
    } else if (Platform.isIOS) {
      service._platform = 'ios';
    } else if (Platform.isAndroid) {
      service._platform = 'android';
    } else {
      service._platform = 'web'; // fallback
    }

    // App version
    try {
      final info = await PackageInfo.fromPlatform();
      service._appVersion = info.version;
    } catch (_) {
      service._appVersion = 'unknown';
    }

    // Country fallback: read from RegionService geoip cache (IP-based, not locale)
    service._country = prefs.getString('country_code_cache');

    // Load category preferences (default: enabled)
    service._brewsEnabled = prefs.getBool(_keyBrewsEnabled) ?? true;
    service._beansEnabled = prefs.getBool(_keyBeansEnabled) ?? true;
    service._generalEnabled = prefs.getBool(_keyGeneralEnabled) ?? true;

    // Start periodic flush timer
    service._flushTimer = Timer.periodic(_flushInterval, (_) {
      service._flush();
    });

    _instance = service;
    return service;
  }

  // ──────────────────── Public Getters ────────────────────

  bool get brewsEnabled => _brewsEnabled;
  bool get beansEnabled => _beansEnabled;
  bool get generalEnabled => _generalEnabled;
  bool get canTrackGeneral => _isCategoryEnabled('general');
  bool get canTrackBeans => _isCategoryEnabled('beans');
  String get installId => _installId;

  void setCatalogRecipeIds(Iterable<String> ids) {
    _catalogRecipeIds = Set.unmodifiable(ids.where(_catalogIdShape.hasMatch));
  }

  /// Number of events currently buffered (for testing/debugging).
  int get bufferLength => _buffer.length;

  @visibleForTesting
  List<Map<String, dynamic>> get bufferedEventsForTesting {
    return List.unmodifiable(
      _buffer.map((event) {
        final snapshot = <String, dynamic>{};
        for (final entry in event.entries) {
          final value = entry.value;
          snapshot[entry.key] = value is Map
              ? Map<String, dynamic>.unmodifiable(value.cast<String, dynamic>())
              : value;
        }
        return Map<String, dynamic>.unmodifiable(snapshot);
      }),
    );
  }

  // ──────────────────── Public API ────────────────────

  /// Records an analytics event. **Synchronous** — adds to an in-memory
  /// buffer and returns immediately. Never blocks the UI.
  ///
  /// Usage:
  /// ```dart
  /// AnalyticsService.instance.track('brew_started', properties: {
  ///   'recipe_id': recipe.id,
  ///   'brewing_method_id': recipe.brewingMethodId,
  /// });
  /// ```
  void track(String eventName, {Map<String, dynamic>? properties}) {
    // Category check
    final category = _eventCategory[eventName];
    if (category == null) {
      AppLogger.warning('Analytics: unknown event "$eventName"');
      return;
    }
    if (!_isCategoryEnabled(category)) return;

    // Build event
    final event = <String, dynamic>{
      'event_name': eventName,
      'category': category,
      'session_id': _sessionId,
      'install_id': _installId,
      'platform': _platform,
      'app_version': _appVersion,
      'client_ts': DateTime.now().toUtc().toIso8601String(),
    };
    if (properties != null && properties.isNotEmpty) {
      final safeProperties = _sanitizeProperties(eventName, properties);
      if (safeProperties.isNotEmpty) event['properties'] = safeProperties;
    }

    // Add to buffer (drop oldest if full)
    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(event);

    // Auto-flush at threshold (non-blocking)
    if (_buffer.length >= _flushThreshold && _inFlight == null) {
      scheduleMicrotask(_flush);
    }
  }

  /// Sets the server-side kill switch. Called from feature flags.
  void setGlobalKillSwitch(bool disabled) {
    _globalKillSwitch = disabled;
    if (disabled) _buffer.clear();
  }

  /// Toggles the **brews** analytics category.
  Future<void> setBrewsEnabled(bool enabled) async {
    _brewsEnabled = enabled;
    if (!enabled) _removeDisabledEvents();
    await _prefs.setBool(_keyBrewsEnabled, enabled);
    notifyListeners();
  }

  /// Toggles the **beans** analytics category.
  Future<void> setBeansEnabled(bool enabled) async {
    _beansEnabled = enabled;
    if (!enabled) _removeDisabledEvents();
    await _prefs.setBool(_keyBeansEnabled, enabled);
    notifyListeners();
  }

  /// Toggles the **general** analytics category.
  Future<void> setGeneralEnabled(bool enabled) async {
    _generalEnabled = enabled;
    if (!enabled) _removeDisabledEvents();
    await _prefs.setBool(_keyGeneralEnabled, enabled);
    notifyListeners();
  }

  /// Flushes buffered events, waiting for any requested follow-up send too.
  /// Failed sends stay buffered, subject to the repeated-failure drop policy.
  Future<void> flushNow() => _flush();

  // ──────────────────── Private ────────────────────

  static const _notificationFields = {'notification_type', 'trigger', 'reason'};
  static const _notificationTypes = {
    'bean_freshness',
    'bean_review_nudge',
    'brew_escalation',
    'brew_later',
    'brew_milestone',
    'brew_reminder',
    'feature_discovery_beans',
    'feature_discovery_pulse',
    'morning_reminder',
    'recipe_exploration',
    'roaster_contribution_nudge',
    'second_brew',
    'unknown',
    'weekly_summary',
  };
  static const _reminderTriggers = {
    'backlog',
    'brew',
    'brew_count',
    'depletion',
    'idle',
    'rest',
    'roaster_contribution',
    'unknown',
  };
  static const _cancellationReasons = {
    'app_opened',
    'brewed',
    'dismissed',
    'reviewed',
    'setting_off',
    'submitted',
    'user',
  };
  static final _catalogIdShape = RegExp(r'^[0-9]{1,12}$');
  static final _localeShape = RegExp(r'^[a-zA-Z]{2,3}([_-][a-zA-Z0-9]{2,8})*$');
  static final _routeNameShape = RegExp(r'^[A-Z][A-Za-z]{1,60}Route$');
  static const _reviewSources = {
    'unknown',
    'finish_screen',
    'roaster_profile',
    'coffee_beans_detail',
  };

  Map<String, dynamic> _sanitizeProperties(
    String eventName,
    Map<String, dynamic> properties,
  ) {
    // Keep reminder routing and review record identifiers out of these events
    // even if another caller passes a local payload to track().
    final fields = switch (eventName) {
      'notification_tapped' ||
      'notification_scheduled' ||
      'notification_presumed_delivered' ||
      'notification_cancelled' => _notificationFields,
      'review_form_opened' => {'mode', 'source_screen'},
      'review_added' => {
        'has_bean',
        'has_roaster_profile',
        'has_text',
        'rating',
        'has_taste_profile',
        'has_flavor_tags',
        'flavor_tags_count',
        'has_brewing_method',
        'would_buy_again',
        'source_screen',
      },
      'review_edited' => {
        'has_bean',
        'rating',
        'has_text',
        'has_taste_profile',
        'has_flavor_tags',
        'has_would_buy_again',
      },
      'review_deleted' => {'has_bean', 'has_roaster_profile'},
      'review_added_after_notification' => {
        'notification_type',
        'trigger',
        'seconds_since_tap',
      },
      'review_nudge_card_shown' => {'trigger', 'impression_count'},
      'review_translated' => {'target_locale', 'source_locale', 'status'},
      'reviews_translated_batch' => {
        'target_locale',
        'requested_count',
        'succeeded_count',
      },
      'onboarding_completed' => {
        'completion_type',
        'brewing_method_id',
        'screen_name',
      },
      _ => null,
    };
    final sanitized = <String, dynamic>{};
    for (final MapEntry(:key, :value) in properties.entries) {
      if (fields != null && !fields.contains(key)) continue;
      if (key == 'recipe_id') {
        // Only known catalog IDs may cross this boundary. Imports, copies, and
        // recipes with unfamiliar identifier formats receive a coarse marker.
        if (value is String) {
          sanitized[key] = _catalogRecipeIds.contains(value)
              ? value
              : 'custom-recipe';
        }
      } else if (value is bool ||
          value is int ||
          value is double && value.isFinite) {
        sanitized[key] = value;
      } else if (value is String) {
        final allowed = switch (key) {
          'notification_type' => _notificationTypes.contains(value),
          'trigger' when fields != null => _reminderTriggers.contains(value),
          'reason' when fields == _notificationFields =>
            _cancellationReasons.contains(value),
          'source_screen' when fields != null => _reviewSources.contains(value),
          'screen_name' when eventName == 'onboarding_completed' =>
            _routeNameShape.hasMatch(value),
          'target_locale' || 'source_locale' => _localeShape.hasMatch(value),
          _ => true,
        };
        if (allowed) sanitized[key] = value;
      }
    }
    return sanitized;
  }

  bool _isCategoryEnabled(String category) {
    if (_globalKillSwitch || _featureFlags?.analyticsEnabled == false) {
      return false;
    }
    switch (category) {
      case 'brews':
        return _brewsEnabled;
      case 'beans':
        return _beansEnabled;
      case 'general':
        return _generalEnabled;
      default:
        return false;
    }
  }

  void _removeDisabledEvents() => _buffer.removeWhere(
    (event) => !_isCategoryEnabled(event['category'] as String),
  );

  Future<void> _flush() {
    final inFlight = _inFlight;
    if (inFlight != null) {
      _flushAgain = true;
      return inFlight;
    }
    if (_buffer.isEmpty) return Future<void>.value();

    // All callers share this future, including any requested follow-up sends.
    _inFlight = _drain().whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  Future<void> _drain() async {
    do {
      _flushAgain = false;
      _removeDisabledEvents();
      if (_buffer.isEmpty) break;

      // Inject client-side country fallback (server-side detection takes priority)
      if (_country != null) {
        for (final event in _buffer) {
          event.putIfAbsent('country', () => _country!);
        }
      }

      // Snapshot current buffer
      final batch = _buffer.take(_maxBatchSize).toList();
      if (batch.length < _buffer.length) _flushAgain = true;

      try {
        final send = sendOverride;
        if (send != null) {
          await send(batch).timeout(const Duration(seconds: 20));
        } else {
          await _sendBatch(batch);
        }

        // Entries can be filtered or evicted while this batch is in flight.
        final sent = Set<Map<String, dynamic>>.identity()..addAll(batch);
        _buffer.removeWhere(sent.contains);
        _consecutiveFailures = 0;
      } catch (_) {
        _consecutiveFailures++;
        AppLogger.warning(
          'Analytics flush failed ($_consecutiveFailures consecutive)',
        );

        // After too many failures, drop oldest half to prevent memory growth
        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          final failed = Set<Map<String, dynamic>>.identity()..addAll(batch);
          final queuedFailures = _buffer.where(failed.contains).toList();
          final halfSize = queuedFailures.length ~/ 2;
          final dropped = Set<Map<String, dynamic>>.identity()
            ..addAll(queuedFailures.take(halfSize));
          _buffer.removeWhere(dropped.contains);
          _consecutiveFailures = 0;
          AppLogger.warning(
            'Analytics: dropped oldest $halfSize events after repeated failures',
          );
        }
        // Leave retries to a later flush rather than hammering while offline.
        break;
      }
    } while (_flushAgain && _buffer.isNotEmpty);
  }

  Future<void> _sendBatch(List<Map<String, dynamic>> batch) async {
    final client = httpClientFactory();
    try {
      // Keep ingestion independent of the signed-in Supabase client's headers.
      final response = await client
          .post(
            _ingestionUri,
            headers: {
              'apikey': _publicApiKey,
              'content-type': 'application/json',
            },
            body: jsonEncode({'events': batch}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Analytics ingestion returned HTTP ${response.statusCode}',
        );
      }
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    unawaited(_flagSubscription?.cancel());
    // Best-effort flush on dispose
    _flush();
    super.dispose();
  }

  /// Resets the singleton (for testing only).
  static void resetForTesting() {
    _instance?._buffer.clear();
    _instance?.dispose();
    _instance = null;
    sendOverride = null;
    httpClientFactory = http.Client.new;
  }
}
