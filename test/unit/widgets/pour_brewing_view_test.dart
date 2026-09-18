import 'dart:math' as math;

import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/brewing/pour_brewing_view.dart';
import 'package:coffee_timer/widgets/brewing/pour_liquid_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Deliberately short: the FlutterTest font uses wide fixed-advance glyphs,
// so anything longer already wraps at 320dp.
const _instruction = 'Pour 60 grams in a slow spiral';
const _longInstruction =
    'Slowly pour in a circular motion, keeping the water level consistent, '
    'then wait for the drawdown to finish before starting the next pour and '
    'make sure the coffee bed stays perfectly flat throughout the whole brew';
const _nextInstruction = 'Wait for the drawdown to finish';

// The FlutterTest font's glyphs advance a full em, so three digits at 72px
// under a 1.5 scaler are wider than a 320dp screen: the narrow-screen
// harness passes 56 to keep the caller's countdown on one line.
//
// Takes the colour the view asks for: the view renders its content twice —
// once dry, once submerged and clipped to the liquid — and hands each copy
// the colour that reads against what is behind it there.
Widget Function(Color) _countdown({double fontSize = 72}) =>
    (Color color) => Text(
          '128',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );

PourBrewingView _view({
  String? nextInstruction = _nextInstruction,
  double level = 0.5,
  bool isPaused = false,
  String instruction = _instruction,
  double bottomClearance = 96,
  double countdownFontSize = 72,
}) {
  return PourBrewingView(
    instruction: instruction,
    nextInstruction: nextInstruction,
    countdownBuilder: _countdown(fontSize: countdownFontSize),
    elapsedText: '02:14',
    totalText: '04:00',
    level: level,
    wavePhase: 1.0,
    waveAmplitude: 6.0,
    fillColor: AppBrewColors.brewFill(lightColorScheme),
    isPaused: isPaused,
    pausedLabel: 'Paused',
    opacity: 1.0,
    bottomClearance: bottomClearance,
  );
}

Widget _wrap(
  Widget child, {
  ColorScheme scheme = lightColorScheme,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: MaterialApp(
      theme: ThemeData(colorScheme: scheme),
      home: Scaffold(body: child),
    ),
  );
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder _semanticsWithId(String identifier) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.identifier == identifier,
);

/// The view lays its content out twice — a dry copy in the scheme colours and
/// a white copy clipped to the liquid — so a bare `find.text` matches two
/// widgets. This scopes a text lookup to the dry copy, which is the only one
/// wrapped in `brewingStepsContent` Semantics.
Finder _dryText(String text) => find.descendant(
  of: _semanticsWithId('brewingStepsContent'),
  matching: find.text(text),
);

int _stepsContentChildCount(WidgetTester tester) {
  final semantics = tester.widget<Semantics>(
    _semanticsWithId('brewingStepsContent'),
  );
  final column = ((semantics.child! as Padding).child!) as Column;
  return column.children.length;
}

/// WCAG 2.x relative luminance from the colour's linearised sRGB channels.
double _relativeLuminance(Color color) {
  double linear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}

double _contrastRatio(Color a, Color b) {
  final luminanceA = _relativeLuminance(a);
  final luminanceB = _relativeLuminance(b);
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Counts its own mounts, so a test can prove the countdown was never
/// remounted (the CLAUDE.md tree-shape trap).
class _MountCountingCountdown extends StatefulWidget {
  const _MountCountingCountdown({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountCountingCountdown> createState() =>
      _MountCountingCountdownState();
}

class _MountCountingCountdownState extends State<_MountCountingCountdown> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) =>
      const Text('128', style: TextStyle(fontSize: 72));
}

void main() {
  group('PourBrewingView layout', () {
    const surfaces = [
      ('phone', Size(375, 812)),
      ('large phone', Size(430, 932)),
    ];
    const themes = [('light', lightColorScheme), ('dark', darkColorScheme)];
    for (final (label, size) in surfaces) {
      for (final (themeLabel, scheme) in themes) {
        testWidgets('renders without overflow at $label in $themeLabel theme', (
          tester,
        ) async {
          _setSurface(tester, size);
          await tester.pumpWidget(_wrap(_view(), scheme: scheme));

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets(
      'does not overflow at 320dp width with a 1.5 text scaler and a long '
      'instruction',
      (tester) async {
        _setSurface(tester, const Size(320, 690));
        await tester.pumpWidget(
          _wrap(
            _view(instruction: _longInstruction, countdownFontSize: 56),
            textScaler: const TextScaler.linear(1.5),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders the instruction, next step and the elapsed row', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(_wrap(_view()));

      // Each string appears twice — once in the dry copy and once in the
      // submerged copy clipped to the liquid — so assertions are scoped to
      // the dry copy, which is the one carrying Semantics.
      expect(_dryText(_instruction), findsOneWidget);
      expect(_dryText(_nextInstruction), findsOneWidget);
      expect(_dryText('02:14 / 04:00'), findsOneWidget);
      expect(
        find.text('02:14 / 04:00'),
        findsNWidgets(2),
        reason: 'both copies are laid out; only their colours differ',
      );
      // The step counter belongs to the app bar alone; rendering it here too
      // repeated it on one screen.
      expect(find.textContaining('Step 3/5'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('PourLiquidPainter levels', () {
    for (final level in [0.0, 0.5, 1.0]) {
      testWidgets('level $level paints without throwing', (tester) async {
        _setSurface(tester, const Size(375, 812));
        await tester.pumpWidget(_wrap(_view(level: level)));

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('stable tree shape', () {
    testWidgets(
      'a null nextInstruction yields the same column child count as a '
      'non-null one',
      (tester) async {
        _setSurface(tester, const Size(375, 812));
        await tester.pumpWidget(_wrap(_view()));
        final withNext = _stepsContentChildCount(tester);

        await tester.pumpWidget(_wrap(_view(nextInstruction: null)));
        final withoutNext = _stepsContentChildCount(tester);

        expect(withNext, withoutNext);
        expect(withoutNext, greaterThan(0));
      },
    );

    testWidgets('toggling nextInstruction never remounts the countdown', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      var mounts = 0;

      PourBrewingView build(String? next) => PourBrewingView(
        instruction: _instruction,
        nextInstruction: next,
        countdownBuilder: (_) =>
            _MountCountingCountdown(onMount: () => mounts++),
        elapsedText: '02:14',
        totalText: '04:00',
        level: 0.5,
        wavePhase: 1.0,
        waveAmplitude: 6.0,
        fillColor: AppBrewColors.brewFill(lightColorScheme),
        isPaused: false,
        pausedLabel: 'Paused',
        opacity: 1.0,
      );

      await tester.pumpWidget(_wrap(build(_nextInstruction)));
      // Two mounts, not one: the content is laid out twice (dry copy plus
      // the white copy clipped to the liquid), so the countdown builder runs
      // once per copy. What this test guards is that the number never grows
      // afterwards.
      expect(mounts, 2);
      final int mountsAfterFirstBuild = mounts;

      await tester.pumpWidget(_wrap(build(null)));
      await tester.pumpWidget(_wrap(build(_nextInstruction)));

      // Same tree position the whole time: no remount on either toggle.
      expect(
        mounts,
        mountsAfterFirstBuild,
        reason: 'toggling the next-step slot remounted the countdown — the '
            'slot must collapse to SizedBox.shrink(), never be removed',
      );
    });
  });

  group('semantics identifiers', () {
    testWidgets('exposes all four load-bearing identifiers', (tester) async {
      _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(_wrap(_view()));

      expect(_semanticsWithId('brewingStepDescription'), findsOneWidget);
      expect(_semanticsWithId('circularProgressIndicator'), findsOneWidget);
      expect(_semanticsWithId('brewingStepsContent'), findsOneWidget);
      expect(_semanticsWithId('brewPausedIndicator'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the paused slot renders empty while running', (tester) async {
      _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(_wrap(_view(isPaused: false)));

      // The slot is always present, but renders as an empty box while
      // running. Asserted structurally — a zero-size, childless SizedBox —
      // rather than by widget-instance equality.
      expect(_semanticsWithId('brewPausedIndicator'), findsOneWidget);
      expect(find.text('Paused'), findsNothing);
      final slot = tester.widget<Semantics>(
        _semanticsWithId('brewPausedIndicator'),
      );
      final emptySlot = slot.child! as SizedBox;
      expect(emptySlot.child, isNull);
      expect(emptySlot.width ?? 0, 0);
      expect(emptySlot.height ?? 0, 0);
      expect(tester.getSize(_semanticsWithId('brewPausedIndicator')).height, 0);
    });

    testWidgets('the paused slot renders the label while paused', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(_wrap(_view(isPaused: true)));

      expect(_dryText('Paused'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('contrast', () {
    test('white on brewFill clears WCAG AA in both themes', () {
      // Computed from relative luminance per WCAG 2.x, not hardcoded.
      expect(
        _contrastRatio(Colors.white, AppBrewColors.brewFill(lightColorScheme)),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(Colors.white, AppBrewColors.brewFill(darkColorScheme)),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('PourLiquidPainter.shouldRepaint', () {
    final fillColor = AppBrewColors.brewFill(lightColorScheme);
    final otherFill = AppBrewColors.brewFill(darkColorScheme);

    PourLiquidPainter painter({
      double level = 0.5,
      double wavePhase = 1.0,
      double waveAmplitude = 6.0,
      Color? fill,
    }) => PourLiquidPainter(
      level: level,
      wavePhase: wavePhase,
      waveAmplitude: waveAmplitude,
      fillColor: fill ?? fillColor,
    );

    test('returns false when nothing changed', () {
      expect(painter().shouldRepaint(painter()), isFalse);
    });

    test('returns true when any single field changes', () {
      expect(painter(level: 0.6).shouldRepaint(painter()), isTrue);
      expect(painter(wavePhase: 2.0).shouldRepaint(painter()), isTrue);
      expect(painter(waveAmplitude: 0.0).shouldRepaint(painter()), isTrue);
      expect(painter(fill: otherFill).shouldRepaint(painter()), isTrue);
    });
  });
}
