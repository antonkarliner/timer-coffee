import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/recipe_detail/bean_selection_row.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const schemes = <(String, ColorScheme)>[
    ('light', lightColorScheme),
    ('dark', darkColorScheme),
  ];

  AppLocalizations locOf(WidgetTester tester) {
    final context = tester.element(find.byType(BeanSelectionRow));
    return AppLocalizations.of(context)!;
  }

  Future<void> pumpRow(
    WidgetTester tester, {
    required ColorScheme scheme,
    String? beanUuid,
    String? beanName,
    required VoidCallback onSelectBeans,
    required VoidCallback onClearSelection,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: ThemeData(colorScheme: scheme),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: BeanSelectionRow(
                selectedBeanUuid: beanUuid,
                selectedBeanName: beanName,
                originalRoasterLogoUrl: null,
                mirrorRoasterLogoUrl: null,
                onSelectBeans: onSelectBeans,
                onClearSelection: onClearSelection,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Flush BeanSelectionRow's 3s fallback timer so it doesn't linger past
    // the end of the test.
    await tester.pump(const Duration(seconds: 4));
  }

  for (final (label, scheme) in schemes) {
    group('idle ($label theme)', () {
      testWidgets('placeholder label and icon render at full onSurface', (
        tester,
      ) async {
        await pumpRow(
          tester,
          scheme: scheme,
          onSelectBeans: () {},
          onClearSelection: () {},
        );

        expect(find.text('Select Beans'), findsOneWidget);

        final text = tester.widget<Text>(find.text('Select Beans'));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.style?.color, scheme.onSurface);
        expect(text.style?.color?.a, 1.0);

        final icon = tester.widget<Icon>(find.byIcon(Coffeico.bag_with_bean));
        expect(icon.color, scheme.onSurface);
        expect(icon.color?.a, 1.0);

        expect(
          find.byTooltip(locOf(tester).fieldClearButtonTooltip),
          findsNothing,
        );
      });

      testWidgets('tapping the chip calls onSelectBeans once', (tester) async {
        var selectCalls = 0;
        await pumpRow(
          tester,
          scheme: scheme,
          onSelectBeans: () => selectCalls++,
          onClearSelection: () {},
        );

        await tester.tap(find.text('Select Beans'));
        await tester.pump();

        expect(selectCalls, 1);
      });

      testWidgets('chip Material uses the card radius', (tester) async {
        await pumpRow(
          tester,
          scheme: scheme,
          onSelectBeans: () {},
          onClearSelection: () {},
        );

        final material = tester.widget<Material>(
          find
              .ancestor(
                of: find.text('Select Beans'),
                matching: find.byType(Material),
              )
              .first,
        );
        final shape = material.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
      });
    });

    group('selected ($label theme)', () {
      testWidgets('shows the bean name with a working clear button', (
        tester,
      ) async {
        var clearCalls = 0;
        await pumpRow(
          tester,
          scheme: scheme,
          beanUuid: 'b1',
          beanName: 'Ethiopia Guji',
          onSelectBeans: () {},
          onClearSelection: () => clearCalls++,
        );

        expect(find.text('Ethiopia Guji'), findsOneWidget);

        final tooltip = find.byTooltip(locOf(tester).fieldClearButtonTooltip);
        expect(tooltip, findsOneWidget);

        await tester.tap(tooltip);
        await tester.pump();

        expect(clearCalls, 1);
      });
    });
  }
}
