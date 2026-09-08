// Tests for the campaign support block in the launch popup surfaces
// (plan 052, Item A, Phases A3+A4). Covers rendering gating on
// `isCampaignActive` (non-campaign and expired popups must render as
// ordinary popups), the optional goal progress bar (presence, clamping,
// whole-dollar label, goal-reached label at/past the goal, floored
// negatives, and the bar-conditional spacers — plan 054 Items A+D), and
// the three support-prompt analytics events
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

/// Every `SizedBox` inside the `CampaignSupportBlock` subtree, so the
/// spacing tests can assert which spacers render (plan 054, Item D).
List<SizedBox> _spacersInsideBlock(WidgetTester tester) => tester
    .widgetList<SizedBox>(
      find.descendant(
        of: find.byType(CampaignSupportBlock),
        matching: find.byType(SizedBox),
      ),
    )
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

    testWidgets('progress bar uses explicit monochrome theme colours',
        (tester) async {
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

      final finder = find.byType(LinearProgressIndicator);
      final bar = tester.widget<LinearProgressIndicator>(finder);
      final colorScheme = Theme.of(tester.element(finder)).colorScheme;
      expect(bar.color, colorScheme.primary);
      expect(bar.backgroundColor, colorScheme.outlineVariant);
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

    testWidgets('over-funded campaign: full bar and the goal-reached '
        'label — the raw "of" label is gone', (tester) async {
      final popup = _makePopup(
        id: 20,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: 250,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
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
      final label = tester
          .widget<Text>(find.textContaining(r'$250 raised'))
          .data!;
      expect(label, r'$250 raised — goal reached. Thank you!');
      expect(label.contains(r'of $100'), isFalse,
          reason: 'over-funded label must not read like a bug, got "$label"');
    });

    testWidgets('exactly at goal: full bar and the goal-reached label — '
        'the boundary is >=, not >', (tester) async {
      final popup = _makePopup(
        id: 21,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: 100,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
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
      expect(
        find.text(r'$100 raised — goal reached. Thank you!'),
        findsOneWidget,
      );
      expect(find.textContaining(r'of $100'), findsNothing);
    });

    testWidgets('just below goal: 0.99 bar and the ordinary "of" label',
        (tester) async {
      final popup = _makePopup(
        id: 22,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: 99,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.99,
      );
      expect(find.text(r'$99 of $100'), findsOneWidget);
      expect(find.textContaining('goal reached'), findsNothing);
    });

    testWidgets('negative progress: the label is floored at zero — no '
        'minus sign', (tester) async {
      final popup = _makePopup(
        id: 23,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: -5,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
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
      final label = tester
          .widget<Text>(find.textContaining(r'$0 of'))
          .data!;
      expect(label, r'$0 of $100');
      expect(label.contains('-'), isFalse,
          reason: 'negative progress must be floored at zero, got "$label"');
      expect(find.textContaining('goal reached'), findsNothing);
    });

    testWidgets('no goal bar: a single 16dp spacer before the CTA — no '
        'stacked 16 + 8 whitespace', (tester) async {
      final popup = _makePopup(
        id: 24,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Support Timer.Coffee'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      final spacers = _spacersInsideBlock(tester);
      expect(
        spacers.where((box) => box.height == 16.0),
        hasLength(1),
        reason: 'exactly one 16dp spacer between the markdown and the CTA',
      );
      expect(
        spacers.where((box) => box.height == 8.0),
        isEmpty,
        reason: 'the 8dp spacer must render only with a goal bar',
      );
    });

    testWidgets('with a goal bar: both spacers render — 16dp before the '
        'bar and 8dp before the CTA', (tester) async {
      final popup = _makePopup(
        id: 25,
        hookType: 'coffee_day',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
        goalAmountUsd: 100,
        progressAmountUsd: 50,
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final spacers = _spacersInsideBlock(tester);
      expect(
        spacers.where((box) => box.height == 16.0),
        hasLength(1),
        reason: 'the 16dp spacer above the goal bar must render',
      );
      expect(
        spacers.where((box) => box.height == 8.0),
        hasLength(1),
        reason: 'the 8dp spacer between the goal bar and the CTA must render',
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

    testWidgets('tapping the CTA closes the dialog, emits '
        'support_prompt_tapped exactly once, routes to /donate, and logs '
        'the CTA dismissal without support_prompt_dismissed', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final tapped = _eventsNamed('support_prompt_tapped');
      expect(tapped, hasLength(1));
      expect(tapped.single['properties']['trigger_id'], 'campaign_7');
      expect(tapped.single['properties']['source_screen'], 'home');
      expect(router.pushedPath, '/donate');
      expect(_eventsNamed('support_prompt_dismissed'), isEmpty);
      final popupDismissed = _eventsNamed('popup_dismissed');
      expect(popupDismissed, hasLength(1));
      expect(popupDismissed.single['properties']['dismiss_method'], 'cta');
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
      final popupDismissed = _eventsNamed('popup_dismissed');
      expect(popupDismissed, hasLength(1));
      expect(popupDismissed.single['properties']['dismiss_method'], 'close');
    });

    testWidgets('barrier dismissal logs barrier_or_back', (tester) async {
      final popup = _makePopup(
        id: 10,
        hookType: 'black_friday',
        campaignEndsAt: DateTime.utc(2100, 1, 1),
      );

      await tester.pumpWidget(_host(
        LaunchPopupWidget(fetchPopupOverride: (context, locale) async => popup),
      ));
      await tester.pumpAndSettle();

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final popupDismissed = _eventsNamed('popup_dismissed');
      expect(popupDismissed, hasLength(1));
      expect(
        popupDismissed.single['properties']['dismiss_method'],
        'barrier_or_back',
      );
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

    testWidgets('tapping the CTA in the expanded dialog closes it, emits '
        'support_prompt_tapped once, routes to /donate, and logs the CTA '
        'dismissal without support_prompt_dismissed', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final tapped = _eventsNamed('support_prompt_tapped');
      expect(tapped, hasLength(1));
      expect(tapped.single['properties']['trigger_id'], 'campaign_7');
      expect(tapped.single['properties']['source_screen'], 'finish');
      expect(router.pushedPath, '/donate');
      expect(_eventsNamed('support_prompt_dismissed'), isEmpty);
      final popupDismissed = _eventsNamed('popup_dismissed');
      expect(popupDismissed, hasLength(1));
      expect(popupDismissed.single['properties']['dismiss_method'], 'cta');
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
      final popupDismissed = _eventsNamed('popup_dismissed');
      expect(popupDismissed, hasLength(1));
      expect(popupDismissed.single['properties']['dismiss_method'], 'close');
    });

    testWidgets('barrier dismissal of the expanded dialog logs '
        'barrier_or_back', (tester) async {
      final popup = _makePopup(
        id: 12,
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
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final popupDismissed = _eventsNamed('popup_dismissed');
      expect(popupDismissed, hasLength(1));
      expect(
        popupDismissed.single['properties']['dismiss_method'],
        'barrier_or_back',
      );
    });
  });
}
