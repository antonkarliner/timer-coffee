import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/auth/sign_in_sheet.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_button/sign_in_button.dart';

const _title = 'Sign in to Timer.Coffee';
const _bodyText = 'Keep your coffee recipes across devices.';

Finder _button(String text) => find.byWidgetPredicate(
  (widget) => widget is SignInButtonBuilder && widget.text == text,
);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(SignInSheet)))!;

Future<void> _openSheet(
  WidgetTester tester, {
  required List<SignInMethod?> results,
  bool showApple = true,
  ColorScheme scheme = lightColorScheme,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: ThemeData(colorScheme: scheme),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: AppTextButton(
              label: 'Open sign-in sheet',
              onPressed: () async {
                results.add(
                  await showSignInSheet(
                    context,
                    title: _title,
                    bodyText: _bodyText,
                    showApple: showApple,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open sign-in sheet'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a drag handle and the centred title style', (
    tester,
  ) async {
    await _openSheet(tester, results: []);

    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
    final heading = tester.widget<Text>(find.text(_title));
    expect(heading.style!.fontSize, AppTextStyles.title.fontSize);
    expect(heading.style!.fontWeight, AppTextStyles.title.fontWeight);
    expect(heading.textAlign, TextAlign.center);
    expect(
      tester.widget<Text>(find.text(_bodyText)).textAlign,
      TextAlign.center,
    );
  });

  for (final width in [390.0, 1024.0]) {
    testWidgets('buttons have equal widths on a $width pt surface', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _openSheet(tester, results: []);
      final l10n = _l10n(tester);
      final buttons = [
        _button(l10n.signInWithApple),
        _button(l10n.signInWithGoogle),
        _button(l10n.signInWithEmail),
      ];

      for (final button in buttons) {
        expect(button, findsOneWidget);
        expect(
          tester.getSize(button).width,
          width == 1024 ? 400 : width - AppSpacing.base * 2,
        );
      }
      final appleCenter = tester.getCenter(buttons.first).dx;
      expect(appleCenter, width / 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('omits Apple when showApple is false', (tester) async {
    await _openSheet(tester, results: [], showApple: false);
    final l10n = _l10n(tester);

    expect(_button(l10n.signInWithApple), findsNothing);
    expect(_button(l10n.signInWithGoogle), findsOneWidget);
    expect(_button(l10n.signInWithEmail), findsOneWidget);
  });

  for (final scheme in [lightColorScheme, darkColorScheme]) {
    testWidgets('uses email theme colours in ${scheme.brightness}', (
      tester,
    ) async {
      await _openSheet(tester, results: [], scheme: scheme);
      final email = _button(_l10n(tester).signInWithEmail);
      final builder = tester.widget<SignInButtonBuilder>(email);

      expect(builder.backgroundColor, scheme.primary);
      expect(builder.textColor, scheme.onPrimary);
      expect(builder.iconColor, scheme.onPrimary);
      expect(
        tester
            .widget<MaterialButton>(
              find.descendant(of: email, matching: find.byType(MaterialButton)),
            )
            .color,
        scheme.primary,
      );
      expect(
        tester.widget<Text>(find.text(builder.text)).style!.color,
        scheme.onPrimary,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.email)).color,
        scheme.onPrimary,
      );

      final providers = tester.widgetList<SignInButton>(
        find.byType(SignInButton),
      );
      expect(providers.map((button) => button.button), [
        scheme.brightness == Brightness.dark
            ? Buttons.apple
            : Buttons.appleDark,
        scheme.brightness == Brightness.dark
            ? Buttons.google
            : Buttons.googleDark,
      ]);
    });
  }

  for (final method in SignInMethod.values) {
    testWidgets('returns $method when tapped', (tester) async {
      final results = <SignInMethod?>[];
      await _openSheet(tester, results: results);
      final l10n = _l10n(tester);
      final label = switch (method) {
        SignInMethod.apple => l10n.signInWithApple,
        SignInMethod.google => l10n.signInWithGoogle,
        SignInMethod.email => l10n.signInWithEmail,
        SignInMethod.cancel => l10n.dialogCancel,
      };

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(results, [method]);
      expect(find.byType(SignInSheet), findsNothing);
    });
  }

  testWidgets('returns null when the barrier is tapped', (tester) async {
    final results = <SignInMethod?>[];
    await _openSheet(tester, results: results);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(find.byType(SignInSheet), findsNothing);
  });

  testWidgets('scrolls at large text scales on a short surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <SignInMethod?>[];
    await _openSheet(
      tester,
      results: results,
      textScaler: TextScaler.linear(3),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
    final cancel = find.text(_l10n(tester).dialogCancel);
    await tester.ensureVisible(cancel);
    await tester.pumpAndSettle();
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(results, [SignInMethod.cancel]);
  });
}
