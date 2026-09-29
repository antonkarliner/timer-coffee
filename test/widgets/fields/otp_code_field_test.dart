import 'package:coffee_timer/widgets/fields/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('typing digits fills cells in order', (tester) async {
    await tester.pumpWidget(_app(const OtpCodeField(label: 'Code')));

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('rejects non-digits', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(OtpCodeField(controller: controller)));

    await tester.enterText(find.byType(TextField), 'a1b2');
    await tester.pump();

    expect(controller.text, '12');
  });

  testWidgets('normalizes pasted separators before applying the length limit', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(OtpCodeField(controller: controller)));

    await tester.enterText(find.byType(TextField), '12 34-56');
    await tester.pump();

    expect(controller.text, '123456');
  });

  testWidgets('calls onCompleted once when six digits are reached', (
    tester,
  ) async {
    final completedCodes = <String>[];
    await tester.pumpWidget(
      _app(OtpCodeField(onCompleted: completedCodes.add)),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump();

    expect(completedCodes, ['123456']);
  });

  testWidgets('keeps the caret at the end so typing appends', (tester) async {
    final controller = TextEditingController(text: '123');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(OtpCodeField(controller: controller)));

    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection.collapsed(offset: 1);
    expect(controller.selection, const TextSelection.collapsed(offset: 3));

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '1234',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();

    expect(controller.text, '1234');
  });

  testWidgets('renders error text', (tester) async {
    await tester.pumpWidget(
      _app(const OtpCodeField(errorText: 'Code expired')),
    );

    expect(find.text('Code expired'), findsOneWidget);
  });

  testWidgets('shows text from an external controller', (tester) async {
    final controller = TextEditingController(text: '654321');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(OtpCodeField(controller: controller)));

    for (final digit in '654321'.split('')) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('lays out without overflow at 280dp width', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 280,
          child: OtpCodeField(label: 'Verification code'),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
