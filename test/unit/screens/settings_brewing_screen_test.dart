import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/notification_mode.dart';
import 'package:coffee_timer/screens/settings/settings_brewing_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/brew_alert_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AdvancedFeaturesService advanced;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    BrewAlertPreference.instance.resetForTesting();
    advanced = AdvancedFeaturesService();
    await advanced.init();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
    advanced.dispose();
  });

  List<Map<String, dynamic>> eventsNamed(String name) => AnalyticsService
      .instance
      .bufferedEventsForTesting
      .where((event) => event['event_name'] == name)
      .toList();

  Widget app(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AdvancedFeaturesService>.value(value: advanced),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(app(const SettingsBrewingScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders layout, manual step control and brew alerts', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Brewing'), findsOneWidget);
    // Only the choice-row title: a section header would repeat it verbatim.
    expect(find.text('Brewing screen'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('settingsBrewingLayoutTile'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsManualStepControlSwitch'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsBrewAlertsTile'),
      findsOneWidget,
    );
    // Stored default is none → "Silent" as the current value.
    expect(find.text('Silent'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(eventsNamed('setting_changed'), isEmpty);
  });

  testWidgets(
    'choosing Classic while immersive is on calls through and shows the switch-back reason row',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AdvancedFeaturesService.kPourLayoutKey: true,
      });
      advanced = AdvancedFeaturesService();
      await advanced.init();
      expect(advanced.pourLayoutEnabled, isTrue);

      await pumpPage(tester);
      expect(
        find.bySemanticsIdentifier('layoutSwitchBackReasonRow'),
        findsNothing,
      );

      await tester.tap(find.bySemanticsIdentifier('settingsBrewingLayoutTile'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('layoutClassicListTile'));
      await tester.pumpAndSettle();

      expect(advanced.pourLayoutEnabled, isFalse);
      expect(
        find.bySemanticsIdentifier('layoutSwitchBackReasonRow'),
        findsOneWidget,
      );
      // The layout row emits only the beta_feature_toggled that
      // setPourLayoutEnabled emits itself — no setting_changed.
      expect(eventsNamed('setting_changed'), isEmpty);
      final toggles = eventsNamed('beta_feature_toggled');
      expect(toggles, hasLength(1));
      expect(toggles.single['properties'], {
        'feature': 'pour_layout',
        'enabled': false,
        'source': 'settings',
      });
    },
  );

  testWidgets(
    'manual step switch toggles the service and emits one beta_feature_toggled',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(
        find.bySemanticsIdentifier('settingsManualStepControlSwitch'),
      );
      await tester.pumpAndSettle();

      expect(advanced.manualStepControlEnabled, isTrue);
      final toggles = eventsNamed('beta_feature_toggled');
      expect(toggles, hasLength(1));
      expect(toggles.single['properties'], {
        'feature': 'manual_step_control',
        'enabled': true,
        'source': 'settings',
      });
      expect(eventsNamed('setting_changed'), isEmpty);
    },
  );

  testWidgets(
    'choosing Vibration persists notificationMode=1 and emits one setting_changed',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.bySemanticsIdentifier('settingsBrewAlertsTile'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsIdentifier('brewAlertVibrationListTile'),
      );
      await tester.pumpAndSettle();

      expect(
        BrewAlertPreference.instance.mode.value,
        NotificationMode.vibrationOnly,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('notificationMode'), 1);
      final events = eventsNamed('setting_changed');
      expect(events, hasLength(1));
      expect(events.single['properties'], {
        'key': 'brew_alerts',
        'value': 'vibration',
        'previous': 'silent',
        'source': 'settings',
      });
    },
  );

  testWidgets('choosing the current brew-alert value emits nothing', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsBrewAlertsTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('brewAlertSilentListTile'));
    await tester.pumpAndSettle();

    expect(eventsNamed('setting_changed'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('notificationMode'), isFalse);
  });
}
