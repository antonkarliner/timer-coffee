import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Configuration for application logging
///
/// Sets up different log levels based on build mode
/// and configures output formatting
class LogConfig {
  static bool _isInitialized = false;

  /// Determines if the app is running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Determines if the app is running in release mode
  static bool get isReleaseMode => kReleaseMode;

  /// Determines if the app is running in profile mode
  static bool get isProfileMode => kProfileMode;

  /// Gets the appropriate log level based on the current build mode
  static Level get currentLogLevel {
    if (isDebugMode) {
      // Development: verbose logging
      return Level.ALL;
    } else if (isProfileMode) {
      // Profile: info and above for performance testing
      return Level.INFO;
    } else {
      // Production: only warnings and errors
      return Level.WARNING;
    }
  }

  /// Gets the appropriate log level for sensitive data based on build mode
  static Level get sensitiveDataLogLevel {
    if (isDebugMode) {
      // In debug mode, allow sensitive data logging at finest level
      return Level.FINEST;
    } else {
      // In production, never log sensitive data
      return Level.OFF;
    }
  }

  /// Checks if a log level should be output based on current configuration
  static bool shouldLog(Level level) {
    // In production, only allow warnings and errors
    if (isReleaseMode) {
      return level.value >= Level.WARNING.value;
    }
    return level.value >= currentLogLevel.value;
  }

  /// Checks if sensitive data should be logged based on current configuration
  static bool shouldLogSensitiveData() {
    return sensitiveDataLogLevel != Level.OFF;
  }

  /// Initializes the logging system with appropriate settings
  ///
  /// In debug mode: verbose logging for development
  /// In profile mode: info and above for performance testing
  /// In release mode: only warnings and errors for production
  static void initialize() {
    if (_isInitialized) {
      return; // Prevent multiple initializations
    }

    // Set the root logger level based on build mode
    Logger.root.level = currentLogLevel;

    // Configure output format with timestamp and level
    Logger.root.onRecord.listen((record) {
      // Only output if the record level meets our threshold
      if (shouldLog(record.level)) {
        // Format: [TIMESTAMP] [LEVEL] [MESSAGE]
        print(
            '${record.time.toIso8601String()}: ${record.level.name}: ${record.message}');
      }
    });

    _isInitialized = true;
  }

  /// Resets the logging configuration (useful for testing)
  static void reset() {
    _isInitialized = false;
    Logger.root.clearListeners();
  }
}
