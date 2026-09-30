import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/date_field.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders error text once with a five-line limit', (tester) async {
    const error = 'Please enter a valid email address.';

    await tester.pumpWidget(
      host(const LabeledField(label: 'Email', errorText: error)),
    );

    final errorFinder = find.text(error);
    expect(errorFinder, findsOneWidget);
    expect(tester.widget<Text>(errorFinder).maxLines, 5);
  });

  testWidgets('renders one complete long error in a narrow field', (
    tester,
  ) async {
    const error =
        'Please enter a valid email address that includes a complete user name '
        'and domain so we can contact you about important changes to your '
        'account settings.';

    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 200,
          child: LabeledField(label: 'Email', errorText: error),
        ),
      ),
    );

    expect(find.text(error), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies semantic identifier only when provided', (tester) async {
    await tester.pumpWidget(
      host(const LabeledField(label: 'Named', semanticIdentifier: 'myField')),
    );

    expect(find.bySemanticsIdentifier('myField'), findsOneWidget);

    await tester.pumpWidget(host(const LabeledField(label: 'Unnamed')));

    expect(find.bySemanticsIdentifier('myField'), findsNothing);
  });

  testWidgets('DateField exposes its semantic identifier once', (tester) async {
    await tester.pumpWidget(
      host(const DateField(label: 'Date', semanticIdentifier: 'myDateField')),
    );

    expect(find.bySemanticsIdentifier('myDateField'), findsOneWidget);
  });
}
