import 'package:coffee_timer/widgets/recipe_detail/floating_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

void main() {
  testWidgets('exposes a stable identifier for screenshot automation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FloatingNavButton(onPressed: () {})),
      ),
    );

    final semantics = tester.getSemantics(find.byType(FloatingNavButton));

    expect(semantics.identifier, 'recipeDetailNextButton');
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.label, 'Preparation');
    expect(find.text('Preparation'), findsOneWidget);
  });

  testWidgets('localized action fits a narrow screen and navigates once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingNavButton(onPressed: () => taps++),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(FloatingNavButton));
    final label = AppLocalizations.of(context)!.preparation;
    expect(find.text(label), findsOneWidget);
    expect(tester.takeException(), isNull);
    final bounds = tester.getRect(find.byType(FloatingNavButton));
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    await tester.tap(find.text(label));
    expect(taps, 1);
  });
}
