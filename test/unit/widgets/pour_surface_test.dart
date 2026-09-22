import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/brewing/brew_fill_ring_painter.dart';
import 'package:coffee_timer/widgets/brewing/pour_brewing_view.dart';
import 'package:coffee_timer/widgets/brewing/pour_liquid_painter.dart';
import 'package:coffee_timer/widgets/brewing/pour_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for the Pour surface repaint split: wave ticks repaint the
// liquid painter and reclip the text clipper through PourSurfaceController,
// without rebuilding the content subtrees; the text clip and the liquid fill
// share one primary path per frame snapshot; the controller is owned (and
// disposed) by the caller, never by the view.

const String _instruction = 'Pour 60 grams in a slow spiral';
const String _nextInstruction = 'Wait for the drawdown to finish';

final Color _fill = AppBrewColors.brewFill(lightColorScheme);

PourSurfaceFrame _frame({
  double level = 0.5,
  double wavePhase = 1.0,
  double waveAmplitude = 6.0,
  double? dropProgress,
  double? rippleProgress,
  double headroom = 32,
}) => PourSurfaceFrame(
  level: level,
  wavePhase: wavePhase,
  waveAmplitude: waveAmplitude,
  dropProgress: dropProgress,
  rippleProgress: rippleProgress,
  headroom: headroom,
);

Widget _view({
  PourSurfaceController? surface,
  String instruction = _instruction,
}) {
  return PourBrewingView(
    instruction: instruction,
    nextLabel: 'Next:',
    nextInstruction: _nextInstruction,
    countdownBuilder: (Color color) =>
        Text('128', style: TextStyle(fontSize: 72, color: color)),
    level: 0.5,
    wavePhase: 1.0,
    waveAmplitude: 6.0,
    fillColor: _fill,
    isPaused: false,
    pausedLabel: 'Paused',
    opacity: 1.0,
    bottomClearance: 96,
    headroom: 32,
    surface: surface,
  );
}

Widget _wrap(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: MaterialApp(
      theme: ThemeData(colorScheme: lightColorScheme),
      home: Scaffold(body: child),
    ),
  );
}

// Scoped to the view: MaterialApp's debug CheckedModeBanner is a CustomPaint
// too, so bare byType lookups would match more than the liquid.
final Finder _liquidPaint = find.descendant(
  of: find.byType(PourBrewingView),
  matching: find.byType(CustomPaint),
);
final Finder _liquidClip = find.descendant(
  of: find.byType(PourBrewingView),
  matching: find.byType(ClipPath),
);

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The ripple formula exactly as it read before the per-frame coefficients
/// were hoisted into PourRippleField — constants and operation order
/// included. The hoisting must not move a decimal point.
double _originalRippleFormula(double x, Size size, double p) {
  const double dropX = 0.5;
  const double amplitude = 8.0;
  const double reach = 0.55;
  const double packetWidth = 28.0;
  const double wavelength = 46.0;
  const double spread = 1.2;
  const double stretch = 0.5;
  const double bobAmplitude = 6.0;
  const double bobWidth = 16.0;
  const double bobCycles = 2.5;

  final double impactX = size.width * dropX;
  final double fromImpact = x - impactX;
  final double width = packetWidth * (1 + spread * p);
  final double length = wavelength * (1 + stretch * p);
  final double travelled = size.width * reach * p;
  final double distance = fromImpact.abs() - travelled;
  final double envelope = math.exp(
    -(distance * distance) / (2 * width * width),
  );
  final double spreadLoss = math.sqrt(packetWidth / width);
  final double fade = math.pow(1 - p, 1.5).toDouble();
  final double outgoing =
      -amplitude *
      fade *
      spreadLoss *
      envelope *
      math.cos(2 * math.pi * distance / length);
  final double bob =
      bobAmplitude *
      (1 - p) *
      math.exp(-4 * p) *
      math.exp(-(fromImpact * fromImpact) / (2 * bobWidth * bobWidth)) *
      math.sin(2 * math.pi * bobCycles * p);
  return outgoing + bob;
}

class _TextPaintProbe extends CustomPainter {
  _TextPaintProbe(this.onPaint);
  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) => onPaint();

  @override
  bool shouldRepaint(covariant _TextPaintProbe oldDelegate) => false;
}

void main() {
  group('ripple geometry is unchanged by the coefficient hoisting', () {
    const Size size = Size(375, 812);

    test('matches the original formula sample-for-sample', () {
      for (final double p in const [0.0, 0.1, 0.35, 0.5, 0.8, 0.99]) {
        for (double x = 0; x <= size.width; x += 17) {
          expect(
            pourRippleOffset(x, size, p),
            closeTo(_originalRippleFormula(x, size, p), 1e-9),
            reason: 'p=$p x=$x',
          );
          expect(
            PourRippleField.of(size, p).offsetAt(x),
            closeTo(_originalRippleFormula(x, size, p), 1e-9),
            reason: 'field p=$p x=$x',
          );
        }
      }
    });

    test('still dies away to exactly zero at progress 1', () {
      for (double x = 0; x <= size.width; x += 13) {
        expect(pourRippleOffset(x, size, 1.0), 0);
      }
    });
  });

  group('PourSurfaceFrame', () {
    test('compares by value', () {
      expect(_frame(), _frame());
      expect(_frame().hashCode, _frame().hashCode);
      expect(_frame(), isNot(_frame(level: 0.6)));
      expect(_frame(), isNot(_frame(wavePhase: 2.0)));
      expect(_frame(), isNot(_frame(waveAmplitude: 0.0)));
      expect(_frame(), isNot(_frame(dropProgress: 0.5)));
      expect(_frame(), isNot(_frame(rippleProgress: 0.5)));
      expect(_frame(), isNot(_frame(headroom: 0)));
    });
  });

  group('PourSurfaceController', () {
    test('notifies when the frame changes, not when it is rewritten equal', () {
      final PourSurfaceController controller = PourSurfaceController(_frame());
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.frame = _frame(level: 0.6);
      expect(notifications, 1);

      // Equal values, new object: a redundant rebuild-path write.
      controller.frame = _frame(level: 0.6);
      expect(notifications, 1);
      controller.dispose();
    });

    test('reuses one primary path per frame and size', () {
      final PourSurfaceController controller = PourSurfaceController();
      final PourSurfaceFrame frame = _frame();
      const Size size = Size(375, 812);

      final Path first = controller.primaryPathFor(frame, size);
      // Same frame, same size → the very same object, no rebuild.
      expect(identical(controller.primaryPathFor(frame, size), first), isTrue);

      // A new frame invalidates: a different object with different geometry.
      final Path raised = controller.primaryPathFor(_frame(level: 0.75), size);
      expect(identical(raised, first), isFalse);
      expect(raised.getBounds().top, lessThan(first.getBounds().top));

      // The cache holds only the latest entry: back to the old frame
      // rebuilds, to equal-but-fresh geometry.
      final Path back = controller.primaryPathFor(frame, size);
      expect(identical(back, first), isFalse);
      expect(back.getBounds(), first.getBounds());

      // Same frame, new size invalidates too.
      const Size otherSize = Size(430, 932);
      final Path resized = controller.primaryPathFor(frame, otherSize);
      expect(identical(resized, back), isFalse);
      expect(resized.getBounds().right, closeTo(otherSize.width, 1e-6));
      controller.dispose();
    });

    test('cached path equals a directly built wave path', () {
      final PourSurfaceController controller = PourSurfaceController();
      final PourSurfaceFrame frame = _frame(rippleProgress: 0.4);
      const Size size = Size(375, 812);

      final Rect cached = controller.primaryPathFor(frame, size).getBounds();
      final Rect direct = buildBrewWavePath(
        size: size,
        fillLevel: pourCanvasLevel(frame.level, frame.headroom, size),
        waveAmplitude: frame.waveAmplitude,
        phase: frame.wavePhase,
        surfaceOffset: PourRippleField.of(size, frame.rippleProgress!).offsetAt,
      ).getBounds();

      expect(cached.left, closeTo(direct.left, 1e-6));
      expect(cached.top, closeTo(direct.top, 1e-6));
      expect(cached.right, closeTo(direct.right, 1e-6));
      expect(cached.bottom, closeTo(direct.bottom, 1e-6));
      controller.dispose();
    });

    test('writing a frame after dispose throws', () {
      final PourSurfaceController controller = PourSurfaceController(_frame());
      controller.dispose();
      expect(
        () => controller.frame = _frame(level: 0.9),
        throwsA(isA<Error>()),
      );
    });
  });

  group('animation ticks vs content rebuilds', () {
    testWidgets('a wave tick repaints the surface but rebuilds no content', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      final PourSurfaceController controller = PourSurfaceController(_frame());
      addTearDown(controller.dispose);
      var builds = 0;
      var textPaints = 0;
      await tester.pumpWidget(
        _wrap(
          PourBrewingView(
            instruction: _instruction,
            nextLabel: 'Next:',
            nextInstruction: _nextInstruction,
            // The view lays the content out twice (dry + submerged), so one
            // build of the view calls this exactly twice.
            countdownBuilder: (Color color) {
              builds++;
              return CustomPaint(
                painter: _TextPaintProbe(() => textPaints++),
                child: Text(
                  '128',
                  style: TextStyle(fontSize: 72, color: color),
                ),
              );
            },
            level: 0.5,
            wavePhase: 1.0,
            waveAmplitude: 6.0,
            fillColor: _fill,
            isPaused: false,
            pausedLabel: 'Paused',
            opacity: 1.0,
            surface: controller,
          ),
        ),
      );
      expect(builds, 2);
      final initialTextPaints = textPaints;
      expect(initialTextPaints, 2);

      // An animation-only tick: fresh level and phase, no data change. The
      // content must not rebuild.
      controller.frame = _frame(level: 0.55, wavePhase: 2.0);
      await tester.pump();
      expect(
        builds,
        2,
        reason:
            'a wave tick reached the countdown builder — the liquid '
            'repaint leaked back into a widget rebuild',
      );

      expect(
        textPaints,
        initialTextPaints,
        reason: 'the moving clip must reuse both painted text layers',
      );

      // The painter/clipper did pick the new frame up, though: the clip in
      // the tree is now the cache entry of the NEW frame snapshot.
      final ClipPath clipWidget = tester.widget<ClipPath>(_liquidClip);
      final Size clipSize = tester.getSize(_liquidClip);
      final Path clip = clipWidget.clipper!.getClip(clipSize);
      expect(
        identical(clip, controller.primaryPathFor(controller.frame, clipSize)),
        isTrue,
      );

      // And a genuine data change still rebuilds the content.
      await tester.pumpWidget(
        _wrap(
          PourBrewingView(
            instruction: 'A different step',
            nextLabel: 'Next:',
            nextInstruction: _nextInstruction,
            countdownBuilder: (Color color) {
              builds++;
              return Text('128', style: TextStyle(fontSize: 72, color: color));
            },
            level: 0.55,
            wavePhase: 2.0,
            waveAmplitude: 6.0,
            fillColor: _fill,
            isPaused: false,
            pausedLabel: 'Paused',
            opacity: 1.0,
            surface: controller,
          ),
        ),
      );
      expect(builds, 4);
    });

    testWidgets('frame changes reach the painter and clipper listenables', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      final PourSurfaceController controller = PourSurfaceController(_frame());
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(_view(surface: controller)));

      // These are the exact listenables the render objects subscribe to:
      // CustomPainter's repaint and CustomClipper's reclip both forward to
      // the surface controller.
      var repaints = 0;
      tester
          .widget<CustomPaint>(_liquidPaint)
          .painter!
          .addListener(() => repaints++);
      var reclips = 0;
      tester
          .widget<ClipPath>(_liquidClip)
          .clipper!
          .addListener(() => reclips++);

      controller.frame = _frame(level: 0.6, wavePhase: 1.5);
      expect(repaints, 1, reason: 'the painter repaint wiring is broken');
      expect(reclips, 1, reason: 'the clipper reclip wiring is broken');
    });
  });

  group('the text clip is the liquid fill', () {
    testWidgets('clip and painter share one path, across frames and sizes', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      final PourSurfaceController controller = PourSurfaceController(
        _frame(level: 0.5, rippleProgress: 0.3),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(_view(surface: controller)));

      Path clipInTree() {
        final ClipPath clipWidget = tester.widget<ClipPath>(_liquidClip);
        final Size size = tester.getSize(_liquidClip);
        return clipWidget.clipper!.getClip(size);
      }

      final Size firstSize = tester.getSize(_liquidClip);
      final Path first = clipInTree();
      expect(
        identical(
          first,
          controller.primaryPathFor(controller.frame, firstSize),
        ),
        isTrue,
        reason: 'the clip must be the very Path object the painter fills with',
      );

      // A new frame snapshot: still one shared object.
      controller.frame = _frame(level: 0.7, wavePhase: 2.0);
      await tester.pump();
      final Size secondSize = tester.getSize(_liquidClip);
      expect(
        identical(
          clipInTree(),
          controller.primaryPathFor(controller.frame, secondSize),
        ),
        isTrue,
      );

      // A size change invalidates the cache and stays synchronized.
      _setSurface(tester, const Size(430, 932));
      await tester.pumpWidget(_wrap(_view(surface: controller)));
      final Size newSize = tester.getSize(_liquidClip);
      expect(newSize, const Size(430, 932));
      expect(
        identical(
          clipInTree(),
          controller.primaryPathFor(controller.frame, newSize),
        ),
        isTrue,
      );
    });

    testWidgets('an empty cup clips the submerged copy away entirely', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      final PourSurfaceController controller = PourSurfaceController(
        _frame(level: 0.0),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_wrap(_view(surface: controller)));

      final ClipPath clipWidget = tester.widget<ClipPath>(_liquidClip);
      final Size size = tester.getSize(_liquidClip);
      expect(
        clipWidget.clipper!.getClip(size).computeMetrics().isEmpty,
        isTrue,
      );
    });
  });

  group('reduced-motion and end-state frames', () {
    testWidgets('a flat frame has no crest above the calm surface line', (
      tester,
    ) async {
      // Reduced motion/web shape: amplitude 0, no ripple. The surface is a
      // dead-straight line at the fill height.
      const Size size = Size(375, 812);
      final PourSurfaceController controller = PourSurfaceController(
        _frame(level: 0.5, waveAmplitude: 0.0),
      );
      addTearDown(controller.dispose);
      final double calmSurface =
          size.height * (1 - pourCanvasLevel(0.5, 32, size));
      expect(
        controller.primaryPathFor(controller.frame, size).getBounds().top,
        closeTo(calmSurface, 1e-6),
      );

      // The live wave, for contrast: the crest rises above the calm line.
      final PourSurfaceController live = PourSurfaceController(_frame());
      addTearDown(live.dispose);
      expect(
        live.primaryPathFor(live.frame, size).getBounds().top,
        lessThan(calmSurface - 3),
      );
    });

    test('the painter paints drop and ripple frames without throwing', () {
      final PourSurfaceController controller = PourSurfaceController();
      addTearDown(controller.dispose);

      void paintFrame(PourSurfaceFrame frame) {
        controller.frame = frame;
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        // Live mode: the constructor fields are stale on purpose; the frame
        // is what gets painted.
        PourLiquidPainter(
          level: 0,
          wavePhase: 0,
          waveAmplitude: 0,
          fillColor: _fill,
          surface: controller,
        ).paint(canvas, const Size(375, 812));
        recorder.endRecording().dispose();
      }

      // Live-mode fields-are-stale check: with no surface frame the level-0
      // painter paints nothing; the same painter driven by a frame paints.
      paintFrame(_frame(level: 0.85, waveAmplitude: 0.0, dropProgress: 0.5));
      paintFrame(_frame(level: 0.85, waveAmplitude: 2.0, rippleProgress: 0.4));
    });
  });

  group('surface-mode repaint decisions', () {
    PourLiquidPainter painter({Color? fill, PourSurfaceController? surface}) =>
        PourLiquidPainter(
          level: 0.5,
          wavePhase: 1.0,
          waveAmplitude: 6.0,
          fillColor: fill ?? _fill,
          surface: surface,
        );

    test('live mode repaints on colour or frame-source change only', () {
      final PourSurfaceController controller = PourSurfaceController(_frame());
      addTearDown(controller.dispose);
      // Frame churn is the listenable's job, not shouldRepaint's.
      expect(
        painter(
          surface: controller,
        ).shouldRepaint(painter(surface: controller)),
        isFalse,
      );
      expect(
        painter(surface: controller).shouldRepaint(
          painter(
            surface: controller,
            fill: AppBrewColors.brewFill(darkColorScheme),
          ),
        ),
        isTrue,
      );
      final PourSurfaceController other = PourSurfaceController(_frame());
      addTearDown(other.dispose);
      expect(
        painter(surface: controller).shouldRepaint(painter(surface: other)),
        isTrue,
      );
      // Switching between live and static modes must repaint.
      expect(painter(surface: controller).shouldRepaint(painter()), isTrue);
      expect(painter().shouldRepaint(painter(surface: controller)), isTrue);
    });

    test('static mode keeps the constructor-field semantics', () {
      expect(painter().shouldRepaint(painter()), isFalse);
      expect(
        painter().shouldRepaint(
          painter(fill: AppBrewColors.brewFill(darkColorScheme)),
        ),
        isTrue,
      );
    });
  });

  group('lifecycle', () {
    testWidgets('unmounting the view does not dispose the controller', (
      tester,
    ) async {
      _setSurface(tester, const Size(375, 812));
      final PourSurfaceController controller = PourSurfaceController(_frame());
      await tester.pumpWidget(_wrap(_view(surface: controller)));

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));

      // The controller is the caller's; the view must have detached quietly.
      final PourSurfaceFrame next = _frame(level: 0.8);
      controller.frame = next;
      expect(controller.frame, next);
      controller.dispose();
    });
  });
}
