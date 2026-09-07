import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brewing/next_step_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Deliberately a couple of glyphs: the FlutterTest font uses wide
// fixed-advance glyphs, so anything longer already wraps at 320dp.
const _shortDescription = 'Stir';
const _veryLongDescription =
    'Slowly pour in a circular motion, keeping the water level consistent, '
    'then wait for the drawdown to finish before starting the next pour and '
    'make sure the coffee bed stays perfectly flat throughout the whole brew';

// Narrow phone width to prove wrapping and truncation behave on small
// screens, with the app-standard 16dp horizontal padding applied.
Widget _wrap(Widget child, {TextScaler textScaler = TextScaler.noScaling}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('brewTimerRingDiameterForWidth', () {
    test('preserves instruction room on compact screens', () {
      expect(brewTimerRingDiameterForWidth(320), 120);
      expect(brewTimerRingDiameterForWidth(280), 120);
    });

    test('grows the timer ring by ten percent on typical phones', () {
      expect(brewTimerRingDiameterForWidth(390), 132);
      expect(brewTimerRingDiameterForWidth(430), 132);
      expect(brewTimerRingDiameterForWidth(355), 126);
    });
  });

  group('NextStepPreview', () {
    testWidgets('renders the label and the next-step description', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const NextStepPreview(label: 'Next:', description: _shortDescription),
        ),
      );

      expect(find.text('Next:'), findsOneWidget);
      expect(tester.getSize(find.byType(NextStepPreview)).width, 288);
      expect(find.text(_shortDescription), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('truncates very long descriptions to two lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const NextStepPreview(
            label: 'Next:',
            description: _veryLongDescription,
          ),
        ),
      );

      final description = tester.widget<Text>(find.text(_veryLongDescription));
      expect(description.maxLines, 2);
      expect(description.overflow, TextOverflow.ellipsis);

      // fontSize 20 * height 1.3 -> 26 per line; the rendered paragraph
      // must actually stop at two lines rather than only carrying the hint.
      final size = tester.getSize(find.text(_veryLongDescription));
      expect(size.height, greaterThan(20 * 1.3 * 1.5));
      expect(size.height, lessThan(20 * 1.3 * 2.5));

      // The truncated description uses the full available content width
      // (320 - 2 * 16), i.e. nothing is reserved on the trailing side.
      expect(size.width, moreOrLessEquals(320 - 2 * AppSpacing.base));
      expect(tester.takeException(), isNull);
    });

    testWidgets('grows with the content instead of clipping at 2x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const NextStepPreview(
            label: 'Next:',
            description: _veryLongDescription,
          ),
          textScaler: const TextScaler.linear(2.0),
        ),
      );

      // No fixed height anywhere: the two capped lines simply get taller.
      final size = tester.getSize(find.text(_veryLongDescription));
      expect(size.height, greaterThan(40 * 1.3 * 1.5));
      expect(size.height, lessThan(40 * 1.3 * 2.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('short descriptions take less height than long ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const NextStepPreview(label: 'Next:', description: _shortDescription),
        ),
      );
      final shortHeight = tester.getSize(find.text(_shortDescription)).height;

      await tester.pumpWidget(
        _wrap(
          const NextStepPreview(
            label: 'Next:',
            description: _veryLongDescription,
          ),
        ),
      );
      final longHeight = tester.getSize(find.text(_veryLongDescription)).height;

      expect(longHeight, greaterThan(shortHeight));
    });
  });

  group('BrewPausedLabel', () {
    testWidgets('exposes the paused state to accessibility services', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const BrewPausedLabel(label: 'Paused')));

      expect(find.text('Paused'), findsOneWidget);
      expect(find.bySemanticsLabel('Paused'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'brewPausedIndicator',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
