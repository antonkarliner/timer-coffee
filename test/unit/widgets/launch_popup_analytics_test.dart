// Tests for the launch popup's analytics instrumentation and engagement
// budget recording (plan 039, Item C, Phase C1). No visible UI change is in
// scope for this phase — these tests cover the three new analytics events
// (popup_shown, popup_dismissed, popup_link_tapped) and the `home_popup`
// budget write, while leaving seen-state semantics untouched.

import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LaunchPopupModel _makePopup({
  int id = 42,
  String content = "What's new in this release.",
}) {
  return LaunchPopupModel(
    id: id,
    content: content,
    locale: 'en',
    createdAt: DateTime.utc(2026, 1, 1),
    platform: 'all',
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

  setUp(() async {
    LaunchPopupWidget.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'launch_popup_first_session_done': true,
    });
    final prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);

    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
      if (call.method == 'canLaunch') return false;
      if (call.method == 'launch') return true;
      return null;
    });
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  testWidgets('popup_shown fires with popup_id, source_screen, locale', (
    tester,
  ) async {
    final popup = _makePopup(id: 7);

    await tester.pumpWidget(
      _host(
        LaunchPopupWidget(
          fetchPopupOverride: (context, locale) async => popup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final shown = events.firstWhere((e) => e['event_name'] == 'popup_shown');
    expect(shown['properties']['popup_id'], 7);
    expect(shown['properties']['source_screen'], 'home');
    expect(shown['properties']['locale'], 'en');
  });

  testWidgets('tapping Close emits popup_dismissed with dismiss_method close', (
    tester,
  ) async {
    final popup = _makePopup(id: 9);

    await tester.pumpWidget(
      _host(
        LaunchPopupWidget(
          fetchPopupOverride: (context, locale) async => popup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final dismissed =
        events.firstWhere((e) => e['event_name'] == 'popup_dismissed');
    expect(dismissed['properties']['popup_id'], 9);
    expect(dismissed['properties']['source_screen'], 'home');
    expect(dismissed['properties']['dismiss_method'], 'close');

    // Seen-state must still be written by the Close button.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('lastPopupId_en'), 9);
  });

  testWidgets(
      'dismissing via the barrier emits popup_dismissed with dismiss_method barrier_or_back',
      (tester) async {
    final popup = _makePopup(id: 11);

    await tester.pumpWidget(
      _host(
        LaunchPopupWidget(
          fetchPopupOverride: (context, locale) async => popup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the modal barrier (outside the dialog content) to dismiss without
    // using the Close button.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final dismissed =
        events.firstWhere((e) => e['event_name'] == 'popup_dismissed');
    expect(dismissed['properties']['popup_id'], 11);
    expect(dismissed['properties']['dismiss_method'], 'barrier_or_back');

    // Seen-state must NOT be written when dismissed via the barrier.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('lastPopupId_en'), isNull);
  });

  testWidgets('tapping an external link emits popup_link_tapped with href_type external', (
    tester,
  ) async {
    final popup = _makePopup(
      id: 13,
      content: '[Learn more](https://timer.coffee)',
    );

    await tester.pumpWidget(
      _host(
        LaunchPopupWidget(
          fetchPopupOverride: (context, locale) async => popup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();

    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final tapped =
        events.firstWhere((e) => e['event_name'] == 'popup_link_tapped');
    expect(tapped['properties']['popup_id'], 13);
    expect(tapped['properties']['source_screen'], 'home');
    expect(tapped['properties']['href_type'], 'external');
  });

  testWidgets('shown popup records a home_popup entry to the engagement budget',
      (tester) async {
    final popup = _makePopup(id: 21);

    await tester.pumpWidget(
      _host(
        LaunchPopupWidget(
          fetchPopupOverride: (context, locale) async => popup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('engagement_budget_log');
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as List;
    final entry = decoded.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['surface'] == 'home_popup' && e['askId'] == '21',
        );
    expect(entry, isNotNull);

    // recordAsk also emits engagement_ask_shown — confirm it carries the
    // same surface/ask_id so the dedup rule has real data to key off.
    final events = AnalyticsService.instance.bufferedEventsForTesting;
    final askShown =
        events.firstWhere((e) => e['event_name'] == 'engagement_ask_shown');
    expect(askShown['properties']['surface'], 'home_popup');
    expect(askShown['properties']['ask_id'], '21');
  });
}
