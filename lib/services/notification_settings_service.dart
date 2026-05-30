import 'package:flutter/material.dart' show TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';

const String KEY_MASTER_ENABLED = 'notifications_master_enabled';
const String KEY_MORNING_REMINDER = 'notifications_morning_reminder_enabled';
const String KEY_MORNING_REMINDER_HOUR = 'notifications_morning_reminder_hour';
const String KEY_MORNING_REMINDER_MINUTE =
    'notifications_morning_reminder_minute';
const String KEY_WEEKLY_SUMMARY = 'notifications_weekly_summary_enabled';
const String KEY_BEAN_FRESHNESS = 'notifications_bean_freshness_enabled';
const String KEY_BEAN_REVIEW_NUDGE = 'notif_settings_bean_review_nudge';

class NotificationSettingsService {
  static final NotificationSettingsService instance =
      NotificationSettingsService._internal();
  factory NotificationSettingsService() => instance;
  NotificationSettingsService._internal();

  SharedPreferences? _prefs;
  final BehaviorSubject<bool> _masterSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _morningSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<TimeOfDay> _morningTimeSubject =
      BehaviorSubject<TimeOfDay>.seeded(const TimeOfDay(hour: 8, minute: 30));
  final BehaviorSubject<bool> _weeklySubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _beanFreshnessSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<bool> _beanReviewNudgeSubject =
      BehaviorSubject<bool>.seeded(true);

  Stream<bool> get masterChanges => _masterSubject.stream.distinct();
  Stream<bool> get morningChanges => _morningSubject.stream.distinct();
  Stream<TimeOfDay> get morningTimeChanges =>
      _morningTimeSubject.stream.distinct();
  Stream<bool> get weeklyChanges => _weeklySubject.stream.distinct();
  Stream<bool> get beanFreshnessChanges =>
      _beanFreshnessSubject.stream.distinct();
  Stream<bool> get beanReviewNudgeChanges =>
      _beanReviewNudgeSubject.stream.distinct();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _masterSubject.add(_prefs!.getBool(KEY_MASTER_ENABLED) ?? false);
    _morningSubject.add(_prefs!.getBool(KEY_MORNING_REMINDER) ?? false);
    _morningTimeSubject.add(TimeOfDay(
      hour: _prefs!.getInt(KEY_MORNING_REMINDER_HOUR) ?? 8,
      minute: _prefs!.getInt(KEY_MORNING_REMINDER_MINUTE) ?? 30,
    ));
    _weeklySubject.add(_prefs!.getBool(KEY_WEEKLY_SUMMARY) ?? false);
    _beanFreshnessSubject.add(_prefs!.getBool(KEY_BEAN_FRESHNESS) ?? false);
    _beanReviewNudgeSubject
        .add(_prefs!.getBool(KEY_BEAN_REVIEW_NUDGE) ?? true);
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

  Future<bool> isMorningReminderEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(KEY_MORNING_REMINDER) ?? false;
  }

  Future<void> setMorningReminderEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(KEY_MORNING_REMINDER, enabled);
    _morningSubject.add(enabled);
    AppLogger.debug('Morning reminder setting updated: $enabled');
  }

  Future<TimeOfDay> getMorningReminderTime() async {
    await _ensureInitialized();
    return TimeOfDay(
      hour: _prefs!.getInt(KEY_MORNING_REMINDER_HOUR) ?? 8,
      minute: _prefs!.getInt(KEY_MORNING_REMINDER_MINUTE) ?? 30,
    );
  }

  Future<void> setMorningReminderTime(TimeOfDay time) async {
    await _ensureInitialized();
    await _prefs!.setInt(KEY_MORNING_REMINDER_HOUR, time.hour);
    await _prefs!.setInt(KEY_MORNING_REMINDER_MINUTE, time.minute);
    _morningTimeSubject.add(time);
    AppLogger.debug(
        'Morning reminder time updated: ${time.hour}:${time.minute}');
  }

  Future<bool> isWeeklySummaryEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(KEY_WEEKLY_SUMMARY) ?? false;
  }

  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(KEY_WEEKLY_SUMMARY, enabled);
    _weeklySubject.add(enabled);
    AppLogger.debug('Weekly summary setting updated: $enabled');
  }

  Future<bool> isBeanFreshnessEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(KEY_BEAN_FRESHNESS) ?? false;
  }

  Future<void> setBeanFreshnessEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(KEY_BEAN_FRESHNESS, enabled);
    _beanFreshnessSubject.add(enabled);
    AppLogger.debug('Bean freshness setting updated: $enabled');
  }

  Future<bool> isBeanReviewNudgeEnabled() async {
    await _ensureInitialized();
    return _prefs!.getBool(KEY_BEAN_REVIEW_NUDGE) ?? true;
  }

  Future<void> setBeanReviewNudgeEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool(KEY_BEAN_REVIEW_NUDGE, enabled);
    _beanReviewNudgeSubject.add(enabled);
    AppLogger.debug('Bean review nudge setting updated: $enabled');
  }

  void dispose() {
    _masterSubject.close();
    _morningSubject.close();
    _morningTimeSubject.close();
    _weeklySubject.close();
    _beanFreshnessSubject.close();
    _beanReviewNudgeSubject.close();
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
