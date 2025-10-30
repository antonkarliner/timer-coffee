import 'dart:async';
import 'dart:io';
import 'package:coffee_timer/services/ocr/ocr_service.dart';
import 'package:coffee_timer/services/clients/beans_label_parser_client.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/ocr_performance_monitor.dart';
import 'package:coffee_timer/utils/ocr_performance_history.dart';

/// Result of an OCR attempt with metadata
class OcrResult {
  final String text;
  final OcrFallbackStrategy strategy;
  final int attemptCount;
  final Duration duration;
  final String? error;

  OcrResult({
    required this.text,
    required this.strategy,
    required this.attemptCount,
    required this.duration,
    this.error,
  });

  bool get isSuccess => text.isNotEmpty && error == null;
}

/// Types of fallback strategies for OCR
enum OcrFallbackStrategy {
  native, // Native on-device OCR
  retry, // Retry native OCR with exponential backoff
}

/// Metrics for tracking fallback usage
class OcrFallbackMetrics {
  int nativeAttempts = 0;
  int nativeSuccesses = 0;
  int retryAttempts = 0;
  int retrySuccesses = 0;
  int totalAttempts = 0;
  int totalSuccesses = 0;
  final List<Map<String, dynamic>> decisionLog = [];

  void recordAttempt(OcrFallbackStrategy strategy, bool success,
      Duration duration, String? error) {
    totalAttempts++;

    switch (strategy) {
      case OcrFallbackStrategy.native:
        nativeAttempts++;
        if (success) nativeSuccesses++;
        break;
      case OcrFallbackStrategy.retry:
        retryAttempts++;
        if (success) retrySuccesses++;
        break;
    }

    if (success) totalSuccesses++;

    decisionLog.add({
      'timestamp': DateTime.now().toIso8601String(),
      'strategy': strategy.toString(),
      'success': success,
      'duration_ms': duration.inMilliseconds,
      'error': error,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'nativeAttempts': nativeAttempts,
      'nativeSuccesses': nativeSuccesses,
      'retryAttempts': retryAttempts,
      'retrySuccesses': retrySuccesses,
      'totalAttempts': totalAttempts,
      'totalSuccesses': totalSuccesses,
      'successRate':
          totalAttempts > 0 ? (totalSuccesses / totalAttempts) * 100 : 0,
      'decisionLog': decisionLog,
    };
  }
}

/// Handles OCR fallback strategies with retry logic (cloud fallback removed)
class OcrFallbackHandler {
  final OcrService _nativeOcrService;
  final BeansLabelParserClient _cloudClient;
  final OcrFallbackMetrics metrics = OcrFallbackMetrics();
  final OcrPerformanceMonitor _monitor = OcrPerformanceMonitor();
  final OcrPerformanceHistory _history = OcrPerformanceHistory.instance;

  // Configuration
  final int maxRetryAttempts;
  final List<int> retryDelaysMs; // Exponential backoff delays in milliseconds

  OcrFallbackHandler({
    required OcrService nativeOcrService,
    required BeansLabelParserClient cloudClient,
    this.maxRetryAttempts = 3,
    this.retryDelaysMs = const [1000, 2000, 4000], // 1s, 2s, 4s
  })  : _nativeOcrService = nativeOcrService,
        _cloudClient = cloudClient {
    // Initialize performance monitoring
    _monitor.initialize();
    // Initialize performance history
    _history.initialize();
  }

  /// Central logging for this handler
  void _log(String msg) {
    AppLogger.debug('[OcrFallback] $msg');
  }

  /// Attempt OCR with fallback strategies (native only, no cloud fallback)
  /// Returns first successful result or last failed attempt
  Future<OcrResult> performOcrWithFallback({
    required File imageFile,
    required String locale,
    String? userId,
  }) async {
    _log('Starting OCR with native-only fallback strategies');

    // Strategy 1: Native OCR (first attempt)
    final nativeResult = await _attemptNativeOcr(imageFile, 1);
    if (nativeResult.isSuccess) {
      _log('Native OCR succeeded on first attempt');
      return nativeResult;
    }

    // Strategy 2: Retry with exponential backoff
    if (maxRetryAttempts > 1) {
      _log('Native OCR failed, attempting retry strategy');
      final retryResult = await _attemptRetryStrategy(imageFile);
      if (retryResult.isSuccess) {
        _log('Retry strategy succeeded');
        return retryResult;
      }
    }

    _log('All native OCR strategies exhausted');
    return OcrResult(
      text: '',
      strategy: OcrFallbackStrategy.retry,
      attemptCount: maxRetryAttempts,
      duration: Duration.zero,
      error: 'All native OCR strategies failed',
    );
  }

  /// Attempt native OCR
  Future<OcrResult> _attemptNativeOcr(File imageFile, int attemptCount) async {
    // Get image file size for monitoring
    final fileSize = await imageFile.length();

    // Start performance monitoring
    final endMonitoring = await _monitor.startOperation(
      OcrOperationType.native,
      imageSizeBytes: fileSize,
    );

    final stopwatch = Stopwatch()..start();
    String? error;
    String text = '';

    try {
      _log('Attempting native OCR (attempt $attemptCount)');
      text = await _nativeOcrService.recognizeText(imageFile);
      _log('Native OCR completed: ${text.length} characters recognized');
    } catch (e) {
      error = e.toString();
      _log('Native OCR failed: $error');
    }

    stopwatch.stop();
    final result = OcrResult(
      text: text,
      strategy: OcrFallbackStrategy.native,
      attemptCount: attemptCount,
      duration: stopwatch.elapsed,
      error: error,
    );

    metrics.recordAttempt(
        OcrFallbackStrategy.native, result.isSuccess, result.duration, error);

    // Record performance metric
    endMonitoring(
      success: result.isSuccess,
      error: error,
      additionalData: {
        'attemptCount': attemptCount,
        'textLength': text.length,
        'strategy': 'native',
      },
    );

    // Record in performance history for adaptive mode selection
    await _history.recordOperation(
      duration: result.duration,
      success: result.isSuccess,
      operationType: 'native',
      error: error,
    );

    return result;
  }

  /// Attempt retry strategy with exponential backoff
  Future<OcrResult> _attemptRetryStrategy(File imageFile) async {
    OcrResult lastResult = OcrResult(
      text: '',
      strategy: OcrFallbackStrategy.retry,
      attemptCount: 0,
      duration: Duration.zero,
      error: 'Retry not attempted',
    );

    for (int i = 0; i < maxRetryAttempts - 1; i++) {
      final attemptNumber = i + 2; // +2 because we already attempted once
      final delay = retryDelaysMs[
          i < retryDelaysMs.length ? i : retryDelaysMs.length - 1];

      if (delay > 0) {
        _log('Waiting ${delay}ms before retry attempt $attemptNumber');
        await Future.delayed(Duration(milliseconds: delay));
      }

      final result = await _attemptNativeOcr(imageFile, attemptNumber);
      lastResult = result;

      if (result.isSuccess) {
        // Update strategy to retry for successful attempts
        lastResult = OcrResult(
          text: result.text,
          strategy: OcrFallbackStrategy.retry,
          attemptCount: result.attemptCount,
          duration: result.duration,
          error: result.error,
        );
        metrics.recordAttempt(
            OcrFallbackStrategy.retry, true, result.duration, null);
        break;
      } else {
        metrics.recordAttempt(
            OcrFallbackStrategy.retry, false, result.duration, result.error);
      }
    }

    return lastResult;
  }

  /// Get metrics for debugging and analytics
  OcrFallbackMetrics getMetrics() {
    return metrics;
  }

  /// Reset metrics (useful for testing or new sessions)
  void resetMetrics() {
    metrics.nativeAttempts = 0;
    metrics.nativeSuccesses = 0;
    metrics.retryAttempts = 0;
    metrics.retrySuccesses = 0;
    metrics.totalAttempts = 0;
    metrics.totalSuccesses = 0;
    metrics.decisionLog.clear();
  }

  /// Get performance history instance
  OcrPerformanceHistory getPerformanceHistory() {
    return _history;
  }

  /// Get adaptive configuration
  OcrAdaptiveConfig getAdaptiveConfig() {
    return _history.config;
  }

  /// Update adaptive configuration
  Future<void> updateAdaptiveConfig(OcrAdaptiveConfig config) async {
    await _history.updateConfig(config);
    _log('Adaptive OCR configuration updated');
  }

  /// Reset performance history
  Future<void> resetPerformanceHistory() async {
    await _history.resetHistory();
    _log('Performance history reset');
  }

  /// Check if cloud mode is currently forced (always false now)
  bool isCloudModeForced() {
    return false; // Cloud mode is always disabled now
  }

  /// Manually force or unforce cloud mode (no-op now)
  Future<void> setForceCloudMode(bool force) async {
    _log('Cloud mode forcing is disabled - ignoring request to set to: $force');
  }
}
