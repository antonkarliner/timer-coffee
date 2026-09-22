import 'dart:math' as math;

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
    nextLabel: 'Next:',
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

    testWidgets('renders the instruction and the next-step preview', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(_wrap(_view()));

      // Each string appears twice — once in the dry copy and once in the
      // submerged copy clipped to the liquid — so assertions are scoped to
      // the dry copy, which is the one carrying Semantics.
      expect(_dryText(_instruction), findsOneWidget);
      expect(_dryText('Next:'), findsOneWidget);
      expect(_dryText(_nextInstruction), findsOneWidget);
      expect(
        find.text(_instruction),
        findsNWidgets(2),
        reason: 'both copies are laid out; only their colours differ',
      );
      // The step counter belongs to the app bar alone, and there is no
      // elapsed/total readout: the liquid is the only whole-brew indicator.
      expect(find.textContaining('Step 3/5'), findsNothing);
      expect(find.textContaining(' / '), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'follows the production hierarchy: countdown, then instruction, then '
      'next step',
      (tester) async {
        // Guards the order itself. An earlier version put the instruction
        // above the countdown, inverting the production screen's logic —
        // time is what moves and presses, so it leads.
        _setSurface(tester, const Size(375, 812));
        await tester.pumpWidget(_wrap(_view()));

        final double countdownY = tester
            .getTopLeft(_semanticsWithId('stepTimeCounter'))
            .dy;
        final double instructionY = tester
            .getTopLeft(_semanticsWithId('brewingStepDescription'))
            .dy;
        final double nextY = tester.getTopLeft(_dryText(_nextInstruction)).dy;

        expect(countdownY, lessThan(instructionY));
        expect(instructionY, lessThan(nextY));
      },
    );

    testWidgets('a longer instruction does not move the countdown', (
      tester,
    ) async {
      // The layout-shift guard: the countdown is anchored to a fixed region
      // boundary, so a step whose instruction wraps to more lines must leave
      // the numbers exactly where they were.
      _setSurface(tester, const Size(375, 812));
      await tester.pumpWidget(_wrap(_view(instruction: 'Wait.')));
      final Offset shortY = tester.getTopLeft(
        _semanticsWithId('stepTimeCounter'),
      );

      await tester.pumpWidget(_wrap(_view(instruction: _longInstruction)));
      final Offset longY = tester.getTopLeft(
        _semanticsWithId('stepTimeCounter'),
      );

      expect(longY, shortY);
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

  group('one tap is one tap', () {
    // The content is laid out twice — a dry copy and a submerged copy on top
    // of it, clipped to the liquid — so every interactive slot exists twice,
    // stacked at the same position. A tap must reach exactly one of them, or
    // a single press on "next step" would skip two steps. Checked with the
    // arrow dry, straddling the surface, and fully submerged.
    for (final level in [0.0, 0.5, 1.0]) {
      testWidgets('a tap on the step arrow fires once at level $level', (
        tester,
      ) async {
        _setSurface(tester, const Size(375, 812));
        var taps = 0;
        await tester.pumpWidget(
          _wrap(
            PourBrewingView(
              instruction: _instruction,
              nextLabel: 'Next:',
              nextInstruction: _nextInstruction,
              countdownBuilder: _countdown(),
              level: level,
              wavePhase: 1.0,
              waveAmplitude: 6.0,
              fillColor: AppBrewColors.brewFill(lightColorScheme),
              isPaused: false,
              pausedLabel: 'Paused',
              opacity: 1.0,
              trailing: (Color color) => IconButton(
                onPressed: () => taps++,
                icon: Icon(Icons.chevron_right, color: color),
              ),
            ),
          ),
        );

        // Both copies render the icon; they share one position, so tapping
        // it sends one real pointer event through normal hit testing.
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
        await tester.tap(find.byIcon(Icons.chevron_right).first);
        await tester.pump();

        expect(taps, 1);
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
        nextLabel: 'Next:',
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

    testWidgets(
      'the paused label is hidden while running but keeps its space, so '
      'pausing does not move the countdown',
      (tester) async {
        // The countdown is bottom-anchored above the paused label, so a label
        // that collapsed to nothing would push the numbers up on every
        // pause. It is a Visibility that maintains its size instead.
        _setSurface(tester, const Size(375, 812));
        await tester.pumpWidget(_wrap(_view(isPaused: false)));

        expect(_semanticsWithId('brewPausedIndicator'), findsOneWidget);
        final visibility = tester.widget<Visibility>(
          find.descendant(
            of: _semanticsWithId('brewPausedIndicator'),
            matching: find.byType(Visibility),
          ),
        );
        expect(visibility.visible, isFalse);
        expect(visibility.maintainSize, isTrue);
        final Offset runningY = tester.getTopLeft(
          _semanticsWithId('stepTimeCounter'),
        );

        await tester.pumpWidget(_wrap(_view(isPaused: true)));
        final Offset pausedY = tester.getTopLeft(
          _semanticsWithId('stepTimeCounter'),
        );

        expect(pausedY, runningY);
      },
    );

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
      double? dropProgress,
      double? rippleProgress,
    }) => PourLiquidPainter(
      level: level,
      wavePhase: wavePhase,
      waveAmplitude: waveAmplitude,
      fillColor: fill ?? fillColor,
      dropProgress: dropProgress,
      rippleProgress: rippleProgress,
    );

    test('returns false when nothing changed', () {
      expect(painter().shouldRepaint(painter()), isFalse);
    });

    test('returns true when any single field changes', () {
      expect(painter(level: 0.6).shouldRepaint(painter()), isTrue);
      expect(painter(wavePhase: 2.0).shouldRepaint(painter()), isTrue);
      expect(painter(waveAmplitude: 0.0).shouldRepaint(painter()), isTrue);
      expect(painter(fill: otherFill).shouldRepaint(painter()), isTrue);
      expect(painter(dropProgress: 0.3).shouldRepaint(painter()), isTrue);
      expect(painter(rippleProgress: 0.3).shouldRepaint(painter()), isTrue);
    });
  });

  group('the last drop', () {
    for (final (label, drop, ripple) in [
      ('drop falling', 0.5, null),
      ('drop about to land', 0.99, null),
      ('ripple just started', null, 0.01),
      ('ripple spreading', null, 0.5),
    ]) {
      testWidgets('paints without throwing: $label', (tester) async {
        _setSurface(tester, const Size(375, 812));
        await tester.pumpWidget(
          _wrap(
            PourBrewingView(
              instruction: _instruction,
              nextLabel: 'Next:',
              nextInstruction: null,
              countdownBuilder: _countdown(),
              level: 0.85,
              wavePhase: 1.0,
              waveAmplitude: 0.0,
              fillColor: AppBrewColors.brewFill(lightColorScheme),
              isPaused: false,
              pausedLabel: 'Paused',
              opacity: 1.0,
              dropProgress: drop,
              rippleProgress: ripple,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    test('a full cup stops headroom px below the top of the canvas', () {
      const size = Size(400, 800);
      // Full: the surface sits exactly `headroom` px down.
      expect(size.height * (1 - pourCanvasLevel(1.0, 32, size)), closeTo(32, 1e-9));
      // Empty stays empty; halfway is halfway through the fillable height.
      expect(pourCanvasLevel(0.0, 32, size), 0);
      expect(
        size.height * pourCanvasLevel(0.5, 32, size),
        closeTo((800 - 32) / 2, 1e-9),
      );
      // No headroom is the plain level.
      expect(pourCanvasLevel(0.7, 0, size), 0.7);
    });

    test('the ripple dips at the impact, spreads out and dies away', () {
      const size = Size(400, 800);
      // At impact the drop punches a dip, ringed by raised water.
      expect(pourRippleOffset(200, size, 0.0), lessThan(0));
      expect(pourRippleOffset(200 + 23, size, 0.0), greaterThan(0));
      // Shortly after, the impact point has sprung back up.
      expect(pourRippleOffset(200, size, 0.1), greaterThan(0));
      // By the end it has faded to nothing everywhere.
      for (final x in [0.0, 100.0, 200.0, 300.0, 400.0]) {
        expect(pourRippleOffset(x, size, 1.0), closeTo(0, 1e-9));
      }
      // Mid-way, the two fronts have moved out symmetrically.
      expect(
        pourRippleOffset(200 - 100, size, 0.5),
        closeTo(pourRippleOffset(200 + 100, size, 0.5), 1e-9),
      );
      // The packets flatten as they travel: the highest point on the surface
      // is lower late on than early.
      double peak(double p) => [
        for (double x = 0; x <= 400; x += 1) pourRippleOffset(x, size, p).abs(),
      ].reduce(math.max);
      expect(peak(0.6), lessThan(peak(0.2)));
    });
  });
}
