import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/supported_locale_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/settings/settings_language_region_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_language_region_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>()])
void main() {
  late MockRecipeProvider recipeProvider;
  late DateTimeFormatService fmtService;

  // Fixed clock: the footer and the sheet examples format this instant, so a
  // minute boundary between the widget's build and an expectation can't flake
  // an exact match. Compute expected strings only after pumping — the
  // MaterialApp's material-localizations load is what initializes intl's date
  // symbols for the non-English locales.
  final fixedNow = DateTime(2026, 10, 2, 15, 41);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    recipeProvider = MockRecipeProvider();
    fmtService = DateTimeFormatService();
    SettingsLanguageRegionScreen.now = () => fixedNow;
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
    SettingsLanguageRegionScreen.now = DateTime.now;
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

  Future<void> pumpPage(
    WidgetTester tester, {
    String localeCode = 'en',
  }) async {
    await tester.pumpWidget(
      app(const SettingsLanguageRegionScreen(), localeCode: localeCode),
    );
    await tester.pumpAndSettle();
  }

  Future<AppLocalizations> loc(String localeCode) =>
      AppLocalizations.delegate.load(Locale(localeCode));

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
    // The old grey preview box is gone; the section footer replaces it.
    expect(find.byIcon(Icons.preview_outlined), findsNothing);
  });

  testWidgets('the Date & time section footer shows today and now in the '
      'chosen formats', (tester) async {
    await pumpPage(tester);

    final l10n = await loc('en');
    // Both styles are on Automatic by default, so the footer uses the
    // English locale pattern and the device's 12-hour clock (tests default
    // to alwaysUse24HourFormat: false).
    final expectedDate = DateFormat(l10n.dateFormat, 'en').format(fixedNow);
    final expectedTime = DateFormat('hh:mm a', 'en').format(fixedNow);
    expect(
      find.text(l10n.settingsDateTimeToday(expectedDate, expectedTime)),
      findsOneWidget,
    );
  });

  testWidgets('the Automatic options say where their format comes from',
      (tester) async {
    await pumpPage(tester);

    final l10n = await loc('en');
    final expectedDateExample =
        DateFormat(l10n.dateFormat, 'en').format(fixedNow);

    await tester.tap(find.bySemanticsIdentifier('settingsDateFormatTile'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(
        find.textContaining(l10n.settingsAutoMatchesLanguage),
      ).data,
      '${l10n.settingsAutoMatchesLanguage} · $expectedDateExample',
    );

    // Close the sheet by picking the already-current value (no change, no
    // event) before opening the time sheet.
    await tester.tap(find.bySemanticsIdentifier('dateFormatAutoListTile'));
    await tester.pumpAndSettle();

    final expectedTimeExample = DateFormat('hh:mm a', 'en').format(fixedNow);
    await tester.tap(find.bySemanticsIdentifier('settingsTimeFormatTile'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(
        find.textContaining(l10n.settingsAutoMatchesDevice),
      ).data,
      '${l10n.settingsAutoMatchesDevice} · $expectedTimeExample',
    );
  });

  testWidgets('under a German locale the sheet example and footer use German '
      'month names', (tester) async {
    await pumpPage(tester, localeCode: 'de');

    final l10nDe = await loc('de');
    // Automatic follows the app language, so its pattern is the German
    // locale default; expected value computed with DateFormat(pattern, 'de'),
    // so a missing locale argument (English month names) fails this test.
    final expectedDateExample =
        DateFormat(l10nDe.dateFormat, 'de').format(fixedNow);
    final expectedTime = DateFormat('hh:mm a', 'de').format(fixedNow);

    expect(
      find.text(
        l10nDe.settingsDateTimeToday(expectedDateExample, expectedTime),
      ),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsIdentifier('settingsDateFormatTile'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '${l10nDe.settingsAutoMatchesLanguage} · $expectedDateExample',
      ),
      findsOneWidget,
    );
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
