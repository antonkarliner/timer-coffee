import 'package:coffee_timer/widgets/recipe_detail/floating_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

Widget _wrap(
  Widget child, {
  Locale? locale,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'exposes a stable identifier and accessible label on the icon-only action',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(FloatingNavButton(onPressed: () => taps++)),
      );

      final semantics = tester.getSemantics(find.byType(FloatingNavButton));
      expect(semantics.identifier, 'recipeDetailNextButton');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.label, 'Preparation');
      // Compact arrow action: the name is semantics-only, no visible text.
      expect(find.text('Preparation'), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      // The callback is exercised through a real tap in the tests below.
    },
  );

  testWidgets(
    'compact 56pt action fits a narrow screen at large text scale and navigates once',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Stack(
            children: [
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingNavButton(onPressed: () => taps++),
              ),
            ],
          ),
          locale: const Locale('de'),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      final bounds = tester.getRect(find.byType(FloatingNavButton));
      expect(bounds.width, 56);
      expect(bounds.height, 56);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(FloatingNavButton));
      expect(taps, 1);
    },
  );

  testWidgets('supports a custom icon', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        FloatingNavButton(
          onPressed: () => taps++,
          icon: const Icon(Icons.check),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    await tester.tap(find.byIcon(Icons.check));
    expect(taps, 1);
  });
}
