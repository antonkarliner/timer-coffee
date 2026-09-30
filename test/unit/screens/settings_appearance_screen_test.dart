import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/screens/settings/settings_appearance_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ThemeProvider themeProvider;
  late SnowEffectProvider snowProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    themeProvider = ThemeProvider(ThemeMode.light);
    snowProvider = SnowEffectProvider();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> settingChangedEvents() => AnalyticsService
      .instance.bufferedEventsForTesting
      .where((event) => event['event_name'] == 'setting_changed')
      .toList();

  Widget app(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SnowEffectProvider>.value(value: snowProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: child,
        ),
      );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(app(const SettingsAppearanceScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders theme and snow controls without exceptions',
      (tester) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsThemeTile'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsSnowSwitch'), findsOneWidget);
    // The icon API is unavailable in the test environment, so the whole
    // section (header included) stays hidden.
    expect(find.text('App Icon'), findsNothing);
    expect(find.bySemanticsIdentifier('appIconDefaultTile'), findsNothing);
    expect(find.bySemanticsIdentifier('appIconLegacyTile'), findsNothing);
  });

  testWidgets('choosing a theme applies it and emits one setting_changed',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsThemeTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('themeDarkListTile'));
    await tester.pumpAndSettle();

    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'theme',
      'value': 'dark',
      'previous': 'light',
      'source': 'settings',
    });
  });

  testWidgets('choosing the current theme emits nothing', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsThemeTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('themeLightListTile'));
    await tester.pumpAndSettle();

    expect(themeProvider.themeMode, ThemeMode.light);
    expect(settingChangedEvents(), isEmpty);
  });

  testWidgets('toggling snow updates the provider, persists and emits',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsSnowSwitch'));
    await tester.pumpAndSettle();

    expect(snowProvider.isSnowing, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('snow_effect_enabled'), isTrue);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'snow_effect',
      'value': 'on',
      'previous': 'off',
      'source': 'settings',
    });
  });
}
