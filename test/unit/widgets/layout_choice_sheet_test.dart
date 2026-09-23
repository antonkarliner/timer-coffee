import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/layout_choice_prompt_service.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/brewing/layout_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _semanticsWithId(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

const _instruction = 'Pour 50 grams of water';
const _nextInstruction = 'Wait for the drawdown';

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

    testWidgets('the Current badge sits on the current card only', (
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
          find.descendant(of: currentCard, matching: find.text('Current')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: otherCard, matching: find.text('Current')),
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
}
