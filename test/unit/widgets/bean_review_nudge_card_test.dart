import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/services/bean_review_prompt_service.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffee_timer/widgets/bean_review_nudge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CoffeeBeansModel _makeBean({
  String uuid = 'bean-1',
  String name = 'Ethiopia Yirgacheffe',
  String roaster = 'Blue Bottle',
}) {
  return CoffeeBeansModel(
    beansUuid: uuid,
    roaster: roaster,
    name: name,
    origin: 'Ethiopia',
    isDeleted: false,
    versionVector: VersionVector.initial('test').toString(),
  );
}

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders the title with the bean name', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = BeanReviewPromptService(prefs: prefs);
    final bean = _makeBean(name: 'Ethiopia Yirgacheffe');

    await tester.pumpWidget(
      host(
        BeanReviewNudgeCard(
          bean: bean,
          trigger: 'brew_count',
          promptService: service,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('How was Ethiopia Yirgacheffe?'), findsOneWidget);
    expect(find.text('by Blue Bottle'), findsOneWidget);
  });

  testWidgets('depletion trigger shows the depleted subtitle', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = BeanReviewPromptService(prefs: prefs);
    final bean = _makeBean();

    await tester.pumpWidget(
      host(
        BeanReviewNudgeCard(
          bean: bean,
          trigger: 'depletion',
          promptService: service,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text("You just finished this bag — how did it treat you?"),
      findsOneWidget,
    );
    expect(find.text('by ${bean.roaster}'), findsNothing);
  });

  testWidgets('records exactly one impression on the first frame', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = BeanReviewPromptService(prefs: prefs);
    final bean = _makeBean(uuid: 'bean-impression');

    expect(prefs.getInt('review_card_imp_bean-impression'), isNull);

    await tester.pumpWidget(
      host(
        BeanReviewNudgeCard(
          bean: bean,
          trigger: 'brew_count',
          promptService: service,
        ),
      ),
    );
    // First frame's post-frame callback.
    await tester.pump();
    // Let the recordImpression future resolve.
    await tester.pump();

    expect(prefs.getInt('review_card_imp_bean-impression'), 1);

    // Rebuilding (e.g. parent setState) must not double-record — the guard
    // is a one-shot flag in State, not tied to build count.
    await tester.pump();
    await tester.pump();
    expect(prefs.getInt('review_card_imp_bean-impression'), 1);
  });

  testWidgets('tapping a star opens the review form with that rating', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = BeanReviewPromptService(prefs: prefs);
    final bean = _makeBean();

    double? capturedRating;
    var callCount = 0;

    await tester.pumpWidget(
      host(
        BeanReviewNudgeCard(
          bean: bean,
          trigger: 'brew_count',
          promptService: service,
          openReviewForm: (context, rating) async {
            callCount++;
            capturedRating = rating;
            return false;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Stars are laid out left-to-right 1..5 — tap the 4th icon.
    final stars = find.byIcon(Icons.star_outline_rounded);
    expect(stars, findsNWidgets(5));
    await tester.tap(stars.at(3));
    await tester.pumpAndSettle();

    expect(callCount, 1);
    expect(capturedRating, 4.0);
  });

  testWidgets(
    'the write-a-review button opens the form with no preselected rating',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = BeanReviewPromptService(prefs: prefs);
      final bean = _makeBean();

      double? capturedRating = -1;
      var callCount = 0;

      await tester.pumpWidget(
        host(
          BeanReviewNudgeCard(
            bean: bean,
            trigger: 'brew_count',
            promptService: service,
            openReviewForm: (context, rating) async {
              callCount++;
              capturedRating = rating;
              return true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Write a review'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(capturedRating, isNull);

      // A `true` result swaps the card into its thank-you state.
      expect(
        find.text('Thanks! Your review helps other coffee lovers.'),
        findsOneWidget,
      );
    },
  );
}
