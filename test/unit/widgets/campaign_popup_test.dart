// Tests for the campaign support block in the launch popup surfaces
// (plan 052, Item A, Phases A3+A4). Covers rendering gating on
// `isCampaignActive` (non-campaign and expired popups must render as
// ordinary popups), the optional goal progress bar (presence, clamping,
// whole-dollar label), and the three support-prompt analytics events
// (support_prompt_shown / _tapped / _dismissed) on both the home modal
// and the finish-screen expanded card dialog.

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/engagement_budget_service.dart';
import 'package:coffee_timer/widgets/campaign_support_block.dart';
import 'package:coffee_timer/widgets/finish/whats_new_card.dart';
import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the path passed to `pushPath` so the donate CTA's deep-link
/// navigation can be asserted without a real router (same pattern as
/// brew_diary_navigation_test.dart).
class _RecordingStackRouter extends Mock implements StackRouter {
  String? pushedPath;

  @override
  Future<T?> pushPath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    pushedPath = path;
    return null;
  }
}

LaunchPopupModel _makePopup({
  int id = 42,
  String? hookType,
  double? goalAmountUsd,
  double? progressAmountUsd,
  DateTime? campaignEndsAt,
  String content = "What's new in this release.",
}) {
  return LaunchPopupModel(
    id: id,
    content: content,
    locale: 'en',
    createdAt: DateTime.utc(2026, 1, 1),
    platform: 'all',
    hookType: hookType,
    goalAmountUsd: goalAmountUsd,
    progressAmountUsd: progressAmountUsd,
    campaignEndsAt: campaignEndsAt,
  );
}

Widget _host(Widget child, {_RecordingStackRouter? router}) {
  Widget app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
  if (router != null) {
    app = StackRouterScope(controller: router, stateHash: 0, child: app);
  }
  return app;
}

List<Map<String, dynamic>> _eventsNamed(String name) =>
    AnalyticsService.instance.bufferedEventsForTesting
        .where((e) => e['event_name'] == name)
        .toList();

void main() {
  setUp(() async {
    LaunchPopupWidget.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'launch_popup_first_session_done': true,
    });
    final prefs = await SharedPreferences.getInstance();
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(prefs);
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('home popup (launch_popup.dart)', () {
    testWidgets('a non-campaign popup renders no campaign block and emits no '
        'support_prompt_shown', (tester) async {
      final popup = _makePopup(id: 7, hookType: null);

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      // Dialog is up, but as an ordinary popup.
      expect(find.text('Close'), findsOneWidget);
      expect(find.byType(CampaignSupportBlock), findsNothing);
      expect(find.text('Support Timer.Coffee'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_eventsNamed('support_prompt_shown'), isEmpty);
    });

    testWidgets('an active campaign renders the CTA and emits '
        'support_prompt_shown exactly once with trigger_id and source_screen',
        (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Support Timer.Coffee'), findsOneWidget);

      final shown = _eventsNamed('support_prompt_shown');
      expect(shown, hasLength(1));
      expect(shown.single['properties']['trigger_id'], 'campaign_7');
      expect(shown.single['properties']['source_screen'], 'home');
    });

    testWidgets('an expired campaign renders as an ordinary popup — no '
        'block, no support-prompt events', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2020, 1, 1),
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      expect(find.byType(CampaignSupportBlock), findsNothing);
      expect(find.text('Support Timer.Coffee'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_eventsNamed('support_prompt_shown'), isEmpty);
      expect(_eventsNamed('support_prompt_tapped'), isEmpty);
      expect(_eventsNamed('support_prompt_dismissed'), isEmpty);
    });

    testWidgets('goal and progress present with goal > 0 → progress bar '
        'with the correct fraction', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 1000,
        progressAmountUsd: 250,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.25);
    });

    testWidgets('progress present but goal null → no progress bar',
        (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        progressAmountUsd: 250,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Support Timer.Coffee'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('goal present but progress null → no progress bar',
        (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 1000,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Support Timer.Coffee'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('goal == 0 → no progress bar', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 0,
        progressAmountUsd: 0,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('progress above goal clamps the bar to 1.0',
        (tester) async {
      final over = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: 250,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => over),
      ));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1.0,
      );
    });

    testWidgets('negative progress clamps the bar to 0.0', (tester) async {
      final negative = _makePopup(
        id: 8,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: -5,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(
          fetchPopupOverride: (context, locale) async => negative,
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.0,
      );
    });

    testWidgets('the displayed goal label contains no decimal point — '
        'whole-dollar rounding is applied', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 1000.55,
        progressAmountUsd: 0,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      final label = tester
          .widget<Text>(find.textContaining(r'$0 of'))
          .data!;
      expect(label.contains('.'), isFalse,
          reason: 'goal label must show whole dollars, got "$label"');
      expect(label, r'$0 of $1,001');
    });

    testWidgets('tapping the CTA emits support_prompt_tapped exactly once '
        'and routes to /donate; closing afterwards emits no '
        'support_prompt_dismissed', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );
      final router = _RecordingStackRouter();

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
        router: router,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Support Timer.Coffee'));
      await tester.pump();

      final tapped = _eventsNamed('support_prompt_tapped');
      expect(tapped, hasLength(1));
      expect(tapped.single['properties']['trigger_id'], 'campaign_7');
      expect(tapped.single['properties']['source_screen'], 'home');
      expect(router.pushedPath, '/donate');

      // Closing the dialog after a tap is not a dismissal of the prompt.
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(_eventsNamed('support_prompt_dismissed'), isEmpty);
      expect(_eventsNamed('popup_dismissed'), hasLength(1));
    });

    testWidgets('closing an active-campaign dialog without tapping the CTA '
        'emits support_prompt_dismissed exactly once', (tester) async {
      final popup = _makePopup(
        id: 9,
        hookType: 'black_friday',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      final dismissed = _eventsNamed('support_prompt_dismissed');
      expect(dismissed, hasLength(1));
      expect(dismissed.single['properties']['trigger_id'], 'campaign_9');
      expect(dismissed.single['properties']['source_screen'], 'home');
    });
  });

  group('finish card (whats_new_card.dart)', () {
    Widget cardHost(
      LaunchPopupModel popup,
      SharedPreferences prefs, {
      _RecordingStackRouter? router,
    }) {
      return _host(
        SingleChildScrollView(
          child: WhatsNewCard(
            popup: popup,
            locale: 'en',
            budgetService: EngagementBudgetService(prefs: prefs),
            prefs: prefs,
          ),
        ),
        router: router,
      );
    }

    testWidgets('the collapsed card shows no campaign block; the expanded '
        'dialog of an active campaign emits support_prompt_shown with '
        "source_screen 'finish'", (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(cardHost(popup, prefs));
      await tester.pump();
      await tester.pump();

      // Collapsed card: no block.
      expect(find.text('Support Timer.Coffee'), findsNothing);

      await tester.tap(find.byType(WhatsNewCard));
      await tester.pumpAndSettle();

      expect(find.text('Support Timer.Coffee'), findsOneWidget);
      final shown = _eventsNamed('support_prompt_shown');
      expect(shown, hasLength(1));
      expect(shown.single['properties']['trigger_id'], 'campaign_7');
      expect(shown.single['properties']['source_screen'], 'finish');
    });

    testWidgets('an expired campaign card opens an ordinary dialog with no '
        'block and no support-prompt events', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2020, 1, 1),
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(cardHost(popup, prefs));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(WhatsNewCard));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsOneWidget);
      expect(find.byType(CampaignSupportBlock), findsNothing);
      expect(find.text('Support Timer.Coffee'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(_eventsNamed('support_prompt_shown'), isEmpty);
      expect(_eventsNamed('support_prompt_dismissed'), isEmpty);
    });

    testWidgets('tapping the CTA in the expanded dialog emits '
        'support_prompt_tapped once, routes to /donate, and closing emits '
        'no support_prompt_dismissed', (tester) async {
      final popup = _makePopup(
        id: 7,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = _RecordingStackRouter();

      await tester.pumpWidget(cardHost(popup, prefs, router: router));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(WhatsNewCard));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Support Timer.Coffee'));
      await tester.pump();

      final tapped = _eventsNamed('support_prompt_tapped');
      expect(tapped, hasLength(1));
      expect(tapped.single['properties']['trigger_id'], 'campaign_7');
      expect(tapped.single['properties']['source_screen'], 'finish');
      expect(router.pushedPath, '/donate');

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(_eventsNamed('support_prompt_dismissed'), isEmpty);
    });

    testWidgets('closing the expanded dialog of an active campaign without '
        'tapping the CTA emits support_prompt_dismissed with '
        "source_screen 'finish'", (tester) async {
      final popup = _makePopup(
        id: 11,
        hookType: 'yearly_recap',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(cardHost(popup, prefs));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(WhatsNewCard));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      final dismissed = _eventsNamed('support_prompt_dismissed');
      expect(dismissed, hasLength(1));
      expect(dismissed.single['properties']['trigger_id'], 'campaign_11');
      expect(dismissed.single['properties']['source_screen'], 'finish');
    });
  });
}