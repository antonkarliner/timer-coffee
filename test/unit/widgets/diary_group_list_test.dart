import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brew_diary/diary_group_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('group card uses explicit counts without a combined trend', (
    tester,
  ) async {
    var tapped = false;
    final entries = [
      _entry(id: 'v60-rated', methodId: 'v60', rating: 4.0),
      _entry(id: 'v60-unrated', methodId: 'v60'),
      _entry(id: 'aero-rated', methodId: 'aeropress', rating: 3.5),
    ];
    final group = DiaryGroup(
      key: 'bean-1',
      title: 'Test beans',
      subtitle: 'Test roaster',
      roaster: 'Test roaster',
      entries: entries,
      // Deliberately stale aggregate fields: presentation must derive the new
      // summary from the already-loaded entries.
      count: 99,
      avgRating: 4.9,
      lastBrew: entries.last.createdAt,
      ratingSeries: const [2.0, 4.0],
      isDialedIn: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiaryGroupCard(group: group, onTap: () => tapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(DiaryGroupCard)),
    )!;
    final card = find.bySemanticsIdentifier('diaryGroupCard_bean-1');

    for (final summaryFragment in [
      loc.diaryGroupBrewCount(3),
      loc.formattedBrewingMethodCount(2),
      loc.journeyEvaluatedBrewCount(2),
    ]) {
      expect(
        find.descendant(of: card, matching: find.text(summaryFragment)),
        findsOneWidget,
      );
    }
    expect(find.text(loc.diaryGroupDialedIn), findsOneWidget);
    expect(find.textContaining('★'), findsNothing);
    final customPaints = tester.widgetList<CustomPaint>(
      find.descendant(of: card, matching: find.byType(CustomPaint)),
    );
    expect(
      customPaints.where(
        (paint) => paint.painter.runtimeType.toString() == '_SparklinePainter',
      ),
      isEmpty,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.trending_up)),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.trending_down)),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.trending_flat)),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('diaryGroupLogoSlot'))),
      const Size(
        AppSpacing.xxl + AppSpacing.lg,
        AppSpacing.xxl + AppSpacing.sm,
      ),
    );

    await tester.tap(card);
    expect(tapped, isTrue);
  });
}

DiaryEntry _entry({
  required String id,
  required String methodId,
  double? rating,
}) => DiaryEntry(
  statUuid: id,
  recipeId: 'recipe-$id',
  recipeName: 'Recipe $id',
  brewingMethodId: methodId,
  methodName: methodId == 'v60' ? 'V60' : 'AeroPress',
  createdAt: DateTime(2026, 7, id == 'aero-rated' ? 3 : 1),
  coffeeAmount: 15,
  waterAmount: 250,
  rating: rating,
  isMarked: false,
  coffeeBeansUuid: 'bean-1',
  beanName: 'Test beans',
  roaster: 'Test roaster',
);
