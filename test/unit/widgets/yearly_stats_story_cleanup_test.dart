import 'dart:async';
import 'dart:ui' as ui;

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/yearly_stats_story_24_screen.dart';
import 'package:coffee_timer/screens/yearly_stats_story_25_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart' as mocks;

void main() {
  test('yearly story entry widgets preserve their public keys', () {
    const story24Key = ValueKey('story-24');
    const story25Key = ValueKey('story-25');

    expect(const YearlyStatsStoryScreen(key: story24Key).key, story24Key);
    expect(const YearlyStatsStory25Screen(key: story25Key).key, story25Key);
  });

  test('2024 background painter retains its non-repainting contract', () {
    final painter = BackgroundPatternPainter(
      icons: const [Icons.coffee],
      spacing: 48,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(120, 120));
    final picture = recorder.endRecording();

    expect(
      painter.shouldRepaint(
        BackgroundPatternPainter(icons: const [Icons.coffee], spacing: 48),
      ),
      isFalse,
    );
    picture.dispose();
  });

  testWidgets('2025 story keeps its loading surface while stats are pending', (
    tester,
  ) async {
    final userStats = mocks.MockUserStatProvider();
    final recipes = mocks.MockRecipeProvider();
    final coffeeBeans = mocks.MockCoffeeBeansProvider();
    final database = mocks.MockDatabaseProvider();
    final pendingStats = Completer<List<UserStatsModel>>();
    when(userStats.fetchAllUserStats()).thenAnswer((_) => pendingStats.future);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatProvider>.value(value: userStats),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipes),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: coffeeBeans),
          Provider<DatabaseProvider>.value(value: database),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: YearlyStatsStory25Screen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
