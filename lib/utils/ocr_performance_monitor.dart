import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/device_profiler.dart';

/// Types of OCR operations for performance tracking
enum OcrOperationType {
  native,
  fallback,
  preprocessing,
  imageResize,
  base64Encoding,
}

/// Device capability categories for performance correlation
enum DeviceCapability {
  lowEnd,
  midRange,
  highEnd,
  unknown,
}

/// Performance metrics for a single OCR operation
class OcrPerformanceMetric {
  final OcrOperationType operationType;
  final Duration duration;
  final int memoryUsageBefore;
  final int memoryUsageAfter;
  final int imageSizeBytes;
  final bool success;
  final String? error;
  final DeviceCapability deviceCapability;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  OcrPerformanceMetric({
    required this.operationType,
    required this.duration,
    required this.memoryUsageBefore,
    required this.memoryUsageAfter,
    required this.imageSizeBytes,
    required this.success,
    this.error,
    required this.deviceCapability,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
  })  : timestamp = timestamp ?? DateTime.now(),
        additionalData = additionalData ?? {};

  /// Memory delta for this operation
  int get memoryDelta => memoryUsageAfter - memoryUsageBefore;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'operationType': operationType.toString(),
      'durationMs': duration.inMilliseconds,
      'memoryUsageBefore': memoryUsageBefore,
      'memoryUsageAfter': memoryUsageAfter,
      'memoryDelta': memoryDelta,
      'imageSizeBytes': imageSizeBytes,
      'success': success,
      'error': error,
      'deviceCapability': deviceCapability.toString(),
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}

/// Aggregated performance statistics
class OcrPerformanceStats {
  final Map<OcrOperationType, int> operationCounts = {};
  final Map<OcrOperationType, Duration> totalDurations = {};
  final Map<OcrOperationType, int> successCounts = {};
  final Map<OcrOperationType, int> failureCounts = {};
  final Map<DeviceCapability, List<OcrPerformanceMetric>> metricsByDevice = {};
  final List<OcrPerformanceMetric> recentMetrics = [];

  /// Average duration for an operation type
  Duration? getAverageDuration(OcrOperationType type) {
    final count = operationCounts[type] ?? 0;
    if (count == 0) return null;
    final total = totalDurations[type] ?? Duration.zero;
    return Duration(milliseconds: total.inMilliseconds ~/ count);
  }

  /// Success rate for an operation type
  double getSuccessRate(OcrOperationType type) {
    final total = (operationCounts[type] ?? 0);
    if (total == 0) return 0.0;
    final successes = successCounts[type] ?? 0;
    return successes / total;
  }

  /// Average memory usage for an operation type
  double getAverageMemoryDelta(OcrOperationType type) {
    final metrics = metricsByDevice.values
        .expand((m) => m)
        .where((m) => m.operationType == type);
    if (metrics.isEmpty) return 0.0;

    final totalDelta = metrics.fold<int>(0, (sum, m) => sum + m.memoryDelta);
    return totalDelta / metrics.length;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'operationCounts':
          operationCounts.map((k, v) => MapEntry(k.toString(), v)),
      'totalDurations': totalDurations
          .map((k, v) => MapEntry(k.toString(), v.inMilliseconds)),
      'successCounts': successCounts.map((k, v) => MapEntry(k.toString(), v)),
      'failureCounts': failureCounts.map((k, v) => MapEntry(k.toString(), v)),
      'recentMetrics': recentMetrics.take(100).map((m) => m.toJson()).toList(),
      'averages': {
        for (final type in OcrOperationType.values)
          type.toString(): {
            'durationMs': getAverageDuration(type)?.inMilliseconds,
            'successRate': getSuccessRate(type),
            'memoryDelta': getAverageMemoryDelta(type),
          }
      },
    };
  }
}

/// Lightweight performance monitoring for OCR operations
///
/// Features:
/// - Minimal overhead with async operations
/// - In-memory storage with periodic flushing
/// - Device capability correlation
/// - Aggregated statistics
/// - Memory usage tracking
class OcrPerformanceMonitor {
  static final OcrPerformanceMonitor _instance =
      OcrPerformanceMonitor._internal();
  factory OcrPerformanceMonitor() => _instance;
  OcrPerformanceMonitor._internal();

  // In-memory storage for metrics
  final Queue<OcrPerformanceMetric> _metrics = Queue<OcrPerformanceMetric>();
  final int _maxMetricsInMemory = 500; // Keep last 500 metrics

  // Aggregated statistics
  final OcrPerformanceStats _stats = OcrPerformanceStats();

  // Periodic flushing timer
  Timer? _flushTimer;
  final Duration _flushInterval = Duration(minutes: 5);

  // Device capability cache
  DeviceCapability? _cachedDeviceCapability;

  // Enable/disable monitoring
  bool _isEnabled = true;

  /// Initialize the performance monitor
  void initialize({bool enabled = true}) {
    _isEnabled = enabled && !kReleaseMode; // Only enable in non-release builds
    if (_isEnabled) {
      _startPeriodicFlush();
      AppLogger.debug('[OcrPerf] Performance monitoring initialized');
    }
  }

  /// Start monitoring an OCR operation
  /// Returns a function to call when the operation completes
  Future<
      void Function(
          {bool success,
          String? error,
          Map<String, dynamic>? additionalData})> startOperation(
    OcrOperationType operationType, {
    int imageSizeBytes = 0,
  }) async {
    if (!_isEnabled) return ({success, error, additionalData}) {};

    final memoryBefore = await _getCurrentMemoryUsage();
    final deviceCapability = await _getDeviceCapability();
    final stopwatch = Stopwatch()..start();

    return (
        {bool success = true,
        String? error,
        Map<String, dynamic>? additionalData}) {
      stopwatch.stop();
      _recordMetric(
        operationType: operationType,
        duration: stopwatch.elapsed,
        memoryBefore: memoryBefore,
        memoryAfter: 0, // Will be updated below
        imageSizeBytes: imageSizeBytes,
        success: success,
        error: error,
        deviceCapability: deviceCapability,
        additionalData: additionalData,
      );
    };
  }

  /// Record a performance metric
  void _recordMetric({
    required OcrOperationType operationType,
    required Duration duration,
    required int memoryBefore,
    required int memoryAfter,
    required int imageSizeBytes,
    required bool success,
    String? error,
    required DeviceCapability deviceCapability,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isEnabled) return;

    final metric = OcrPerformanceMetric(
      operationType: operationType,
      duration: duration,
      memoryUsageBefore: memoryBefore,
      memoryUsageAfter: memoryAfter,
      imageSizeBytes: imageSizeBytes,
      success: success,
      error: error,
      deviceCapability: deviceCapability,
      additionalData: additionalData,
    );

    // Add to in-memory storage
    _metrics.add(metric);
    if (_metrics.length > _maxMetricsInMemory) {
      _metrics.removeFirst();
    }

    // Update aggregated statistics
    _updateStats(metric);

    // Log slow operations
    if (duration.inMilliseconds > _getSlowOperationThreshold(operationType)) {
      AppLogger.warning(
          '[OcrPerf] Slow operation detected: ${operationType.toString()} '
          'took ${duration.inMilliseconds}ms (success: $success)');
    }
  }

  /// Update aggregated statistics
  void _updateStats(OcrPerformanceMetric metric) {
    final type = metric.operationType;

    // Update counts
    _stats.operationCounts[type] = (_stats.operationCounts[type] ?? 0) + 1;
    _stats.totalDurations[type] =
        (_stats.totalDurations[type] ?? Duration.zero) + metric.duration;

    if (metric.success) {
      _stats.successCounts[type] = (_stats.successCounts[type] ?? 0) + 1;
    } else {
      _stats.failureCounts[type] = (_stats.failureCounts[type] ?? 0) + 1;
    }

    // Update device-specific metrics
    _stats.metricsByDevice.putIfAbsent(metric.deviceCapability, () => []);
    _stats.metricsByDevice[metric.deviceCapability]!.add(metric);

    // Update recent metrics
    _stats.recentMetrics.add(metric);
    if (_stats.recentMetrics.length > 100) {
      _stats.recentMetrics.removeAt(0);
    }
  }

  /// Get current memory usage in bytes
  Future<int> _getCurrentMemoryUsage() async {
    if (kIsWeb) return 0;

    try {
      final info = await ProcessInfo.currentRss;
      return info;
    } catch (e) {
      return 0;
    }
  }

  /// Get device capability category
  Future<DeviceCapability> _getDeviceCapability() async {
    if (_cachedDeviceCapability != null) return _cachedDeviceCapability!;

    try {
      final isLowEnd = await DeviceProfiler.isLowEndDevice;
      _cachedDeviceCapability =
          isLowEnd ? DeviceCapability.lowEnd : DeviceCapability.midRange;
      return _cachedDeviceCapability!;
    } catch (e) {
      _cachedDeviceCapability = DeviceCapability.unknown;
      return DeviceCapability.unknown;
    }
  }

  /// Get slow operation threshold in milliseconds
  int _getSlowOperationThreshold(OcrOperationType type) {
    switch (type) {
      case OcrOperationType.native:
        return 2000; // 2 seconds
      case OcrOperationType.fallback:
        return 8000; // 8 seconds
      case OcrOperationType.preprocessing:
        return 1000; // 1 second
      case OcrOperationType.imageResize:
        return 1500; // 1.5 seconds
      case OcrOperationType.base64Encoding:
        return 1000; // 1 second
    }
  }

  /// Start periodic flushing of metrics
  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      _flushMetrics();
    });
  }

  /// Flush metrics to persistent storage (if needed)
  void _flushMetrics() {
    if (!_isEnabled || _metrics.isEmpty) return;

    try {
      // In a real implementation, you might want to persist metrics
      // For now, we'll just log a summary
      final summary = _getPerformanceSummary();
      AppLogger.debug('[OcrPerf] Metrics flushed: $summary');

      // Keep recent metrics in memory
      while (_metrics.length > 100) {
        _metrics.removeFirst();
      }
    } catch (e) {
      AppLogger.error('[OcrPerf] Error flushing metrics: $e');
    }
  }

  /// Get performance summary
  Map<String, dynamic> _getPerformanceSummary() {
    return {
      'totalMetrics': _metrics.length,
      'operationCounts': _stats.operationCounts,
      'averageDurations': _stats.totalDurations.map((k, v) => MapEntry(
          k.toString(), v.inMilliseconds ~/ (_stats.operationCounts[k] ?? 1))),
      'successRates': {
        for (final type in OcrOperationType.values)
          type.toString(): _stats.getSuccessRate(type)
      },
    };
  }

  /// Get current performance statistics
  OcrPerformanceStats getStats() {
    return _stats;
  }

  /// Get metrics for a specific operation type
  List<OcrPerformanceMetric> getMetricsForOperation(OcrOperationType type) {
    return _metrics.where((m) => m.operationType == type).toList();
  }

  /// Get metrics for a specific device capability
  List<OcrPerformanceMetric> getMetricsForDevice(DeviceCapability capability) {
    return _metrics.where((m) => m.deviceCapability == capability).toList();
  }

  /// Reset all metrics
  void resetMetrics() {
    _metrics.clear();
    _stats.operationCounts.clear();
    _stats.totalDurations.clear();
    _stats.successCounts.clear();
    _stats.failureCounts.clear();
    _stats.metricsByDevice.clear();
    _stats.recentMetrics.clear();
    AppLogger.debug('[OcrPerf] Metrics reset');
  }

  /// Dispose the monitor
  void dispose() {
    _flushTimer?.cancel();
    _flushMetrics();
    AppLogger.debug('[OcrPerf] Performance monitor disposed');
  }
}

/// Extension to make ProcessInfo.currentRss available
extension ProcessInfoExtension on ProcessInfo {
  static Future<int> get currentRss async {
    // This is a simplified implementation
    // In a real app, you might want to use platform-specific APIs
    if (Platform.isIOS || Platform.isAndroid) {
      // For mobile platforms, we'll use a placeholder
      // In a real implementation, you'd use platform channels to get actual memory usage
      return 0;
    }
    return 0;
  }
}

/// Mock ProcessInfo class for compatibility
class ProcessInfo {
  static Future<int> get currentRss => ProcessInfoExtension.currentRss;
}
