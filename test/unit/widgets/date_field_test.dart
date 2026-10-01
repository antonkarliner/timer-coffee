import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const initialValue = '2026-10-01T00:00:00.000';

  Widget app({
    required String datePattern,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: DateField(
          label: 'Date',
          initialValue: initialValue,
          datePattern: datePattern,
        ),
      ),
    );
  }

  String displayedText(WidgetTester tester) {
    return tester
            .widget<TextFormField>(
              find.descendant(
                of: find.byType(DateField),
                matching: find.byType(TextFormField),
              ),
            )
            .controller
            ?.text ??
        '';
  }

  testWidgets('displays explicit numeric date patterns', (tester) async {
    const expectations = {
      'dd/MM/yyyy': '01/10/2026',
      'MM/dd/yyyy': '10/01/2026',
      'yyyy-MM-dd': '2026-10-01',
    };

    for (final entry in expectations.entries) {
      await tester.pumpWidget(app(datePattern: entry.key));
      await tester.pumpAndSettle();

      expect(displayedText(tester), entry.value);
    }
  });

  testWidgets('displays the English app Auto date style', (tester) async {
    await tester.pumpWidget(app(datePattern: 'MMM d, yyyy'));
    await tester.pumpAndSettle();

    expect(displayedText(tester), 'Oct 1, 2026');
  });

  testWidgets('uses the app locale for German month names', (tester) async {
    await tester.pumpWidget(
      app(
        datePattern: 'd. MMM yyyy',
        locale: const Locale('de'),
      ),
    );
    await tester.pumpAndSettle();

    expect(displayedText(tester), '1. Okt. 2026');
  });

  testWidgets('updates the display when datePattern changes', (tester) async {
    await tester.pumpWidget(app(datePattern: 'dd/MM/yyyy'));
    await tester.pumpAndSettle();
    expect(displayedText(tester), '01/10/2026');

    await tester.pumpWidget(app(datePattern: 'yyyy-MM-dd'));
    await tester.pumpAndSettle();

    expect(displayedText(tester), '2026-10-01');
  });
}
