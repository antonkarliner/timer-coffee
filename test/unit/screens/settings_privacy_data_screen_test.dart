import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/screens/settings/settings_privacy_data_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/widgets/app_switch_list_tile.dart';
import 'package:coffee_timer/widgets/settings/data_export_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Page test for SettingsPrivacyDataScreen (Settings → Privacy & data).
///
/// Uses a real [AnalyticsService] so the buffer assertions see exactly what
/// the switches emit. Product decision D6a is pinned here: the brews and
/// beans switches report `setting_changed`, the general switch must never
/// report anything in either direction, and with general analytics off the
/// category check drops even the brews/beans events.
void main() {
  // Read by setUp before AnalyticsService initializes (a plain-zone await:
  // PackageInfo.fromPlatform() never completes under testWidgets).
  var initialPrefs = const <String, Object>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
    initialPrefs = const {};
  });

  List<Map<String, dynamic>> allEvents() =>
      AnalyticsService.instance.bufferedEventsForTesting;

  List<Map<String, dynamic>> eventsNamed(String name) =>
      allEvents().where((event) => event['event_name'] == name).toList();

  Widget app() => ChangeNotifierProvider<AnalyticsService>.value(
    value: AnalyticsService.instance,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const SettingsPrivacyDataScreen(),
    ),
  );

  testWidgets('renders both headers, the three switches, the export row and '
      'the policy row', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Usage analytics'), findsOneWidget);
    expect(find.text('Your data'), findsOneWidget);

    expect(
      find.bySemanticsIdentifier('settingsAnalyticsBrewsSwitch'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsAnalyticsBeansSwitch'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsAnalyticsGeneralSwitch'),
      findsOneWidget,
    );
    expect(find.byType(AppSwitchListTile), findsNWidgets(3));
    expect(find.text('Share brewing analytics'), findsOneWidget);
    expect(find.text('Share bean analytics'), findsOneWidget);
    expect(find.text('Share general usage analytics'), findsOneWidget);

    expect(find.byType(DataExportSection), findsOneWidget);
    expect(find.bySemanticsIdentifier('dataExportListTile'), findsOneWidget);
    expect(find.text('Export my data'), findsOneWidget);

    expect(
      find.bySemanticsIdentifier('settingsPrivacyPolicyRow'),
      findsOneWidget,
    );
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(allEvents(), isEmpty);
  });

  testWidgets('toggling brews off emits exactly one setting_changed', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share brewing analytics'));
    await tester.pumpAndSettle();

    final events = eventsNamed('setting_changed');
    expect(events, hasLength(1));
    expect(events.single['properties'], {
      'key': 'analytics_brews',
      'value': 'off',
      'previous': 'on',
      'source': 'settings',
    });
  });

  testWidgets('toggling beans emits exactly one setting_changed', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share bean analytics'));
    await tester.pumpAndSettle();

    final events = eventsNamed('setting_changed');
    expect(events, hasLength(1));
    expect(events.single['properties'], {
      'key': 'analytics_beans',
      'value': 'off',
      'previous': 'on',
      'source': 'settings',
    });
  });

  testWidgets('toggling the general switch emits nothing in either direction', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // The switch itself must still work — it just must never report.
    await tester.tap(find.text('Share general usage analytics'));
    await tester.pumpAndSettle();
    expect(AnalyticsService.instance.generalEnabled, isFalse);

    await tester.tap(find.text('Share general usage analytics'));
    await tester.pumpAndSettle();
    expect(AnalyticsService.instance.generalEnabled, isTrue);

    expect(allEvents(), isEmpty);
    expect(jsonEncode(allEvents()), isNot(contains('analytics_general')));
  });

  testWidgets('with general analytics off, toggling brews buffers nothing', (
    tester,
  ) async {
    await AnalyticsService.instance.setGeneralEnabled(false);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share brewing analytics'));
    await tester.pumpAndSettle();

    // `setting_changed` is category `general`, so the service's own category
    // check drops it — intended (product decision D6a), not worked around.
    expect(AnalyticsService.instance.brewsEnabled, isFalse);
    expect(allEvents(), isEmpty);
  });

  testWidgets('tapping the policy row pushes a page showing the bundled '
      'markdown document', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Markdown), findsOneWidget);
    final markdown = tester.widget<Markdown>(find.byType(Markdown));
    expect(markdown.data, startsWith('# Privacy Policy'));
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Privacy Policy'),
      ),
      findsOneWidget,
    );
  });
}
