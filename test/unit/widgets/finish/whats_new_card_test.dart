// Tests for the finish-screen "what's new" card (plan 039, Item C, Phase
// C2). Covers: render-gated impression bookkeeping (independent finish-only
// seen-state key + engagement-budget recording), the three analytics events
// with `source_screen: 'finish'`, and that both are consistent with the
// home popup's naming (`launch_popup.dart`, C1).

import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/engagement_budget_service.dart';
import 'package:coffee_timer/widgets/finish/whats_new_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LaunchPopupModel _makePopup({
  int id = 42,
  String content = "What's new in this release.",
  String platform = 'all',
}) {
  return LaunchPopupModel(
    id: id,
    content: content,
    locale: 'en',
    createdAt: DateTime.utc(2026, 1, 1),
    platform: platform,
  );
}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  late SharedPreferences prefs;
  late EngagementBudgetService budget;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    budget = EngagementBudgetService(prefs: prefs);
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
      if (call.method == 'canLaunch') return false;
      if (call.method == 'launch') return true;
      return null;
    });
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  testWidgets('popup_shown fires on first frame with source_screen finish', (
    tester,
  ) async {
    final popup = _makePopup(id: 7);

    await tester.pumpWidget(
      _host(
        WhatsNewCard(
          popup: popup,
          locale: 'en',
          budgetService: budget,
          prefs: prefs,
        ),
      ),
    );
    await tester.pump();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final shown = events.firstWhere((e) => e['event_name'] == 'popup_shown');
    expect(shown['properties']['popup_id'], 7);
    expect(shown['properties']['source_screen'], 'finish');
    expect(shown['properties']['locale'], 'en');
  });

  testWidgets(
      'first frame writes the independent finish-only seen-state key, not '
      'the home key', (tester) async {
    final popup = _makePopup(id: 8);

    await tester.pumpWidget(
      _host(
        WhatsNewCard(
          popup: popup,
          locale: 'en',
          budgetService: budget,
          prefs: prefs,
        ),
      ),
    );
    await tester.pump();

    expect(prefs.getInt('lastPopupIdSeenAtFinish_en'), 8);
    // Home's own seen-state key must be completely untouched by this card.
    expect(prefs.getInt('lastPopupId_en'), isNull);
  });

  testWidgets(
      'first frame records a finish_popup budget entry keyed by the popup id',
      (tester) async {
    final popup = _makePopup(id: 21);

    await tester.pumpWidget(
      _host(
        WhatsNewCard(
          popup: popup,
          locale: 'en',
          budgetService: budget,
          prefs: prefs,
        ),
      ),
    );
    await tester.pump();

    final raw = prefs.getString('engagement_budget_log');
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as List;
    final entry = decoded.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['surface'] == 'finish_popup' && e['askId'] == '21',
        );
    expect(entry, isNotNull);
  });

  testWidgets('tapping the card and then Close emits popup_dismissed with '
      'dismiss_method close', (tester) async {
    final popup = _makePopup(id: 9);

    await tester.pumpWidget(
      _host(
        WhatsNewCard(
          popup: popup,
          locale: 'en',
          budgetService: budget,
          prefs: prefs,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final dismissed =
        events.firstWhere((e) => e['event_name'] == 'popup_dismissed');
    expect(dismissed['properties']['popup_id'], 9);
    expect(dismissed['properties']['source_screen'], 'finish');
    expect(dismissed['properties']['dismiss_method'], 'close');
  });

  testWidgets(
      'dismissing the expanded view via the barrier emits dismiss_method '
      'barrier_or_back', (tester) async {
    final popup = _makePopup(id: 11);

    await tester.pumpWidget(
      _host(
        WhatsNewCard(
          popup: popup,
          locale: 'en',
          budgetService: budget,
          prefs: prefs,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final dismissed =
        events.firstWhere((e) => e['event_name'] == 'popup_dismissed');
    expect(dismissed['properties']['popup_id'], 11);
    expect(dismissed['properties']['dismiss_method'], 'barrier_or_back');
  });

  testWidgets(
      'tapping a link inside the expanded view emits popup_link_tapped with '
      'source_screen finish', (tester) async {
    final popup = _makePopup(
      id: 13,
      content: '[Learn more](https://timer.coffee)',
    );

    await tester.pumpWidget(
      _host(
        WhatsNewCard(
          popup: popup,
          locale: 'en',
          budgetService: budget,
          prefs: prefs,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final tapped =
        events.firstWhere((e) => e['event_name'] == 'popup_link_tapped');
    expect(tapped['properties']['popup_id'], 13);
    expect(tapped['properties']['source_screen'], 'finish');
    expect(tapped['properties']['href_type'], 'external');
  });
}
