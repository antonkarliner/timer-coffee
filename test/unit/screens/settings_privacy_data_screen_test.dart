import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/screens/settings/settings_privacy_data_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/settings/data_export_section.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecommendationClient extends Mock implements BeanRecommendationClient {
  int deleteCount = 0;
  BeanRecommendationStatus status = BeanRecommendationStatus.noSupply;
  bool generateFailed = false;

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async {
    if (generateFailed) throw StateError('offline');
    return status;
  }

  @override
  Future<void> deleteMine() async {
    deleteCount++;
  }
}

/// Retains the real persistence/notification behaviour while recording the
/// switch's calls (no Supabase or recommendation load is needed on this page).
class _RecommendationProvider extends RecommendationProvider {
  _RecommendationProvider({required super.client, required super.prefs})
    : super(
        currentUserId: () => 'user-1',
        featureFlagEnabled: () => true,
        countryCodeLookup: (_) async => null,
        clock: () => DateTime(2026, 11, 16, 19, 42),
      );

  final List<bool> optOutCalls = [];
  final List<String> refreshCalls = [];

  @override
  Future<void> refresh(String localeCode) {
    refreshCalls.add(localeCode);
    return super.refresh(localeCode);
  }

  @override
  Future<void> setOptedOut(bool value) {
    optOutCalls.add(value);
    return super.setOptedOut(value);
  }
}

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
    SettingsPrivacyDataScreen.forYouDebugOverride = null;
    AnalyticsService.resetForTesting();
    initialPrefs = const {};
    // rootBundle caches the policy's load future; one created in an earlier
    // test's fake-async zone never completes in the next, so the page would
    // spin forever.
    rootBundle.clear();
  });

  List<Map<String, dynamic>> allEvents() =>
      AnalyticsService.instance.bufferedEventsForTesting;

  List<Map<String, dynamic>> eventsNamed(String name) =>
      allEvents().where((event) => event['event_name'] == name).toList();

  Widget app({
    Locale locale = const Locale('en'),
    Map<String, bool> flags = const {},
    RecommendationProvider? recommendations,
  }) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AnalyticsService>.value(
        value: AnalyticsService.instance,
      ),
      Provider<Map<String, bool>>.value(value: flags),
      if (recommendations != null)
        ChangeNotifierProvider<RecommendationProvider>.value(
          value: recommendations,
        ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const SettingsPrivacyDataScreen(),
    ),
  );

  Finder suggestionsRow() => find.byWidgetPredicate(
    (widget) =>
        widget is SettingsSwitchRow &&
        widget.identifier == 'settingsBeanSuggestionsSwitch',
  );

  Future<(_RecommendationProvider, _RecommendationClient)> recommendations({
    bool optedOut = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(RecommendationProvider.optOutPrefKey, optedOut);
    final client = _RecommendationClient();
    final provider = _RecommendationProvider(client: client, prefs: prefs);
    addTearDown(provider.dispose);
    return (provider, client);
  }

  Finder debugRow() => find.byWidgetPredicate(
    (widget) =>
        widget is SettingsActionRow &&
        widget.identifier == 'settingsDebugRefreshSuggestions',
  );

  testWidgets('debug row absent by default even with feature flag on', (
    tester,
  ) async {
    final (provider, _) = await recommendations();
    await tester.pumpWidget(
      app(
        flags: {FeatureFlagKeys.beanRecommendations: true},
        recommendations: provider,
      ),
    );
    await tester.pumpAndSettle();
    expect(suggestionsRow(), findsOneWidget);
    expect(debugRow(), findsNothing);
  });

  testWidgets(
    'debug flag alone shows row below switch and tap refreshes locale',
    (tester) async {
      SettingsPrivacyDataScreen.forYouDebugOverride = true;
      final (provider, client) = await recommendations();
      await tester.pumpWidget(
        app(locale: const Locale('en', 'GB'), recommendations: provider),
      );
      await tester.pumpAndSettle();
      expect(debugRow(), findsOneWidget);
      expect(
        tester.widget<SettingsActionRow>(debugRow()).subtitle,
        'state: idle · reason: - · items: 0 · last: - -',
      );
      final section = tester.widget<SettingsSection>(
        find.ancestor(of: debugRow(), matching: find.byType(SettingsSection)),
      );
      final index = section.children.indexWhere(
        (row) => row is SettingsActionRow,
      );
      expect(
        (section.children[index - 1] as SettingsSwitchRow).identifier,
        'settingsBeanSuggestionsSwitch',
      );

      await tester.ensureVisible(debugRow());
      await tester.tap(find.text('Debug: refresh suggestions'));
      await tester.pumpAndSettle();
      // The app ships `en`, not `en_GB`: an en-GB device resolves to `en`,
      // and that resolved tag is what the screen must pass on.
      expect(provider.refreshCalls, ['en']);
      expect(
        tester.widget<SettingsActionRow>(debugRow()).subtitle,
        'state: hidden · reason: no_supply · items: 0 · last: no_supply 19:42',
      );

      client.status = BeanRecommendationStatus.insufficientHistory;
      await provider.refresh('en-GB');
      await tester.pumpAndSettle();
      expect(
        tester.widget<SettingsActionRow>(debugRow()).subtitle,
        'state: hidden · reason: insufficient_history · items: 0 · '
        'last: insufficient_history 19:42',
      );

      client.generateFailed = true;
      await provider.refresh('en-GB');
      await tester.pumpAndSettle();
      expect(
        tester.widget<SettingsActionRow>(debugRow()).subtitle,
        'state: hidden · reason: - · items: 0 · last: failed 19:42',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('suggestions switch reflects opt-out, persists toggles and '
      'reports enabled in the beans category', (tester) async {
    final (provider, client) = await recommendations();
    await tester.pumpWidget(
      app(
        flags: {FeatureFlagKeys.beanRecommendations: true},
        recommendations: provider,
      ),
    );
    await tester.pumpAndSettle();

    final row = tester.widget<SettingsSwitchRow>(suggestionsRow());
    final l10n = AppLocalizations.of(tester.element(suggestionsRow()))!;
    expect(row.title, l10n.forYouSettingTitle);
    expect(row.subtitle, l10n.forYouSettingSubtitle);
    expect(row.value, isTrue);
    expect(provider.optOutCalls, isEmpty);
    expect(eventsNamed('for_you_setting_toggled'), isEmpty);
    // Plan 017 phase 5d: the row moved into the usage-analytics section,
    // directly after the general-analytics row and before the footer note.
    final section = tester.widget<SettingsSection>(
      find.ancestor(
        of: suggestionsRow(),
        matching: find.byType(SettingsSection),
      ),
    );
    expect(section.header, l10n.settingsUsageAnalyticsHeader);
    expect(section.footer, l10n.settingsUsageAnalyticsFooter);
    final children = section.children
        .whereType<SettingsSwitchRow>()
        .toList(growable: false);
    expect(children, hasLength(4));
    expect(
      children.last.identifier,
      'settingsBeanSuggestionsSwitch',
      reason: 'the suggestions row is the section’s last row, i.e. '
          'rendered above the footer',
    );
    expect(
      children[children.length - 2].identifier,
      'settingsAnalyticsGeneralSwitch',
      reason: 'directly after "Share general usage analytics"',
    );

    await tester.ensureVisible(suggestionsRow());
    await tester.tap(find.text(l10n.forYouSettingTitle));
    await tester.pumpAndSettle();
    expect(provider.optOutCalls, [true]);
    expect(provider.optedOut, isTrue);
    expect(client.deleteCount, 1);
    expect(tester.widget<SettingsSwitchRow>(suggestionsRow()).value, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        RecommendationProvider.optOutPrefKey,
      ),
      isTrue,
    );

    await tester.tap(find.text(l10n.forYouSettingTitle));
    await tester.pumpAndSettle();
    expect(provider.optOutCalls, [true, false]);
    expect(provider.optedOut, isFalse);
    expect(tester.widget<SettingsSwitchRow>(suggestionsRow()).value, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        RecommendationProvider.optOutPrefKey,
      ),
      isFalse,
    );
    expect(eventsNamed('for_you_setting_toggled').map((e) => e['properties']), [
      {'enabled': false, 'source': 'settings'},
      {'enabled': true, 'source': 'settings'},
    ]);
    expect(
      eventsNamed('for_you_setting_toggled').map((e) => e['category']),
      everyElement('beans'),
    );
    expect(eventsNamed('setting_changed'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suggestions switch watches an initially stored opt-out', (
    tester,
  ) async {
    final (provider, _) = await recommendations(optedOut: true);
    await tester.pumpWidget(
      app(
        flags: {FeatureFlagKeys.beanRecommendations: true},
        recommendations: provider,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SettingsSwitchRow>(suggestionsRow()).value, isFalse);

    await provider.setOptedOut(false);
    await tester.pumpAndSettle();
    expect(tester.widget<SettingsSwitchRow>(suggestionsRow()).value, isTrue);
    expect(
      eventsNamed('for_you_setting_toggled'),
      isEmpty,
      reason: 'external preference changes are not switch taps',
    );
  });

  testWidgets('flag off hides suggestions and preserves existing data rows', (
    tester,
  ) async {
    final (provider, _) = await recommendations();
    await tester.pumpWidget(
      app(
        flags: {FeatureFlagKeys.beanRecommendations: true},
        recommendations: provider,
      ),
    );
    await tester.pumpAndSettle();
    final exportElement = tester.element(find.byType(DataExportSection));
    expect(suggestionsRow(), findsOneWidget);

    await tester.pumpWidget(
      app(
        flags: {FeatureFlagKeys.beanRecommendations: false},
        recommendations: provider,
      ),
    );
    await tester.pumpAndSettle();
    expect(suggestionsRow(), findsNothing);
    expect(find.byType(SettingsSwitchRow), findsNWidgets(3));
    expect(tester.element(find.byType(DataExportSection)), same(exportElement));
    expect(provider.optOutCalls, isEmpty);
    expect(allEvents(), isEmpty);
  });

  testWidgets('bean analytics opt-out suppresses suggestion toggle events', (
    tester,
  ) async {
    final (provider, client) = await recommendations();
    await AnalyticsService.instance.setBeansEnabled(false);
    await tester.pumpWidget(
      app(
        flags: {FeatureFlagKeys.beanRecommendations: true},
        recommendations: provider,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(suggestionsRow());
    final row = tester.widget<SettingsSwitchRow>(suggestionsRow());
    await tester.tap(find.text(row.title));
    await tester.pumpAndSettle();
    expect(provider.optedOut, isTrue);
    expect(client.deleteCount, 1);
    expect(allEvents(), isEmpty);
  });

  testWidgets('renders both sections, the three switches with their '
      'subtitles, the export row and the policy row', (tester) async {
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
    expect(find.byType(SettingsSwitchRow), findsNWidgets(3));
    expect(find.text('Share brewing analytics'), findsOneWidget);
    expect(find.text('Share bean analytics'), findsOneWidget);
    expect(find.text('Share general usage analytics'), findsOneWidget);
    // Each switch says what it controls.
    expect(
      find.text('Covers brews you start, finish, or log, and brew diary use'),
      findsOneWidget,
    );
    expect(
      find.text('Covers beans you add or remove, and bean reviews'),
      findsOneWidget,
    );
    expect(
      find.text('Covers screens, settings, and the rest of the app'),
      findsOneWidget,
    );
    // Section footer.
    expect(
      find.text('Anonymous: never your name, email, or account ID'),
      findsOneWidget,
    );

    expect(find.byType(DataExportSection), findsOneWidget);
    expect(find.bySemanticsIdentifier('dataExportListTile'), findsOneWidget);
    expect(find.text('Export your data'), findsOneWidget);
    // The export row is a grammar-v2 nav row carrying its subtitle.
    final exportRow = tester.widgetList<SettingsNavRow>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SettingsNavRow && widget.identifier == 'dataExportListTile',
      ),
    ).single;
    expect(exportRow.title, 'Export your data');
    expect(
      exportRow.subtitle,
      'Emails you a copy of your brews, beans, and recipes',
    );

    expect(
      find.bySemanticsIdentifier('settingsPrivacyPolicyRow'),
      findsOneWidget,
    );
    expect(find.text('Privacy policy'), findsOneWidget);
    // No decorative icons on page rows: the policy row has no leading icon.
    final policyRow = tester.widgetList<SettingsNavRow>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SettingsNavRow &&
            widget.identifier == 'settingsPrivacyPolicyRow',
      ),
    ).single;
    expect(policyRow.icon, isNull);
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

    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Markdown), findsOneWidget);
    final markdown = tester.widget<Markdown>(find.byType(Markdown));
    expect(markdown.data, startsWith('# Privacy Policy'));
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Privacy policy'),
      ),
      findsOneWidget,
    );

    // The sheet is the Help Center article style: the document h1 renders
    // with AppTextStyles.headline's size and weight. flutter_markdown emits
    // blocks as Text.rich, whose styled span sits under a root span carrying
    // the ambient style — so read the styled child span.
    final h1RichText = tester.widget<RichText>(
      find.text('Privacy Policy for Timer.Coffee', findRichText: true).first,
    );
    final h1Span =
        (h1RichText.text as TextSpan).children!.whereType<TextSpan>().single;
    expect(h1Span.style?.fontSize, AppTextStyles.headline.fontSize);
    expect(h1Span.style?.fontWeight, AppTextStyles.headline.fontWeight);
  });

  testWidgets('English policy stays LTR while the Persian app bar stays RTL', (
    tester,
  ) async {
    await tester.pumpWidget(app(locale: const Locale('fa')));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('settingsPrivacyPolicyRow'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Markdown), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Markdown))),
      TextDirection.ltr,
    );
    expect(
      Directionality.of(tester.element(find.byType(AppBar))),
      TextDirection.rtl,
    );
  });
}
