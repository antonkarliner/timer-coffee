import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coffee_timer/widgets/new_beans/loading_overlay.dart';

/// Pumps [overlay] inside a minimal MaterialApp using [brightness].
Future<void> _pump(
  WidgetTester tester,
  LoadingOverlay overlay, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Stack(children: [overlay])),
    ),
  );
}

void main() {
  group('LoadingOverlay', () {
    testWidgets('shows the heading on its own when no detail is given', (
      tester,
    ) async {
      await _pump(tester, const LoadingOverlay(label: 'Saving…'));

      expect(find.text('Saving…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the current stage detail alongside the heading', (
      tester,
    ) async {
      await _pump(
        tester,
        const LoadingOverlay(
          label: 'Analyzing',
          detail: 'Reading the label…',
        ),
      );

      expect(find.text('Analyzing'), findsOneWidget);
      expect(find.text('Reading the label…'), findsOneWidget);
    });

    testWidgets('detail updates when the real stage advances', (tester) async {
      await _pump(
        tester,
        const LoadingOverlay(label: 'Analyzing', detail: 'Preparing photos…'),
      );
      expect(find.text('Preparing photos…'), findsOneWidget);

      await _pump(
        tester,
        const LoadingOverlay(label: 'Analyzing', detail: 'Reading the label…'),
      );
      await tester.pump();

      expect(find.text('Preparing photos…'), findsNothing);
      expect(find.text('Reading the label…'), findsOneWidget);
    });

    testWidgets('reassurance is hidden until the real threshold elapses', (
      tester,
    ) async {
      await _pump(
        tester,
        const LoadingOverlay(
          label: 'Analyzing',
          reassurance: 'Still working…',
          reassuranceDelay: Duration(seconds: 10),
        ),
      );

      // Not shown immediately — it must be earned by actual elapsed time.
      expect(find.text('Still working…'), findsNothing);

      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Still working…'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Still working…'), findsOneWidget);
    });

    testWidgets('no reassurance timer runs when no reassurance is given', (
      tester,
    ) async {
      await _pump(tester, const LoadingOverlay(label: 'Saving…'));
      await tester.pump(const Duration(seconds: 30));

      // Would throw a pending-timer error on teardown if one were scheduled.
      expect(find.text('Saving…'), findsOneWidget);
    });

    testWidgets('offers no cancel affordance', (tester) async {
      // The scan cannot actually be aborted server-side, so the overlay must
      // not present an action implying it can be.
      await _pump(
        tester,
        const LoadingOverlay(
          label: 'Analyzing',
          detail: 'Reading the label…',
          reassurance: 'Still working…',
        ),
      );

      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders in dark mode', (tester) async {
      await _pump(
        tester,
        const LoadingOverlay(
          label: 'Analyzing',
          detail: 'Reading the label…',
        ),
        brightness: Brightness.dark,
      );

      expect(find.text('Analyzing'), findsOneWidget);
      expect(find.text('Reading the label…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
