import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Configuration for adaptive OCR mode selection
class OcrAdaptiveConfig {
  final Duration slowOperationThreshold;
  final int slowOperationCountThreshold;
  final bool enableAdaptiveMode;
  final bool debugLogging;

  const OcrAdaptiveConfig({
    this.slowOperationThreshold = const Duration(seconds: 5),
    this.slowOperationCountThreshold = 5,
    this.enableAdaptiveMode = true,
    this.debugLogging = false,
  });

  /// Create config from JSON
  factory OcrAdaptiveConfig.fromJson(Map<String, dynamic> json) {
    return OcrAdaptiveConfig(
      slowOperationThreshold:
          Duration(seconds: json['slowOperationThresholdSeconds'] ?? 5),
      slowOperationCountThreshold: json['slowOperationCountThreshold'] ?? 5,
      enableAdaptiveMode: json['enableAdaptiveMode'] ?? true,
      debugLogging: json['debugLogging'] ?? false,
    );
  }

  /// Convert config to JSON
  Map<String, dynamic> toJson() {
    return {
      'slowOperationThresholdSeconds': slowOperationThreshold.inSeconds,
      'slowOperationCountThreshold': slowOperationCountThreshold,
      'enableAdaptiveMode': enableAdaptiveMode,
      'debugLogging': debugLogging,
    };
  }
}

/// Performance history entry for a single OCR operation
class OcrPerformanceEntry {
  final DateTime timestamp;
  final Duration duration;
  final bool success;
  final String operationType; // 'native' or 'cloud'
  final String? error;

  OcrPerformanceEntry({
    required this.timestamp,
    required this.duration,
    required this.success,
    required this.operationType,
    this.error,
  });

  /// Create entry from JSON
  factory OcrPerformanceEntry.fromJson(Map<String, dynamic> json) {
    return OcrPerformanceEntry(
      timestamp: DateTime.parse(json['timestamp']),
      duration: Duration(milliseconds: json['durationMs']),
      success: json['success'],
      operationType: json['operationType'],
      error: json['error'],
    );
  }

  /// Convert entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'success': success,
      'operationType': operationType,
      'error': error,
    };
  }

  /// Check if this operation is considered slow
  bool isSlow(Duration threshold) {
    return duration > threshold;
  }
}

/// Summary of OCR performance history
class OcrPerformanceSummary {
  final int totalOperations;
  final int slowOperations;
  final int recentSlowOperations; // Last 10 operations
  final bool shouldForceCloudMode;
  final DateTime? lastSlowOperation;
  final Duration averageNativeDuration;
  final Duration averageCloudDuration;

  const OcrPerformanceSummary({
    required this.totalOperations,
    required this.slowOperations,
    required this.recentSlowOperations,
    required this.shouldForceCloudMode,
    this.lastSlowOperation,
    required this.averageNativeDuration,
    required this.averageCloudDuration,
  });
}

/// Manages OCR performance history and adaptive mode selection
class OcrPerformanceHistory {
  static const String _keyConfig = 'ocr_adaptive_config';
  static const String _keyHistory = 'ocr_performance_history';
  static const String _keyForceCloudMode = 'ocr_force_cloud_mode';
  static const String _keySlowOperationCount = 'ocr_slow_operation_count';
  static const int _maxHistoryEntries = 100;

  static OcrPerformanceHistory? _instance;
  static OcrPerformanceHistory get instance {
    _instance ??= OcrPerformanceHistory._internal();
    return _instance!;
  }

  OcrPerformanceHistory._internal();

  SharedPreferences? _prefs;
  OcrAdaptiveConfig _config = const OcrAdaptiveConfig();
  List<OcrPerformanceEntry> _history = [];
  bool _initialized = false;

  /// Initialize the performance history tracker
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadConfig();
      await _loadHistory();
      _initialized = true;
      AppLogger.debug('[OcrHistory] Performance history initialized');
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to initialize: $e');
      // Continue with default values if initialization fails
      _initialized = true;
    }
  }

  /// Load configuration from SharedPreferences
  Future<void> _loadConfig() async {
    if (_prefs == null) return;

    try {
      final configJson = _prefs!.getString(_keyConfig);
      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        _config = OcrAdaptiveConfig.fromJson(configMap);
      }
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to load config: $e');
    }
  }

  /// Save configuration to SharedPreferences
  Future<void> _saveConfig() async {
    if (_prefs == null) return;

    try {
      final configJson = jsonEncode(_config.toJson());
      await _prefs!.setString(_keyConfig, configJson);
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to save config: $e');
    }
  }

  /// Load history from SharedPreferences
  Future<void> _loadHistory() async {
    if (_prefs == null) return;

    try {
      final historyJson = _prefs!.getString(_keyHistory);
      if (historyJson != null) {
        final historyList = jsonDecode(historyJson) as List<dynamic>;
        _history = historyList
            .map((entry) =>
                OcrPerformanceEntry.fromJson(entry as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to load history: $e');
      _history = [];
    }
  }

  /// Save history to SharedPreferences
  Future<void> _saveHistory() async {
    if (_prefs == null) return;

    try {
      final historyJson = jsonEncode(_history.map((e) => e.toJson()).toList());
      await _prefs!.setString(_keyHistory, historyJson);
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to save history: $e');
    }
  }

  /// Get current configuration
  OcrAdaptiveConfig get config => _config;

  /// Update configuration
  Future<void> updateConfig(OcrAdaptiveConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
    AppLogger.debug('[OcrHistory] Configuration updated');
  }

  /// Record an OCR operation
  Future<void> recordOperation({
    required Duration duration,
    required bool success,
    required String operationType,
    String? error,
  }) async {
    if (!_initialized) await initialize();

    final entry = OcrPerformanceEntry(
      timestamp: DateTime.now(),
      duration: duration,
      success: success,
      operationType: operationType,
      error: error,
    );

    _history.add(entry);

    // Keep only the most recent entries
    if (_history.length > _maxHistoryEntries) {
      _history = _history.sublist(_history.length - _maxHistoryEntries);
    }

    // Check if this was a slow operation and update counter
    if (operationType == 'native' &&
        entry.isSlow(_config.slowOperationThreshold)) {
      await _incrementSlowOperationCount();
    }

    await _saveHistory();

    if (_config.debugLogging) {
      AppLogger.debug('[OcrHistory] Recorded operation: $operationType '
          'duration=${duration.inMilliseconds}ms success=$success '
          'slow=${entry.isSlow(_config.slowOperationThreshold)}');
    }
  }

  /// Increment the slow operation counter
  Future<void> _incrementSlowOperationCount() async {
    if (_prefs == null) return;

    try {
      final currentCount = _prefs!.getInt(_keySlowOperationCount) ?? 0;
      final newCount = currentCount + 1;
      await _prefs!.setInt(_keySlowOperationCount, newCount);

      // Check if we should force cloud mode
      if (newCount >= _config.slowOperationCountThreshold) {
        await _setForceCloudMode(true);
        AppLogger.warning(
            '[OcrHistory] Slow operation threshold reached, forcing cloud mode');
      }
    } catch (e) {
      AppLogger.error(
          '[OcrHistory] Failed to increment slow operation count: $e');
    }
  }

  /// Get the current slow operation count
  int getSlowOperationCount() {
    if (_prefs == null) return 0;
    return _prefs!.getInt(_keySlowOperationCount) ?? 0;
  }

  /// Reset the slow operation counter
  Future<void> resetSlowOperationCount() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setInt(_keySlowOperationCount, 0);
      AppLogger.debug('[OcrHistory] Slow operation counter reset');
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to reset slow operation count: $e');
    }
  }

  /// Check if cloud mode should be forced
  bool get shouldForceCloudMode {
    if (!_config.enableAdaptiveMode) return false;
    if (_prefs == null) return false;
    return _prefs!.getBool(_keyForceCloudMode) ?? false;
  }

  /// Set force cloud mode flag
  Future<void> _setForceCloudMode(bool force) async {
    if (_prefs == null) return;

    try {
      await _prefs!.setBool(_keyForceCloudMode, force);
    } catch (e) {
      AppLogger.error('[OcrHistory] Failed to set force cloud mode: $e');
    }
  }

  /// Manually force cloud mode
  Future<void> setForceCloudMode(bool force) async {
    await _setForceCloudMode(force);
    AppLogger.debug('[OcrHistory] Force cloud mode set to: $force');
  }

  /// Reset performance history and counters
  Future<void> resetHistory() async {
    _history.clear();
    await resetSlowOperationCount();
    await _setForceCloudMode(false);
    await _saveHistory();
    AppLogger.debug('[OcrHistory] Performance history reset');
  }

  /// Get performance summary
  OcrPerformanceSummary getPerformanceSummary() {
    final nativeOperations =
        _history.where((e) => e.operationType == 'native').toList();
    final cloudOperations =
        _history.where((e) => e.operationType == 'cloud').toList();

    final slowOperations = _history
        .where((e) =>
            e.operationType == 'native' &&
            e.isSlow(_config.slowOperationThreshold))
        .toList();

    final recentOperations = _history.take(10).toList();
    final recentSlowOperations = recentOperations
        .where((e) =>
            e.operationType == 'native' &&
            e.isSlow(_config.slowOperationThreshold))
        .length;

    final averageNativeDuration = nativeOperations.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: nativeOperations
                    .map((e) => e.duration.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                nativeOperations.length);

    final averageCloudDuration = cloudOperations.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: cloudOperations
                    .map((e) => e.duration.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                cloudOperations.length);

    return OcrPerformanceSummary(
      totalOperations: _history.length,
      slowOperations: slowOperations.length,
      recentSlowOperations: recentSlowOperations,
      shouldForceCloudMode: shouldForceCloudMode,
      lastSlowOperation:
          slowOperations.isNotEmpty ? slowOperations.last.timestamp : null,
      averageNativeDuration: averageNativeDuration,
      averageCloudDuration: averageCloudDuration,
    );
  }

  /// Get all performance entries
  List<OcrPerformanceEntry> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Get recent performance entries (last N)
  List<OcrPerformanceEntry> getRecentHistory(int count) {
    return List.unmodifiable(_history.take(count).toList());
  }

  /// Check if native OCR should be attempted based on performance history
  bool shouldAttemptNativeOcr() {
    if (!_config.enableAdaptiveMode) return true;
    return !shouldForceCloudMode;
  }
}
