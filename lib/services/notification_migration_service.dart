import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/fcm_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';

/// Service to handle one-time migration of notification settings
/// when users update from pre-FCM version (before 3.4.6) to FCM version.
///
/// This migration ensures that users who previously had notification permissions
/// automatically get the master notification toggle enabled after the update.
class NotificationMigrationService {
  static final NotificationMigrationService instance =
      NotificationMigrationService._internal();
  factory NotificationMigrationService() => instance;
  NotificationMigrationService._internal();

  static const String _migrationKey = 'notification_migration_completed';
  static const String _previousVersionKey = 'previous_app_version';
  static const String _targetVersion = '3.4.6'; // Migration target version

  /// Perform migration if needed
  ///
  /// This method should be called during app initialization.
  /// It will:
  /// 1. Check if migration was already completed
  /// 2. Compare current version with previous version
  /// 3. If updating from pre-FCM version, check notification permissions
  /// 4. If permissions are granted, enable master notification toggle
  /// 5. Mark migration as completed
  Future<void> performMigrationIfNeeded() async {
    try {
      AppLogger.debug('Starting notification migration check');

      // Check if migration was already completed
      final prefs = await SharedPreferences.getInstance();
      final migrationCompleted = prefs.getBool(_migrationKey) ?? false;

      if (migrationCompleted) {
        AppLogger.debug('Notification migration already completed');
        return;
      }

      // Get current and previous version information
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final previousVersionString = prefs.getString(_previousVersionKey);

      // Store current version for next launch
      await prefs.setString(_previousVersionKey, packageInfo.version);

      String? previousVersion = previousVersionString;
      if (previousVersion == null) {
        // If no previous version is stored, this could be a fresh install
        // or an update from a very old version that didn't store this info
        AppLogger.debug('No previous version found, assuming pre-FCM version');
        previousVersion = '0.0.0';
      }

      AppLogger.debug(
          'Version check - Previous: $previousVersion, Current: $currentVersion, Target: $_targetVersion');

      // Check if this is an update from pre-FCM version
      final isUpdatingFromPreFCM =
          _isVersionLessThan(previousVersion, _targetVersion) &&
              !_isVersionLessThan(currentVersion, _targetVersion);

      if (!isUpdatingFromPreFCM) {
        AppLogger.debug(
            'Not updating from pre-FCM version, skipping migration');
        // Mark as completed to avoid re-checking
        await prefs.setBool(_migrationKey, true);
        return;
      }

      AppLogger.info(
          'Detected update from pre-FCM version, performing notification migration');

      // Initialize notification settings service if not already initialized
      await NotificationSettingsService.instance.init();

      // Check if user has notification permissions
      final hasPermissions = await FcmService().checkPermissionStatus();
      AppLogger.debug('User notification permission status: $hasPermissions');

      if (hasPermissions) {
        // Enable master notification toggle
        await NotificationSettingsService.instance.setMasterEnabled(true);
        AppLogger.info('Master notification toggle enabled due to migration');
      } else {
        AppLogger.debug(
            'User does not have notification permissions, leaving toggle disabled');
      }

      // Mark migration as completed
      await prefs.setBool(_migrationKey, true);
      AppLogger.info('Notification migration completed successfully');
    } catch (e) {
      AppLogger.error('Error during notification migration', errorObject: e);
      // Don't rethrow - migration failure should not crash the app
      // The migration will be attempted again on next launch
    }
  }

  /// Compare two version strings to check if first is less than second
  bool _isVersionLessThan(String version1, String version2) {
    try {
      final v1Parts =
          version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts =
          version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Ensure both lists have at least 3 elements
      while (v1Parts.length < 3) v1Parts.add(0);
      while (v2Parts.length < 3) v2Parts.add(0);

      // Compare major, minor, and patch versions
      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] < v2Parts[i]) {
          return true;
        } else if (v1Parts[i] > v2Parts[i]) {
          return false;
        }
      }
      return false; // Versions are equal
    } catch (e) {
      AppLogger.error('Error comparing versions: $version1 vs $version2',
          errorObject: e);
      return false;
    }
  }

  /// Check if migration has been completed
  ///
  /// This can be used for debugging or testing purposes
  Future<bool> isMigrationCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationKey) ?? false;
    } catch (e) {
      AppLogger.error('Error checking migration status', errorObject: e);
      return false;
    }
  }

  /// Reset migration status (for testing purposes only)
  ///
  /// This method should only be used in testing environments
  Future<void> resetMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationKey);
      AppLogger.debug('Migration status reset');
    } catch (e) {
      AppLogger.error('Error resetting migration status', errorObject: e);
    }
  }

  /// Get stored previous version
  Future<String?> getPreviousVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_previousVersionKey);
    } catch (e) {
      AppLogger.error('Error getting previous version', errorObject: e);
      return null;
    }
  }
}
