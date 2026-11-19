import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/roaster_profile_model.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/coffee_beans_hero_header.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/quick_stat_chip.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffee_timer/widgets/roasters/roaster_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brew_flow_async_context_test.mocks.dart';

Finder _decoratedBoxesUnder(Finder parent) =>
    find.descendant(of: parent, matching: find.byType(DecoratedBox));

void _expectNoGradients(WidgetTester tester, Finder parent) {
  final gradients = tester
      .widgetList<DecoratedBox>(_decoratedBoxesUnder(parent))
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .where((decoration) => decoration.gradient != null);
  expect(gradients, isEmpty);
}

void main() {
  for (final scheme in [lightColorScheme, darkColorScheme]) {
    final brightness = scheme.brightness.name;

    testWidgets('bean hero uses themed surfaces in $brightness mode', (
      tester,
    ) async {
      final bean = CoffeeBeansModel(
        beansUuid: 'bean-1',
        roaster: 'Test Roaster',
        name: 'Test Beans',
        origin: 'Kenya',
        roastDate: DateTime(2026, 7, 1),
        packageWeightGrams: 250,
        cuppingScore: 86.5,
        versionVector: '{}',
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
          child: MaterialApp(
            theme: ThemeData(colorScheme: scheme),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: CoffeeBeansHeroHeader(
                bean: bean,
                coffeeBeansProvider: MockCoffeeBeansProvider(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hero = find.byType(CoffeeBeansHeroHeader);
      _expectNoGradients(tester, hero);
      final card = find.descendant(of: hero, matching: find.byType(Card));
      expect(tester.widget<Card>(card).color, isNull);

      final chips = find.descendant(
        of: hero,
        matching: find.byType(QuickStatChip),
      );
      expect(chips, findsNWidgets(3));
      final chipBoxes = _decoratedBoxesUnder(chips);
      expect(chipBoxes, findsNWidgets(3));
      for (final box in tester.widgetList<DecoratedBox>(chipBoxes)) {
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, scheme.surfaceContainerHighest);
      }
    });

    testWidgets('roaster tile uses a flat logo frame in $brightness mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      const roaster = RoasterProfileModel(
        id: 'roaster-1',
        slug: 'test-roaster',
        coffeeRoasterId: 1,
        roasterName: 'Test Roaster',
        isActive: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: Scaffold(body: RoasterTile(roaster: roaster, onTap: () {})),
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.byType(RoasterTile);
      _expectNoGradients(tester, tile);
      final logo = find.descendant(of: tile, matching: find.byType(RoasterLogo));
      final frame = find.ancestor(
        of: logo,
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      );
      final logoBox = tester.widget<Container>(frame);
      final decoration = logoBox.decoration as BoxDecoration;
      expect(decoration.color, scheme.surfaceContainerHighest);
      expect(logoBox.padding, const EdgeInsets.all(AppSpacing.xs));
      expect(tester.getSize(frame), const Size.square(56));
    });
  }
}
