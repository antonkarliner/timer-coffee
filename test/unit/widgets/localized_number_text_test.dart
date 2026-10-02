import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/brewing/localized_number_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The brewing countdown formats with the app locale. `NumberFormat()` with
/// no locale is always en_US here (Flutter never sets `Intl.defaultLocale`),
/// which put Latin digits on the fa brewing screen.
void main() {
  Future<void> pump(WidgetTester tester, Locale locale) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(
          body: LocalizedNumberText(currentNumber: 15, totalNumber: 30),
        ),
      ),
    );
  }

  testWidgets('en: Latin digits, slash', (tester) async {
    await pump(tester, const Locale('en'));
    expect(find.text('15/30'), findsOneWidget);
  });

  testWidgets('fa: Persian digits, backslash for RTL', (tester) async {
    await pump(tester, const Locale('fa'));
    expect(find.text('۱۵\\۳۰'), findsOneWidget);
  });

  testWidgets('ar: Latin digits (intl ar number symbols), backslash for RTL',
      (tester) async {
    await pump(tester, const Locale('ar'));
    expect(find.text('15\\30'), findsOneWidget);
  });
}
