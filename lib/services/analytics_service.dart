import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show ChangeNotifier, kIsWeb, visibleForTesting;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';

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
///   reviews_translated_batch, review_nudge_card_shown
/// - **general**: app_opened, screen_viewed, recipe_created, recipe_shared,
///   collection interactions and sharing, donation_screen_viewed,
///   donation_button_tapped, donation_completed, donation_failed,
///   roaster_profile_viewed, roaster_link_tapped, roaster_contribution_shown/
///   _submitted/_dismissed, and the "moments" (surprise-and-delight) events
///   moment_shown, moment_interacted, moment_discovered
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
    // General
    'app_opened': 'general',
    'screen_viewed': 'general',
    'recipe_created': 'general',
    'recipe_shared': 'general',
    'collection_card_tapped': 'general',
    'collection_detail_viewed': 'general',
    'collection_recipe_tapped': 'general',
    'collection_shared': 'general',
    'collections_section_toggled': 'general',
    'collections_visibility_changed': 'general',
    'donation_screen_viewed': 'general',
    'donation_button_tapped': 'general',
    'donation_completed': 'general',
    'donation_failed': 'general',
    // Roaster profiles
    'roaster_profile_viewed': 'general',
    'roaster_link_tapped': 'general',
    // Roaster website crowdsourcing (plan 011)
    'roaster_contribution_prompt_shown': 'general',
    'roaster_contribution_submitted': 'general',
    'roaster_contribution_dismissed': 'general',
    // Onboarding & journey
    'onboarding_completed': 'general',
    'journey_started': 'general',
    'journey_milestone_completed': 'general',
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
    // Advanced / beta feature toggles
    'beta_feature_toggled': 'general',
    // Moments (surprise-and-delight / easter eggs)
    'moment_shown': 'general',
    'moment_interacted': 'general',
    'moment_discovered': 'general',
  };

  // ──────────────────── State ────────────────────

  late final SharedPreferences _prefs;
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
  bool _isFlushing = false;

  // ──────────────────── Initialization ────────────────────

  /// Initializes the singleton. Must be called once during app startup,
  /// after [SharedPreferences] is available.
  static Future<AnalyticsService> initialize(SharedPreferences prefs) async {
    if (_instance != null) return _instance!;

    final service = AnalyticsService._();
    service._prefs = prefs;

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
  String get installId => _installId;

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
    // Global kill switch
    if (_globalKillSwitch) return;

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
      event['properties'] = properties;
    }

    // Add to buffer (drop oldest if full)
    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(event);

    // Auto-flush at threshold (non-blocking)
    if (_buffer.length >= _flushThreshold && !_isFlushing) {
      scheduleMicrotask(_flush);
    }
  }

  /// Sets the server-side kill switch. Called from feature flags.
  void setGlobalKillSwitch(bool disabled) {
    _globalKillSwitch = disabled;
  }

  /// Toggles the **brews** analytics category.
  Future<void> setBrewsEnabled(bool enabled) async {
    _brewsEnabled = enabled;
    await _prefs.setBool(_keyBrewsEnabled, enabled);
    notifyListeners();
  }

  /// Toggles the **beans** analytics category.
  Future<void> setBeansEnabled(bool enabled) async {
    _beansEnabled = enabled;
    await _prefs.setBool(_keyBeansEnabled, enabled);
    notifyListeners();
  }

  /// Toggles the **general** analytics category.
  Future<void> setGeneralEnabled(bool enabled) async {
    _generalEnabled = enabled;
    await _prefs.setBool(_keyGeneralEnabled, enabled);
    notifyListeners();
  }

  /// Forces an immediate flush. Called when app goes to background.
  Future<void> flushNow() => _flush();

  // ──────────────────── Private ────────────────────

  bool _isCategoryEnabled(String category) {
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

  Future<void> _flush() async {
    if (_isFlushing || _buffer.isEmpty) return;
    _isFlushing = true;

    // Inject client-side country fallback (server-side detection takes priority)
    if (_country != null) {
      for (final event in _buffer) {
        event.putIfAbsent('country', () => _country!);
      }
    }

    // Snapshot current buffer
    final batch = List<Map<String, dynamic>>.from(_buffer);

    try {
      await Supabase.instance.client.functions.invoke(
        _edgeFunctionName,
        body: {'events': batch},
      );

      // Success — clear flushed events
      _buffer.removeRange(0, batch.length.clamp(0, _buffer.length));
      _consecutiveFailures = 0;
    } catch (e) {
      _consecutiveFailures++;
      AppLogger.warning(
        'Analytics flush failed ($_consecutiveFailures consecutive): $e',
      );

      // After too many failures, drop oldest half to prevent memory growth
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        final halfSize = _buffer.length ~/ 2;
        if (halfSize > 0) {
          _buffer.removeRange(0, halfSize);
        }
        _consecutiveFailures = 0;
        AppLogger.warning(
          'Analytics: dropped oldest $halfSize events after repeated failures',
        );
      }
    } finally {
      _isFlushing = false;
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    // Best-effort flush on dispose
    _flush();
    super.dispose();
  }

  /// Resets the singleton (for testing only).
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
  }
}
