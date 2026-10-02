import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/screens/settings/settings_notifications_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/widgets/settings/debug_notification_panel.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// Page test for SettingsNotificationsScreen.
///
/// In the test environment `NotificationService.initialize()` cannot run
/// (it needs localized channel copy and platform channels), so the
/// controller takes its catch path: master stays at its default (on) and
/// `isLoading` flips to false, which is exactly the state the page renders
/// here. Only the happy-path render and the reminder persistence are
/// asserted; the permission-denied flows need the real notification stack
/// and are covered on-device.
void main() {
  late AppDatabase database;
  late DateTimeFormatService dateTimeFormatService;
  late OnboardingService onboarding;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    database = openTestDatabase();
    dateTimeFormatService = DateTimeFormatService();
    onboarding = OnboardingService(prefs);
  });

  tearDown(() async {
    await database.close();
    dateTimeFormatService.dispose();
    onboarding.dispose();
  });

  Widget app() => MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<DateTimeFormatService>.value(
            value: dateTimeFormatService,
          ),
          ChangeNotifierProvider<OnboardingService>.value(value: onboarding),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SettingsNotificationsScreen(),
        ),
      );

  testWidgets('renders master switch, reminders header and all four toggles',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Notifications'), findsOneWidget);
    expect(
        find.bySemanticsIdentifier('settingsNotificationsMasterSwitch'),
        findsOneWidget);
    expect(find.text('Enable notifications'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    // Master switch + the four optional reminder switches.
    expect(find.byType(SettingsSwitchRow), findsNWidgets(5));
    expect(
        find.bySemanticsIdentifier('settingsMorningReminderSwitch'),
        findsOneWidget);
    expect(
        find.bySemanticsIdentifier('settingsWeeklySummarySwitch'),
        findsOneWidget);
    expect(
        find.bySemanticsIdentifier('settingsBeanFreshnessSwitch'),
        findsOneWidget);
    expect(
        find.bySemanticsIdentifier('settingsBeanReviewNudgeSwitch'),
        findsOneWidget);
    expect(find.text('Morning brew reminder'), findsOneWidget);
    expect(find.text('Weekly summary'), findsOneWidget);
    expect(find.text('Freshness reminders'), findsOneWidget);
    expect(find.text('Bean review reminders'), findsOneWidget);

    // With permission granted the warning row is hidden, so its semantics
    // identifier does not exist (an empty slot produces no semantics node).
    expect(find.bySemanticsIdentifier('notificationsPermissionBanner'),
        findsNothing);
    expect(find.text('Notifications are off in system settings'),
        findsNothing);

    // Debug builds render the debug panel slot.
    expect(find.byType(DebugNotificationPanel), findsOneWidget);
  });

  testWidgets('the Reminders header shows only while the reminders slot is '
      'visible', (tester) async {
    await tester.pumpWidget(app());

    // First frame: the controller is still loading, so the reminders slot
    // renders empty — no header, no reminder rows.
    expect(find.text('Reminders'), findsNothing);
    expect(find.byType(SettingsSwitchRow), findsOneWidget); // master only

    await tester.pumpAndSettle();

    // Loaded with notifications on (the test-environment default): the
    // header and the reminder rows appear.
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.byType(SettingsSwitchRow), findsNWidgets(5));
  });

  testWidgets('bean-review switch persists the off state', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Bean review reminders'));
    await tester.tap(find.text('Bean review reminders'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('notif_settings_bean_review_nudge'), isFalse);
  });
}
