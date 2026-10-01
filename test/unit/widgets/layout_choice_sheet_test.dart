import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/services/layout_choice_prompt_service.dart';
import 'package:coffee_timer/utils/recipe_step_resolution.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/brewing/layout_choice_sheet.dart';
import 'package:coffee_timer/widgets/brewing/layout_preview_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _semanticsWithId(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

const _instruction = 'Pour 50 grams of water';
const _nextInstruction = 'Wait for the drawdown';

RecipeModel _recipe(
  List<BrewStepModel> steps, {
  double coffeeAmount = 18,
  double waterAmount = 300,
}) {
  return RecipeModel(
    id: 'recipe',
    name: 'Test recipe',
    brewingMethodId: 'method',
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
    grindSize: 'Medium',
    brewTime: const Duration(minutes: 3),
    shortDescription: 'Test',
    steps: steps,
  );
}

Future<void> _pumpPreviewCards(
  WidgetTester tester, {
  required LayoutChoice current,
  required ValueChanged<LayoutChoice> onSelected,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorScheme: lightColorScheme),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: LayoutPreviewCards(
              current: current,
              onSelected: onSelected,
              instruction: _instruction,
              nextInstruction: _nextInstruction,
              stepSeconds: 45,
            ),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _cardDecoration(WidgetTester tester, Finder card) {
  final semantics = tester.widget<Semantics>(card);
  final inkWell = semantics.child! as InkWell;
  final container = inkWell.child! as Container;
  return container.decoration! as BoxDecoration;
}

/// Pumps a minimal app and opens the sheet from a button, recording what
/// the sheet resolved with into [picked]. Pass a distinct [appKey] when
/// pumping several sheets in one test, so each gets a fresh navigator
/// instead of re-opening on top of the previous one.
Future<void> _openSheet(
  WidgetTester tester, {
  required ColorScheme scheme,
  required List<LayoutChoice?> picked,
  LayoutChoice current = LayoutChoice.classic,
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
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final result = await showLayoutChoiceSheet(
                  context,
                  trigger: LayoutChoiceTrigger.existingUser,
                  current: current,
                  instruction: _instruction,
                  nextInstruction: _nextInstruction,
                  stepSeconds: 45,
                );
                picked.add(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('layout choice sheet', () {
    testWidgets(
      'renders both cards without overflow on small and large screens in light and dark',
      (tester) async {
        for (final size in const [Size(375, 667), Size(430, 932)]) {
          for (final scheme in const [lightColorScheme, darkColorScheme]) {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await _openSheet(
              tester,
              scheme: scheme,
              picked: [],
              appKey: '$size / ${scheme.brightness}',
            );

            expect(
              tester.takeException(),
              isNull,
              reason: '$size ${scheme.brightness}',
            );
            expect(_semanticsWithId('layoutChoiceClassicCard'), findsOneWidget);
            expect(
              _semanticsWithId('layoutChoiceImmersiveCard'),
              findsOneWidget,
            );
            expect(find.text('Classic'), findsOneWidget);
            expect(find.text('Immersive'), findsOneWidget);
            expect(find.text('How do you want to brew?'), findsOneWidget);
          }
        }
      },
    );

    testWidgets('tapping the Immersive card pops LayoutChoice.pour', (
      tester,
    ) async {
      final picked = <LayoutChoice?>[];
      await _openSheet(tester, scheme: lightColorScheme, picked: picked);

      await tester.tap(_semanticsWithId('layoutChoiceImmersiveCard'));
      await tester.pumpAndSettle();

      expect(picked, [LayoutChoice.pour]);
      expect(find.text('Immersive'), findsNothing);
    });

    testWidgets('tapping the Classic card pops LayoutChoice.classic', (
      tester,
    ) async {
      final picked = <LayoutChoice?>[];
      await _openSheet(tester, scheme: lightColorScheme, picked: picked);

      await tester.tap(_semanticsWithId('layoutChoiceClassicCard'));
      await tester.pumpAndSettle();

      expect(picked, [LayoutChoice.classic]);
    });

    testWidgets('the selection check sits on the current card only', (
      tester,
    ) async {
      for (final current in LayoutChoice.values) {
        final picked = <LayoutChoice?>[];
        await _openSheet(
          tester,
          scheme: lightColorScheme,
          picked: picked,
          current: current,
          appKey: current,
        );

        final currentCard = _semanticsWithId(
          current == LayoutChoice.classic
              ? 'layoutChoiceClassicCard'
              : 'layoutChoiceImmersiveCard',
        );
        final otherCard = _semanticsWithId(
          current == LayoutChoice.classic
              ? 'layoutChoiceImmersiveCard'
              : 'layoutChoiceClassicCard',
        );

        expect(
          find.descendant(
            of: currentCard,
            matching: find.byType(SelectionCheckBadge),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: otherCard,
            matching: find.byType(SelectionCheckBadge),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('cards are buttons in semantics, selected only when current', (
      tester,
    ) async {
      final picked = <LayoutChoice?>[];
      await _openSheet(
        tester,
        scheme: lightColorScheme,
        picked: picked,
        current: LayoutChoice.pour,
      );

      final classic = tester.widget<Semantics>(
        _semanticsWithId('layoutChoiceClassicCard'),
      );
      expect(classic.properties.button, isTrue);
      expect(classic.properties.selected, isFalse);

      final pour = tester.widget<Semantics>(
        _semanticsWithId('layoutChoiceImmersiveCard'),
      );
      expect(pour.properties.button, isTrue);
      expect(pour.properties.selected, isTrue);
    });

    testWidgets(
      'the live previews emit no brewing identifiers into the semantics tree',
      (tester) async {
        final semantics = tester.ensureSemantics();

        await _openSheet(tester, scheme: lightColorScheme, picked: []);

        // Positive control: the cards themselves are in the semantics tree.
        expect(
          find.bySemanticsIdentifier('layoutChoiceClassicCard'),
          findsOneWidget,
        );
        // The previews embed the real brewing widgets, whose identifiers
        // (`brewingStepDescription`, `stepTimeCounter`, …) the brewing tests
        // rely on — ExcludeSemantics must keep every one of them inside.
        expect(
          find.bySemanticsIdentifier(
            RegExp(
              'brewingStepDescription|brewingStepsContent|stepTimeCounter|brewPausedIndicator|circularProgressIndicator',
            ),
          ),
          findsNothing,
        );

        semantics.dispose();
      },
    );
  });

  group('LayoutPreviewCards', () {
    testWidgets('tapping each card reports its layout choice', (tester) async {
      final selected = <LayoutChoice>[];
      await _pumpPreviewCards(
        tester,
        current: LayoutChoice.classic,
        onSelected: selected.add,
      );

      await tester.tap(_semanticsWithId('layoutChoiceClassicCard'));
      await tester.tap(_semanticsWithId('layoutChoiceImmersiveCard'));

      expect(selected, [LayoutChoice.classic, LayoutChoice.pour]);
    });

    testWidgets('uses selected and unselected borders', (tester) async {
      await _pumpPreviewCards(
        tester,
        current: LayoutChoice.pour,
        onSelected: (_) {},
      );

      final classicDecoration = _cardDecoration(
        tester,
        _semanticsWithId('layoutChoiceClassicCard'),
      );
      final immersiveDecoration = _cardDecoration(
        tester,
        _semanticsWithId('layoutChoiceImmersiveCard'),
      );
      final classicBorder = classicDecoration.border! as Border;
      final immersiveBorder = immersiveDecoration.border! as Border;

      expect(classicBorder.top.color, lightColorScheme.outlineVariant);
      expect(classicBorder.top.width, 1);
      expect(immersiveBorder.top.color, lightColorScheme.primary);
      expect(immersiveBorder.top.width, 2);
    });

    testWidgets('large text does not overflow or change card heights', (
      tester,
    ) async {
      await _pumpPreviewCards(
        tester,
        current: LayoutChoice.classic,
        onSelected: (_) {},
        textScaler: const TextScaler.linear(1.3),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_semanticsWithId('layoutChoiceClassicCard')).height,
        tester.getSize(_semanticsWithId('layoutChoiceImmersiveCard')).height,
      );
    });
  });

  group('layoutPreviewStepsFor', () {
    test('skips preparation steps with zero time', () {
      final preview = layoutPreviewStepsFor(
        _recipe([
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare the brewer',
            time: Duration.zero,
          ),
          BrewStepModel(
            id: 'first',
            order: 2,
            description: 'First pour',
            time: const Duration(seconds: 30),
          ),
          BrewStepModel(
            id: 'second',
            order: 3,
            description: 'Second pour',
            time: const Duration(seconds: 45),
          ),
        ]),
      );

      expect(preview.instruction, 'First pour');
      expect(preview.nextInstruction, 'Second pour');
      expect(preview.stepSeconds, 30);
    });

    test('has no next instruction with only one timed step', () {
      final preview = layoutPreviewStepsFor(
        _recipe([
          BrewStepModel(
            id: 'only',
            order: 1,
            description: 'Only pour',
            time: const Duration(seconds: 20),
          ),
        ]),
      );

      expect(preview.nextInstruction, isNull);
    });

    test('returns an empty preview when there is no timed step', () {
      final preview = layoutPreviewStepsFor(
        _recipe([
          BrewStepModel(
            id: 'prep',
            order: 1,
            description: 'Prepare the brewer',
            time: Duration.zero,
          ),
        ]),
      );

      expect(preview, (instruction: '', nextInstruction: null, stepSeconds: 0));
    });

    test('resolves final coffee and water amount placeholders', () {
      final preview = layoutPreviewStepsFor(
        _recipe([
          BrewStepModel(
            id: 'pour',
            order: 1,
            description:
                'Use <final_coffee_amount>g coffee and '
                '<final_water_amount>g water',
            time: const Duration(seconds: 25),
          ),
        ]),
      );

      expect(preview.instruction, 'Use 18g coffee and 300g water');
    });
  });
}
