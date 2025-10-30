import 'dart:io';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Lightweight device capability profiler for OCR optimization
/// Uses device_info_plus package for accurate device detection
class DeviceProfiler {
  static bool? _isLowEndDeviceCache;
  static bool? _isInitializedCache;
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Detects if the current device is considered low-end for OCR processing
  /// Uses simple heuristics based on platform and OS version
  /// Results are cached to avoid repeated checks
  static Future<bool> get isLowEndDevice async {
    // Return cached result if already determined
    if (_isInitializedCache == true) {
      return _isLowEndDeviceCache ?? false;
    }

    // Initialize and cache the result
    _isInitializedCache = true;
    _isLowEndDeviceCache = await _detectLowEndDevice();

    // Log the detection result for debugging
    if (_isLowEndDeviceCache!) {
      AppLogger.debug(
          '[DeviceProfiler] Detected low-end device, OCR will be optimized');
    } else {
      AppLogger.debug(
          '[DeviceProfiler] Detected capable device, full OCR enabled');
    }

    return _isLowEndDeviceCache!;
  }

  /// Internal method to perform the actual device detection
  /// Uses platform-specific heuristics with device_info_plus
  static Future<bool> _detectLowEndDevice() async {
    try {
      if (Platform.isIOS) {
        // For iOS: Consider devices with iOS 15 and below as low-end
        final IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        final String systemVersion = iosInfo.systemVersion;
        final int majorVersion = _parseMajorVersion(systemVersion);

        // iOS 15 and below are considered low-end
        final bool isLowEnd = majorVersion <= 15;

        AppLogger.debug(
            '[DeviceProfiler] iOS version: $systemVersion (major: $majorVersion), low-end: $isLowEnd');
        return isLowEnd;
      } else if (Platform.isAndroid) {
        // For Android: Check API level for older versions
        // API level 28 (Android 9) and below are considered low-end
        final AndroidDeviceInfo androidInfo =
            await _deviceInfoPlugin.androidInfo;
        final int apiLevel = androidInfo.version.sdkInt;

        // API level 28 and below are considered low-end
        final bool isLowEnd = apiLevel <= 28;

        AppLogger.debug(
            '[DeviceProfiler] Android API level: $apiLevel, low-end: $isLowEnd');
        return isLowEnd;
      }

      // For other platforms (web, desktop), default to capable
      AppLogger.debug(
          '[DeviceProfiler] Non-mobile platform detected, defaulting to capable');
      return false;
    } catch (e) {
      // If detection fails, log error and default to capable
      AppLogger.debug(
          '[DeviceProfiler] Error detecting device capabilities: $e');
      return false;
    }
  }

  /// Parse major version number from iOS version string
  /// Example: "15.7.1" -> 15
  static int _parseMajorVersion(String versionString) {
    try {
      final parts = versionString.split('.');
      if (parts.isNotEmpty) {
        return int.tryParse(parts.first) ?? 0;
      }
      return 0;
    } catch (e) {
      AppLogger.debug(
          '[DeviceProfiler] Error parsing iOS version: $versionString, error: $e');
      return 0;
    }
  }

  /// Reset the cached detection (useful for testing)
  static void resetCache() {
    _isInitializedCache = null;
    _isLowEndDeviceCache = null;
  }
}
