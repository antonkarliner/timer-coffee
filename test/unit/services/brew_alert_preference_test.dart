import 'package:coffee_timer/models/notification_mode.dart';
import 'package:coffee_timer/services/brew_alert_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BrewAlertPreference.instance.resetForTesting();
  });

  test('defaults to none when nothing is stored', () async {
    await BrewAlertPreference.instance.load();

    expect(BrewAlertPreference.instance.mode.value, NotificationMode.none);
  });

  test('load reads stored values 0, 1 and 2', () async {
    final stored = {
      0: NotificationMode.none,
      1: NotificationMode.vibrationOnly,
      2: NotificationMode.soundOnly,
    };

    for (final entry in stored.entries) {
      SharedPreferences.setMockInitialValues({'notificationMode': entry.key});
      await BrewAlertPreference.instance.load();

      expect(
        BrewAlertPreference.instance.mode.value,
        entry.value,
        reason: 'stored ${entry.key} should load as ${entry.value}',
      );
    }
  });

  test(
    'set persists the same int under notificationMode and notifies',
    () async {
      await BrewAlertPreference.instance.load();

      var notifications = 0;
      void listener() => notifications++;
      BrewAlertPreference.instance.mode.addListener(listener);
      addTearDown(
        () => BrewAlertPreference.instance.mode.removeListener(listener),
      );

      await BrewAlertPreference.instance.set(NotificationMode.vibrationOnly);

      expect(
        BrewAlertPreference.instance.mode.value,
        NotificationMode.vibrationOnly,
      );
      expect(notifications, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('notificationMode'), 1);

      await BrewAlertPreference.instance.set(NotificationMode.soundOnly);
      expect(
        (await SharedPreferences.getInstance()).getInt('notificationMode'),
        2,
      );
      expect(notifications, 2);
    },
  );

  test('set is a no-op when the mode is unchanged', () async {
    SharedPreferences.setMockInitialValues({'notificationMode': 2});
    await BrewAlertPreference.instance.load();

    var notifications = 0;
    void listener() => notifications++;
    BrewAlertPreference.instance.mode.addListener(listener);
    addTearDown(
      () => BrewAlertPreference.instance.mode.removeListener(listener),
    );

    await BrewAlertPreference.instance.set(NotificationMode.soundOnly);

    expect(notifications, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('notificationMode'), 2);
  });

  // Behavioural check only: with the mock store the set's write lands before
  // the load reads, so this passes with or without the `_setCount` guard. The
  // guard covers the opposite ordering, which the mock cannot produce.
  test('a set made while a load is in flight is not overwritten', () async {
    SharedPreferences.setMockInitialValues({'notificationMode': 2});

    final loading = BrewAlertPreference.instance.load();
    await BrewAlertPreference.instance.set(NotificationMode.vibrationOnly);
    await loading;

    expect(
      BrewAlertPreference.instance.mode.value,
      NotificationMode.vibrationOnly,
    );
  });

  test('wire names match the analytics vocabulary', () {
    expect(NotificationMode.none.wireName, 'silent');
    expect(NotificationMode.vibrationOnly.wireName, 'vibration');
    expect(NotificationMode.soundOnly.wireName, 'sound');
  });
}
