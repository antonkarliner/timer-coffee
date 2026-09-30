import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/supported_locale_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/settings/settings_language_region_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_language_region_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>()])
void main() {
  late MockRecipeProvider recipeProvider;
  late DateTimeFormatService fmtService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    recipeProvider = MockRecipeProvider();
    fmtService = DateTimeFormatService();
    when(recipeProvider.currentLocale).thenReturn(const Locale('en'));
    when(recipeProvider.fetchAllSupportedLocales()).thenAnswer(
      (_) async => [
        SupportedLocaleModel(locale: 'en', localeName: 'English'),
        SupportedLocaleModel(locale: 'de', localeName: 'Deutsch'),
      ],
    );
    when(recipeProvider.setLocale(any)).thenAnswer((_) async {});
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> settingChangedEvents() => AnalyticsService
      .instance.bufferedEventsForTesting
      .where((event) => event['event_name'] == 'setting_changed')
      .toList();

  Widget app(Widget child, {String localeCode = 'en'}) => MultiProvider(
        providers: [
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
          ChangeNotifierProvider<DateTimeFormatService>.value(
            value: fmtService,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(localeCode),
          home: child,
        ),
      );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(app(const SettingsLanguageRegionScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders language and date/time rows without exceptions',
      (tester) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Language & region'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsLangTile'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('settingsDateFormatTile'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsIdentifier('settingsTimeFormatTile'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.preview_outlined), findsOneWidget);
  });

  testWidgets('re-renders in the new language when the app locale changes, '
      'without a route replace', (tester) async {
    const page = SettingsLanguageRegionScreen();
    await tester.pumpWidget(app(page));
    await tester.pumpAndSettle();
    expect(find.text('Language & region'), findsOneWidget);

    // Same element, only MaterialApp's locale changes — exactly what happens
    // in the app when RecipeProvider.setLocale notifies (main.dart passes
    // currentLocale into MaterialApp.router with listen: true).
    await tester.pumpWidget(app(page, localeCode: 'de'));
    await tester.pumpAndSettle();

    expect(find.text('Sprache & Region'), findsOneWidget);
    expect(find.text('Datumsformat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'choosing a date format applies it and emits one setting_changed',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsDateFormatTile'));
    await tester.pumpAndSettle();

    // Each option shows today's date in that style as its subtitle.
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('dateFormatDmyListTile'),
        matching: find.textContaining(RegExp(r'^\d{2}/\d{2}/\d{4}$')),
      ),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsIdentifier('dateFormatDmyListTile'));
    await tester.pumpAndSettle();

    expect(fmtService.dateStyle, DateStyle.dmy);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'date_format',
      'value': 'dmy',
      'previous': 'auto',
      'source': 'settings',
    });
  });

  testWidgets('choosing the current date format emits nothing',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsDateFormatTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('dateFormatAutoListTile'));
    await tester.pumpAndSettle();

    expect(fmtService.dateStyle, DateStyle.auto);
    expect(settingChangedEvents(), isEmpty);
  });

  testWidgets('choosing a time format applies it and emits one setting_changed',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsTimeFormatTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('timeFormat24hListTile'));
    await tester.pumpAndSettle();

    expect(fmtService.timeStyle, TimeStyle.h24);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'time_format',
      'value': 'h24',
      'previous': 'auto',
      'source': 'settings',
    });
  });

  testWidgets('choosing a language persists it and calls setLocale',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsLangTile'));
    await tester.pumpAndSettle();
    // Identifier follows the `locale<code>ListTile` convention, so German
    // ('de') yields `localedeListTile`.
    await tester.tap(find.bySemanticsIdentifier('localedeListTile'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'de');
    verify(recipeProvider.setLocale(const Locale('de'))).called(1);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'language',
      'value': 'de',
      'previous': 'en',
      'source': 'settings',
    });
  });
}
