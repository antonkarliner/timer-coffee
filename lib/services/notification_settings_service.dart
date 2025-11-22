import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';

const String KEY_MASTER_ENABLED = 'notifications_master_enabled';

class NotificationSettingsService {
  static final NotificationSettingsService instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => instance;
  NotificationSettingsService._internal();

  SharedPreferences? _prefs;
  final BehaviorSubject<bool> _masterSubject =
      BehaviorSubject<bool>.seeded(false);

  Stream<bool> get masterChanges => _masterSubject.stream.distinct();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final current = _prefs!.getBool(KEY_MASTER_ENABLED) ?? false;
    _masterSubject.add(current);
  }

  Future<bool> isMasterEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(KEY_MASTER_ENABLED) ?? false;
  }

  Future<void> setMasterEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(KEY_MASTER_ENABLED, enabled);
    _masterSubject.add(enabled);
    AppLogger.debug('Master notification setting updated: $enabled');
  }

  void dispose() {
    _masterSubject.close();
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// Check if notification migration has been completed
  /// This method is used by the migration service to track completion status
  Future<bool> isMigrationCompleted() async {
    await _ensureInitialized();
    return _prefs!.getBool('notification_migration_completed') ?? false;
  }

  /// Mark notification migration as completed
  /// This method is used by the migration service to mark completion
  Future<void> setMigrationCompleted(bool completed) async {
    await _ensureInitialized();
    await _prefs!.setBool('notification_migration_completed', completed);
    AppLogger.debug(
        'Notification migration completion status updated: $completed');
  }
}
