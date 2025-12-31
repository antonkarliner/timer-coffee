import 'dart:async';
import 'dart:convert';

import 'package:coffee_timer/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source responsible solely for fetching flags from Supabase.
class SupabaseFeatureFlagsDataSource {
  SupabaseFeatureFlagsDataSource(this.client);

  final SupabaseClient client;

  Future<Map<String, bool>> fetchFlags({
    required String platform,
    required int buildNumber,
  }) async {
    final response = await client
        .schema('service')
        .from('feature_flags')
        .select('key, enabled, platforms, min_build, max_build');

    final flags = <String, bool>{};

    for (final row in response) {
      final List<dynamic>? platforms = row['platforms'] as List<dynamic>?;
      final int? minBuild = row['min_build'] as int?;
      final int? maxBuild = row['max_build'] as int?;

      final bool platformOk = platforms == null || platforms.contains(platform);
      final bool buildOk =
          (minBuild == null || buildNumber >= minBuild) &&
              (maxBuild == null || buildNumber <= maxBuild);

      final dynamic key = row['key'];
      final dynamic enabled = row['enabled'];

      if (platformOk && buildOk && key is String && enabled is bool) {
        flags[key] = enabled;
      }
    }

    return flags;
  }
}

/// Local cache using a single JSON blob for easy migration/debugging.
class LocalFeatureFlagsStore {
  LocalFeatureFlagsStore(this.prefs);

  static const _prefsKey = 'feature_flags_v1';
  final SharedPreferences prefs;

  Map<String, bool> load() {
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString == null) return {};

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v is bool ? v : false));
    } catch (e, st) {
      AppLogger.warning('Failed to decode cached feature flags',
          errorObject: e, stackTrace: st);
      return {};
    }
  }

  Future<void> save(Map<String, bool> flags) async {
    final jsonString = jsonEncode(flags);
    await prefs.setString(_prefsKey, jsonString);
  }
}

/// Repository providing a single entry point for feature flags.
class FeatureFlagsRepository {
  FeatureFlagsRepository({
    required this.remote,
    required this.local,
    required this.platform,
    required this.buildNumber,
    Duration fetchTimeout = const Duration(seconds: 3),
  }) : _fetchTimeout = fetchTimeout {
    _flags = Map.unmodifiable(local.load());
    _controller = StreamController<Map<String, bool>>.broadcast(
      onListen: () => _controller.add(_flags),
    );
  }

  final SupabaseFeatureFlagsDataSource remote;
  final LocalFeatureFlagsStore local;
  final String platform;
  final int buildNumber;
  final Duration _fetchTimeout;

  late Map<String, bool> _flags;
  late final StreamController<Map<String, bool>> _controller;

  Map<String, bool> get currentFlags => _flags;
  Stream<Map<String, bool>> get stream => _controller.stream;

  bool isEnabled(String key, {bool defaultValue = false}) =>
      _flags[key] ?? defaultValue;

  /// Refresh flags from Supabase with a short timeout to avoid blocking startup.
  Future<void> refresh() async {
    try {
      final newFlags = await remote
          .fetchFlags(platform: platform, buildNumber: buildNumber)
          .timeout(_fetchTimeout, onTimeout: () {
        AppLogger.warning('Feature flag fetch timed out');
        throw TimeoutException('Feature flag fetch timed out');
      });

      _flags = Map.unmodifiable(newFlags);
      await local.save(newFlags);
      _controller.add(_flags);
    } catch (e, st) {
      AppLogger.warning('Feature flag refresh failed',
          errorObject: e, stackTrace: st);
      // Keep cached flags on failure.
    }
  }

  void dispose() {
    _controller.close();
  }
}

class FeatureFlagKeys {
  FeatureFlagKeys._();

  static const holidayGiftBox = 'holiday_gift_box';
  static const newCalendar = 'new_calendar';
  static const testBanner = 'test_banner';
  static const yearlyStatsStory25Banner = 'yearly_stats_story_25_banner';
}

extension FeatureFlagsX on FeatureFlagsRepository {
  bool get holidayGiftBox => isEnabled(FeatureFlagKeys.holidayGiftBox);
  bool get newCalendar => isEnabled(FeatureFlagKeys.newCalendar);
  bool get testBanner => isEnabled(FeatureFlagKeys.testBanner);
  bool get yearlyStatsStory25Banner =>
      isEnabled(FeatureFlagKeys.yearlyStatsStory25Banner);
}
