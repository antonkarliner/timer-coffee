import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/recipe_detail/authentication_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    );
  }

  testWidgets('an empty label reserves no space above the field', (tester) async {
    await tester.pumpWidget(host(const LabeledField(label: '')));

    final input = find.byType(TextField);
    expect(
      find.byWidgetPredicate((widget) => widget is Text && widget.data == ''),
      findsNothing,
    );
    expect(tester.widget<TextField>(input).decoration!.labelText, isNull);
    expect(
      tester.getSize(find.byType(LabeledField)).height,
      tester.getSize(input).height,
    );
  });

  testWidgets('an empty inside label has no decoration label', (tester) async {
    await tester.pumpWidget(
      host(const LabeledField(label: '', labelInsideField: true)),
    );

    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.decoration!.labelText, isNull);
  });

  testWidgets('a non-empty label still renders above the field', (tester) async {
    await tester.pumpWidget(host(const LabeledField(label: 'Name')));

    final label = find.text('Name');
    expect(label, findsOneWidget);
    expect(
      tester.getBottomLeft(label).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('the email dialog submits text from its LabeledField', (
    tester,
  ) async {
    String? submittedEmail;
    final page = Builder(
      builder: (context) => TextButton(
        onPressed: () => AuthenticationDialogs.showEmailSignInDialog(
          context,
          (email) => submittedEmail = email,
        ),
        child: const Text('Open email dialog'),
      ),
    );
    await tester.pumpWidget(host(page));
    await tester.tap(find.text('Open email dialog'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final field = find.descendant(of: dialog, matching: find.byType(LabeledField));
    final input = find.descendant(of: field, matching: find.byType(TextField));
    expect(field, findsOneWidget);
    expect(input, findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(input).keyboardType,
      TextInputType.emailAddress,
    );

    const email = 'brewer@example.com';
    final controller = tester.widget<LabeledField>(field).controller!;
    await tester.enterText(input, email);
    expect(controller.text, email);

    await tester.pumpWidget(host(page, locale: const Locale('fr')));
    await tester.pumpAndSettle();
    expect(tester.widget<LabeledField>(field).controller, same(controller));
    final l10n = AppLocalizations.of(tester.element(dialog))!;
    await tester.tap(find.text(l10n.sendOTP));
    await tester.pumpAndSettle();

    expect(submittedEmail, email);
    expect(dialog, findsNothing);
  });
}
