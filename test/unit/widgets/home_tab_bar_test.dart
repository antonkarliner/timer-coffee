import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/home_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the main screen's bottom tab bar against the overflow found on
/// 2026-10-02 (plan 077 Phase 13, row 2): in German at the largest standard
/// iOS text size (a text scale of about 1.35) the three tabs reported
/// "BOTTOM OVERFLOWED BY 11 / 36 / 5 PIXELS". The bar is a fixed 50 pt high;
/// long labels wrapped to two lines, and even one line at that scale was
/// taller than the space left under the icon.
///
/// The bar is pumped on its own: it needs only a theme and localizations,
/// none of HomeScreen's providers.
void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required Locale locale,
    required double textScale,
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(bottomNavigationBar: HomeTabBar(onTap: (_) {})),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> labelsFor(Locale locale) {
    final l10n = lookupAppLocalizations(locale);
    return [l10n.homescreenbrewcoffee, l10n.myBeans, l10n.homescreenmore];
  }

  group('HomeTabBar', () {
    testWidgets('de at text scale 1.35 fits every tab without overflow', (
      tester,
    ) async {
      const locale = Locale('de');
      await pumpBar(tester, locale: locale, textScale: 1.35, width: 393);

      expect(tester.takeException(), isNull);
      for (final label in labelsFor(locale)) {
        expect(find.text(label), findsOneWidget);
      }
    });

    for (final code in ['de', 'ru', 'fi', 'fa']) {
      for (final textScale in [1.0, 1.35, 2.0]) {
        for (final width in [375.0, 440.0]) {
          testWidgets(
            '$code at ${textScale}x, ${width.toInt()} wide: labels stay '
            'inside the bar and clear of each other',
            (tester) async {
              final locale = Locale(code);
              await pumpBar(
                tester,
                locale: locale,
                textScale: textScale,
                width: width,
              );

              expect(tester.takeException(), isNull);
              final bar = tester.getRect(find.byType(HomeTabBar));
              // getRect is post-transform, so it measures the label as drawn
              // after any FittedBox scale-down.
              final rects =
                  labelsFor(locale)
                      .map((label) => tester.getRect(find.text(label)))
                      .toList()
                    ..sort((a, b) => a.left.compareTo(b.left));
              for (final rect in rects) {
                expect(rect.bottom, lessThanOrEqualTo(bar.bottom));
                expect(rect.left, greaterThanOrEqualTo(bar.left));
                expect(rect.right, lessThanOrEqualTo(bar.right));
              }
              for (var i = 0; i < rects.length - 1; i++) {
                expect(rects[i].right, lessThanOrEqualTo(rects[i + 1].left));
              }
            },
          );
        }
      }
    }

    testWidgets('de at 1.35: every tab fits in the raised active slot too', (
      tester,
    ) async {
      const locale = Locale('de');
      await pumpBar(tester, locale: locale, textScale: 1.35, width: 393);

      for (final label in labelsFor(locale)) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'active: $label');
      }
    });

    testWidgets('de at 1.35: every label renders on a single line', (
      tester,
    ) async {
      const locale = Locale('de');
      await pumpBar(tester, locale: locale, textScale: 1.35, width: 393);

      for (final label in labelsFor(locale)) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
    });

    testWidgets('a label is drawn at the same size active or inactive', (
      tester,
    ) async {
      const locale = Locale('de');
      await pumpBar(tester, locale: locale, textScale: 2.0, width: 393);
      final more = lookupAppLocalizations(locale).homescreenmore;

      final inactiveHeight = tester.getRect(find.text(more)).height;
      await tester.tap(find.text(more));
      await tester.pumpAndSettle();
      final activeHeight = tester.getRect(find.text(more)).height;

      expect(activeHeight, closeTo(inactiveHeight, 0.5));
    });
  });
}
