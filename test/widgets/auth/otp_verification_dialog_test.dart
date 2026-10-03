import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/otp_code_field.dart';
import 'package:coffee_timer/widgets/recipe_detail/authentication_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _email = 'coffee@example.com';

Future<void> _openDialog(
  WidgetTester tester,
  Future<String?> Function(String, String) onSubmitted,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => AppTextButton(
            label: 'Open',
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => OTPVerificationDialog(
                email: _email,
                onOTPSubmitted: onSubmitted,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('six digits submit once and success closes the dialog', (
    tester,
  ) async {
    final result = Completer<String?>();
    final submissions = <(String, String)>[];
    await _openDialog(tester, (email, token) {
      submissions.add((email, token));
      return result.future;
    });

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump();

    expect(submissions, [(_email, '123456')]);
    expect(find.byType(OTPVerificationDialog), findsOneWidget);
    expect(
      tester.widget<OtpCodeField>(find.byType(OtpCodeField)).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<AppElevatedButton>(find.byType(AppElevatedButton))
          .isLoading,
      isTrue,
    );
    final cancel = find.widgetWithText(AppTextButton, 'Cancel');
    expect(tester.widget<AppTextButton>(cancel).onPressed, isNull);

    result.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(OTPVerificationDialog), findsNothing);
    expect(submissions, hasLength(1));
  });

  testWidgets('wrong code stays open, clears and refocuses for a retry', (
    tester,
  ) async {
    final result = Completer<String?>();
    final tokens = <String>[];
    await _openDialog(tester, (_, token) {
      tokens.add(token);
      return result.future;
    });

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    final originalState = tester.state(find.byType(OtpCodeField));
    result.complete('Invalid code');
    await tester.pumpAndSettle();

    expect(find.byType(OTPVerificationDialog), findsOneWidget);
    expect(find.text('Invalid code'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.state(find.byType(OtpCodeField)), same(originalState));

    // Clearing resets completion tracking, so the same code can be retried.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(tokens, ['123456', '123456']);
  });

  testWidgets('five digits do not submit', (tester) async {
    var calls = 0;
    await _openDialog(tester, (_, _) async {
      calls++;
      return null;
    });

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.byType(OTPVerificationDialog), findsOneWidget);
  });
}
