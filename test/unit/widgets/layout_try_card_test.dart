import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/engagement_budget_service.dart';
import 'package:coffee_timer/services/finish_slot_resolver.dart'
    show kLayoutTryAskId;
import 'package:coffee_timer/services/layout_choice_prompt_service.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/finish/layout_try_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the card at 375 logical pixels wide (small-phone finish screen) on
/// the given scheme. Every bookkeeping dependency is real: prefs, budget
/// service, prompt service, and the advanced-features toggle.
Future<void> pumpCard(
  WidgetTester tester, {
  required ColorScheme scheme,
  required SharedPreferences prefs,
  required EngagementBudgetService budget,
  required LayoutChoicePromptService promptService,
  required AdvancedFeaturesService advanced,
  Object? appKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: appKey == null ? null : ValueKey<Object>(appKey),
      theme: ThemeData(colorScheme: scheme),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LayoutTryCard(
            budgetService: budget,
            promptService: promptService,
            advancedFeatures: advanced,
            arm: 'none',
          ),
        ),
      ),
    ),
  );
  // First frame's post-frame callback (impression bookkeeping), then let
  // its futures resolve.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders in light and dark at 375 wide without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final scheme in const [lightColorScheme, darkColorScheme]) {
      SharedPreferences.setMockInitialValues({'layout_picker_dismissed': true});
      final prefs = await SharedPreferences.getInstance();

      await pumpCard(
        tester,
        scheme: scheme,
        prefs: prefs,
        budget: EngagementBudgetService(prefs: prefs),
        promptService: LayoutChoicePromptService(prefs),
        advanced: AdvancedFeaturesService(isWeb: false),
        appKey: scheme.brightness,
      );

      expect(
        tester.takeException(),
        isNull,
        reason: '${scheme.brightness} at 375 wide',
      );
      expect(find.text('Try the immersive screen next time'), findsOneWidget);
      expect(
        find.text('The screen fills with coffee as your brew progresses.'),
        findsOneWidget,
      );
      expect(find.text('Use it next brew'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    }
  });

  testWidgets('first frame marks the card shown and records the '
      'finish_slot budget ask under kLayoutTryAskId', (tester) async {
    SharedPreferences.setMockInitialValues({'layout_picker_dismissed': true});
    final prefs = await SharedPreferences.getInstance();
    final budget = EngagementBudgetService(prefs: prefs);

    expect(prefs.getBool('layout_finish_card_shown'), isNull);
    expect(prefs.getString('engagement_budget_log'), isNull);

    await pumpCard(
      tester,
      scheme: lightColorScheme,
      prefs: prefs,
      budget: budget,
      promptService: LayoutChoicePromptService(prefs),
      advanced: AdvancedFeaturesService(isWeb: false),
    );

    expect(prefs.getBool('layout_finish_card_shown'), isTrue);
    final entries =
        (jsonDecode(prefs.getString('engagement_budget_log')!) as List)
            .cast<Map<String, dynamic>>();
    expect(
      entries.any(
        (e) =>
            e['surface'] == EngagementSurface.finishSlot &&
            e['askId'] == kLayoutTryAskId,
      ),
      isTrue,
      reason: 'expected a finish_slot/$kLayoutTryAskId entry, got $entries',
    );

    // Rebuilding must not double-record — the guard is a one-shot flag.
    await tester.pump();
    await tester.pump();
    expect(
      (jsonDecode(prefs.getString('engagement_budget_log')!) as List).length,
      1,
    );
  });

  testWidgets('accept flips pourLayoutEnabled and swaps the buttons for the '
      'accepted confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({'layout_picker_dismissed': true});
    final prefs = await SharedPreferences.getInstance();
    final advanced = AdvancedFeaturesService(isWeb: false);
    expect(advanced.pourLayoutEnabled, isFalse);

    await pumpCard(
      tester,
      scheme: lightColorScheme,
      prefs: prefs,
      budget: EngagementBudgetService(prefs: prefs),
      promptService: LayoutChoicePromptService(prefs),
      advanced: advanced,
    );

    await tester.tap(find.byKey(const Key('layoutTryAcceptButton')));
    await tester.pumpAndSettle();

    expect(advanced.pourLayoutEnabled, isTrue);
    expect(
      find.text('Done — your next brew uses the immersive screen.'),
      findsOneWidget,
    );
    expect(find.text('Use it next brew'), findsNothing);
    expect(find.text('Not now'), findsNothing);
  });

  testWidgets('accept persists the toggle to prefs', (tester) async {
    SharedPreferences.setMockInitialValues({'layout_picker_dismissed': true});
    final prefs = await SharedPreferences.getInstance();
    final advanced = AdvancedFeaturesService(isWeb: false);

    await pumpCard(
      tester,
      scheme: lightColorScheme,
      prefs: prefs,
      budget: EngagementBudgetService(prefs: prefs),
      promptService: LayoutChoicePromptService(prefs),
      advanced: advanced,
    );

    await tester.tap(find.byKey(const Key('layoutTryAcceptButton')));
    await tester.pumpAndSettle();

    expect(prefs.getBool(AdvancedFeaturesService.kPourLayoutKey), isTrue);
  });

  testWidgets('decline collapses the card', (tester) async {
    SharedPreferences.setMockInitialValues({'layout_picker_dismissed': true});
    final prefs = await SharedPreferences.getInstance();
    final advanced = AdvancedFeaturesService(isWeb: false);

    await pumpCard(
      tester,
      scheme: lightColorScheme,
      prefs: prefs,
      budget: EngagementBudgetService(prefs: prefs),
      promptService: LayoutChoicePromptService(prefs),
      advanced: advanced,
    );

    await tester.tap(find.byKey(const Key('layoutTryDeclineButton')));
    await tester.pumpAndSettle();

    expect(find.text('Try the immersive screen next time'), findsNothing);
    expect(find.byType(Card), findsNothing);
    // Decline must not have touched the layout.
    expect(advanced.pourLayoutEnabled, isFalse);
    expect(prefs.getBool(AdvancedFeaturesService.kPourLayoutKey), isNull);
  });
}
