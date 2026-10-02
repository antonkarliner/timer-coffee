import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/utils/date_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// ar dates match ar counts (Latin digits); fa keeps Persian digits for both.
///
/// Rendered inside a localized MaterialApp on purpose: the Arabic-Indic ar
/// digits come from flutter_localizations' date symbols, which intl's own
/// `initializeDateFormatting` would not reproduce.
void main() {
  final date = DateTime(2026, 10, 2);

  Future<String> renderDate(WidgetTester tester, String locale) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        home: Builder(
          builder: (context) => Text(
            DateFormat(
              'dd/MM/yyyy',
              Localizations.localeOf(context).toString(),
            ).format(date),
          ),
        ),
      ),
    );
    return tester.widget<Text>(find.byType(Text)).data!;
  }

  // The default is process-wide; put it back for other tests in this isolate.
  tearDown(() => DateFormat.useNativeDigitsByDefaultFor('ar', true));

  testWidgets('without it, ar dates use Arabic-Indic digits', (tester) async {
    expect(await renderDate(tester, 'ar'), '٠٢/١٠/٢٠٢٦');
  });

  testWidgets('with it, ar dates use Latin digits like ar counts',
      (tester) async {
    configureDateDigits();
    expect(await renderDate(tester, 'ar'), '02/10/2026');
    expect(
      lookupAppLocalizations(const Locale('ar')).settingsMethodsShownCount(
        11,
        30,
      ),
      'الطرق: 11 من 30',
    );
  });

  testWidgets('fa keeps Persian digits for dates and counts', (tester) async {
    configureDateDigits();
    expect(await renderDate(tester, 'fa'), '۰۲/۱۰/۲۰۲۶');
    expect(
      lookupAppLocalizations(const Locale('fa')).settingsMethodsShownCount(
        11,
        30,
      ),
      '۱۱ از ۳۰ روش',
    );
  });
}
