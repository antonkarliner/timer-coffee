import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/services/recipe_ai_review_diff.dart';
import 'package:coffee_timer/services/recipe_expression_service.dart';
import 'package:coffee_timer/services/recipe_verification_client.dart';
import 'package:coffee_timer/widgets/recipe_creation/ai_review_changes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeExpressionProcessingResult _processing(List<String> templates) {
  final steps = <BrewStepModel>[];
  final stepResults = <RecipeExpressionStepResult>[];
  for (var i = 0; i < templates.length; i++) {
    final original = BrewStepModel(
      id: 's$i',
      order: i + 1,
      description: 'raw $i',
      time: const Duration(seconds: 30),
    );
    final step = original.copyWith(description: templates[i]);
    steps.add(step);
    stepResults.add(
      RecipeExpressionStepResult(
        originalStep: original,
        step: step,
        previewDescription: '',
        issues: const [],
      ),
    );
  }
  return RecipeExpressionProcessingResult(
    steps: steps,
    stepResults: stepResults,
  );
}

/// One changed step (brew step 1): the AI made a literal 250ml amount
/// scalable. At the current amounts both render "250ml"; at 2× only the
/// scalable one (500ml).
RecipeAiReviewDiff _oneChangeDiff() => RecipeAiReviewDiff.compute(
  local: _processing([
    'Prepare filter',
    'Rinse filter with 250ml water',
    'Pour all water',
  ]),
  reviewed: _processing([
    'Prepare filter',
    'Rinse filter with (1 x <final_water_amount>)ml water',
    'Pour all water',
  ]),
  coffeeAmount: 15,
  waterAmount: 250,
);

Iterable<String> _renderedTexts(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rich) => rich.text.toPlainText());
}

Future<Completer<RecipeAiReviewDecision?>> _openSheet(
  WidgetTester tester, {
  required RecipeAiReviewDiff diff,
  List<RecipeVerificationIssue> issues = const [],
}) async {
  // Small phone size, so overflow in the sheet is caught.
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) {
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );

  final result = Completer<RecipeAiReviewDecision?>();
  showAiReviewChangesSheet(
    hostContext,
    diff: diff,
    coffeeAmount: 15,
    waterAmount: 250,
    issues: issues,
  ).then(result.complete);
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('lists only the changed steps with both versions', (
    tester,
  ) async {
    await _openSheet(tester, diff: _oneChangeDiff());

    // Step order 2 → "Brew Step 1"; the unchanged step has no card.
    expect(find.text('Brew Step 1'), findsOneWidget);
    expect(find.text('Preparation Step'), findsNothing);
    expect(find.text('Your version'), findsOneWidget);
    expect(find.text('Reviewed'), findsOneWidget);
    // At the current amounts both versions render identically.
    expect(
      _renderedTexts(tester).where((t) => t.contains('250ml')).length,
      2,
    );
    expect(
      _renderedTexts(tester).any((t) => t.contains('Pour all water')),
      isFalse,
    );
  });

  testWidgets('2× preview doubles the scalable amount but not the literal', (
    tester,
  ) async {
    await _openSheet(tester, diff: _oneChangeDiff());

    await tester.tap(find.bySemanticsIdentifier('ai_review_preview_2x'));
    await tester.pumpAndSettle();

    final texts = _renderedTexts(tester).toList();
    expect(texts.where((t) => t.contains('500ml')).length, 1);
    // "Your version" keeps the literal 250ml.
    expect(texts.where((t) => t.contains('250ml')).length, 1);
  });

  testWidgets('Apply changes completes the future with applied', (
    tester,
  ) async {
    final result = await _openSheet(tester, diff: _oneChangeDiff());

    await tester.tap(find.bySemanticsIdentifier('ai_review_apply'));
    await tester.pumpAndSettle();

    expect(await result.future, RecipeAiReviewDecision.applied);
  });

  testWidgets('Keep my version completes the future with kept', (
    tester,
  ) async {
    final result = await _openSheet(tester, diff: _oneChangeDiff());

    await tester.tap(find.bySemanticsIdentifier('ai_review_keep'));
    await tester.pumpAndSettle();

    expect(await result.future, RecipeAiReviewDecision.kept);
  });

  testWidgets('dismissing via the barrier returns null', (tester) async {
    final result = await _openSheet(tester, diff: _oneChangeDiff());

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(await result.future, isNull);
  });

  testWidgets('amount-issue notes are deduplicated; other codes ignored', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await _openSheet(
      tester,
      diff: _oneChangeDiff(),
      issues: const [
        RecipeVerificationIssue(
          code: 'unverifiable_amount',
          field: 'description',
          message: 'first',
        ),
        RecipeVerificationIssue(
          code: 'unverifiable_amount',
          field: 'description',
          message: 'duplicate code',
        ),
        RecipeVerificationIssue(code: 'total_brew_time_mismatch'),
        RecipeVerificationIssue(code: 'invalid_scalable_expression'),
      ],
    );

    expect(
      find.text(l10n.recipeCreationAiReviewIssueAmountUnverified),
      findsOneWidget,
    );
    expect(
      find.text(l10n.recipeCreationFormatIssueInvalidExpression),
      findsOneWidget,
    );
    // No note text for the timing-only code.
    expect(find.textContaining('total_brew_time'), findsNothing);
  });

  testWidgets('ten changed steps fit a 375×667 phone without overflow', (
    tester,
  ) async {
    final templates = [
      for (var i = 0; i < 11; i++)
        i.isEven
            ? 'Step $i with 250ml fixed'
            : 'Step $i with (1 x <final_water_amount>)ml scalable',
    ];
    final diff = RecipeAiReviewDiff.compute(
      local: _processing(templates),
      reviewed: _processing([
        for (var i = 0; i < 11; i++)
          i.isEven
              ? 'Step $i edited with 250ml fixed'
              : 'Step $i with (1 x <final_water_amount>)ml scalable now',
      ]),
      coffeeAmount: 15,
      waterAmount: 250,
    );
    expect(diff.changedStepCount, 11);

    final result = await _openSheet(tester, diff: diff);

    expect(tester.takeException(), isNull);
    // The action bar is outside the scrollable body, so it is reachable.
    await tester.tap(find.bySemanticsIdentifier('ai_review_apply'));
    await tester.pumpAndSettle();
    expect(await result.future, RecipeAiReviewDecision.applied);
  });
}
