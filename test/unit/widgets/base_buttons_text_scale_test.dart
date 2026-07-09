import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longLabel = 'Start the brewing timer now';

Widget _wrap(Widget child, {TextScaler textScaler = TextScaler.noScaling}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('AppElevatedButton at large text scale', () {
    testWidgets('plain label does not throw or overflow at scale 2.0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppElevatedButton(
            label: _longLabel,
            onPressed: () {},
          ),
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('icon variant does not throw or overflow at scale 2.0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppElevatedButton(
            label: _longLabel,
            icon: Icons.timer,
            onPressed: () {},
          ),
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at heightMedium at scale 1.0', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppElevatedButton(
            label: 'Start',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final size = tester.getSize(find.byType(AppElevatedButton));
      expect(size.height, AppButton.heightMedium);
    });
  });

  group('AppTextButton at large text scale', () {
    testWidgets('plain label does not throw or overflow at scale 2.0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppTextButton(
            label: _longLabel,
            onPressed: () {},
          ),
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('icon variant does not throw or overflow at scale 2.0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppTextButton(
            label: _longLabel,
            icon: Icons.timer,
            onPressed: () {},
          ),
          textScaler: const TextScaler.linear(2.0),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
