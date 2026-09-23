import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/settings/layout_switch_back_reason_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kGivenKey = 'layout_switch_back_reason_given';
const _kShownCountKey = 'layout_switch_back_reason_shown_count';

const _promptEn = 'What didn’t work?';
const _thanksEn = 'Thanks — that helps.';

/// Pumps the row (hidden or visible per [pourEnabled]) inside a MaterialApp.
/// Re-pumping with a different [pourEnabled] reuses the row's element, so its
/// `didUpdateWidget` observes the flip exactly like a real toggle rebuild.
Future<void> pumpRow(
  WidgetTester tester, {
  required bool pourEnabled,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  Key? rowKey,
}) async {
  final scheme =
      brightness == Brightness.light ? lightColorScheme : darkColorScheme;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorScheme: scheme),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LayoutSwitchBackReasonRow(
            key: rowKey,
            pourEnabled: pourEnabled,
            source: 'test',
          ),
        ),
      ),
    ),
  );
  // Flush the prefs load (initState) and let delegates/AnimatedSize settle.
  await tester.pump();
  await tester.pump();
}

/// A toggle flip animates the row in/out over 200ms — settle it.
Future<void> settleToggle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('is hidden initially, whether immersive is on or off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Mounted while immersive is ON — no flip observed yet.
    await pumpRow(tester, pourEnabled: true);
    expect(find.text(_promptEn), findsNothing);
    expect(prefs.getInt(_kShownCountKey), isNull);

    // Fresh mount directly while immersive is already OFF — also not a flip.
    // A distinct key forces a remount instead of an element update, so the
    // row cannot see a true → false `didUpdateWidget` here.
    await pumpRow(
      tester,
      pourEnabled: false,
      rowKey: const Key('fresh-mount-off'),
    );
    await settleToggle(tester);
    expect(find.text(_promptEn), findsNothing);
    expect(prefs.getInt(_kShownCountKey), isNull);
  });

  testWidgets('appears after a true → false rebuild, once, and marks shown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final semantics = tester.ensureSemantics();

    try {
      await pumpRow(tester, pourEnabled: true);
      await pumpRow(tester, pourEnabled: false);
      await settleToggle(tester);

      expect(find.text(_promptEn), findsOneWidget);
      expect(find.text('Hard to read'), findsOneWidget);
      expect(find.text('Too distracting'), findsOneWidget);
      expect(find.text('I prefer the classic timer'), findsOneWidget);
      expect(find.text('Something didn’t work'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('layoutSwitchBackReasonRow'),
        findsOneWidget,
      );
      expect(prefs.getInt(_kShownCountKey), 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('is not shown for a false → true transition', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpRow(tester, pourEnabled: false);
    await pumpRow(tester, pourEnabled: true);
    await settleToggle(tester);

    expect(find.text(_promptEn), findsNothing);
    expect(prefs.getInt(_kShownCountKey), isNull);
  });

  testWidgets('tapping a chip persists the answer and shows the thanks text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpRow(tester, pourEnabled: true);
    await pumpRow(tester, pourEnabled: false);
    await settleToggle(tester);

    await tester.tap(find.text('Hard to read'));
    await settleToggle(tester);

    expect(find.text(_thanksEn), findsOneWidget);
    expect(find.text(_promptEn), findsOneWidget,
        reason: 'only the chips are replaced by the thanks note');
    expect(find.text('Hard to read'), findsNothing);
    expect(find.text('Too distracting'), findsNothing);
    expect(find.text('I prefer the classic timer'), findsNothing);
    expect(find.text('Something didn’t work'), findsNothing);
    expect(prefs.getBool(_kGivenKey), isTrue);
    expect(prefs.getInt(_kShownCountKey), 1);
  });

  testWidgets('never appears once the install has answered', (tester) async {
    SharedPreferences.setMockInitialValues({_kGivenKey: true});
    final prefs = await SharedPreferences.getInstance();

    await pumpRow(tester, pourEnabled: true);
    await pumpRow(tester, pourEnabled: false);
    await settleToggle(tester);

    expect(find.text(_promptEn), findsNothing);
    expect(prefs.getInt(_kShownCountKey), isNull,
        reason: 'the shown count must not tick for ineligible installs');
  });

  testWidgets('stops appearing after being shown twice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Show #1.
    await pumpRow(tester, pourEnabled: true);
    await pumpRow(tester, pourEnabled: false);
    await settleToggle(tester);
    expect(find.text(_promptEn), findsOneWidget);

    // Back to immersive hides it again.
    await pumpRow(tester, pourEnabled: true);
    await settleToggle(tester);
    expect(find.text(_promptEn), findsNothing);

    // Show #2.
    await pumpRow(tester, pourEnabled: false);
    await settleToggle(tester);
    expect(find.text(_promptEn), findsOneWidget);

    // Back to immersive, then a third flip — no third show, ever.
    await pumpRow(tester, pourEnabled: true);
    await settleToggle(tester);
    await pumpRow(tester, pourEnabled: false);
    await settleToggle(tester);
    expect(find.text(_promptEn), findsNothing);
    expect(prefs.getInt(_kShownCountKey), 2);
  });

  testWidgets('hides again when the user flips back to immersive while '
      'it is showing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpRow(tester, pourEnabled: true);
    await pumpRow(tester, pourEnabled: false);
    await settleToggle(tester);
    expect(find.text(_promptEn), findsOneWidget);

    await pumpRow(tester, pourEnabled: true);
    await settleToggle(tester);
    expect(find.text(_promptEn), findsNothing);
    expect(find.text('Hard to read'), findsNothing);
    expect(prefs.getBool(_kGivenKey), isNull,
        reason: 'hiding without an answer must not persist one');
  });

  testWidgets('renders in light and dark at 375 wide without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final brightness in Brightness.values) {
      SharedPreferences.setMockInitialValues({});
      await pumpRow(
        tester,
        pourEnabled: true,
        brightness: brightness,
      );
      await pumpRow(
        tester,
        pourEnabled: false,
        brightness: brightness,
      );
      await settleToggle(tester);

      expect(tester.takeException(), isNull,
          reason: '$brightness at 375 wide');
      expect(find.text(_promptEn), findsOneWidget);
    }
  });

  testWidgets('renders the long German strings at 375 wide without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await pumpRow(tester, pourEnabled: true, locale: const Locale('de'));
    await pumpRow(tester, pourEnabled: false, locale: const Locale('de'));
    await settleToggle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Was hat nicht funktioniert?'), findsOneWidget);
    expect(find.text('Ich bevorzuge den klassischen Timer'), findsOneWidget);
    expect(find.text('Schwer zu lesen'), findsOneWidget);
    expect(find.text('Etwas hat nicht funktioniert'), findsOneWidget);
  });
}
