import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/auth/provider_sign_in_button.dart';
import 'package:coffee_timer/widgets/auth/sign_in_sheet.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

const _title = 'Sign in to Timer.Coffee';
const _bodyText = 'Keep your coffee recipes across devices.';

// Google's brand-mandated colours, pinned here so a regression is caught.
const _googleLightFill = Color(0xFFFFFFFF);
const _googleLightStroke = Color(0xFF747775);
const _googleLightText = Color(0xFF1F1F1F);
const _googleDarkFill = Color(0xFF131314);
const _googleDarkStroke = Color(0xFF8E918F);
const _googleDarkText = Color(0xFFE3E3E3);

Finder _appleButton() => find.byType(AppleSignInButton);

Finder _googleButton() => find.byType(GoogleSignInButton);

Finder _emailButton(AppLocalizations l10n) => find.byType(EmailSignInButton);

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(SignInSheet)))!;

Future<void> _openSheet(
  WidgetTester tester, {
  required List<SignInMethod?> results,
  bool showApple = true,
  ColorScheme scheme = lightColorScheme,
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: ThemeData(colorScheme: scheme),
      locale: locale,
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
        _appleButton(),
        _googleButton(),
        _emailButton(l10n),
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

    expect(_appleButton(), findsNothing);
    expect(_googleButton(), findsOneWidget);
    expect(_emailButton(l10n), findsOneWidget);
  });

  for (final scheme in [lightColorScheme, darkColorScheme]) {
    testWidgets('matches the brand colours in ${scheme.brightness}', (
      tester,
    ) async {
      await _openSheet(tester, results: [], scheme: scheme);
      final l10n = _l10n(tester);
      final isDark = scheme.brightness == Brightness.dark;

      // Email: primary fill, onPrimary title and icon.
      final emailFinder = _emailButton(l10n);
      expect(emailFinder, findsOneWidget);
      final email = tester.widget<Material>(
        find.descendant(of: emailFinder, matching: find.byType(Material)),
      );
      expect(email.color, scheme.primary);
      expect(
        tester.widget<Text>(find.text(l10n.signInWithEmail)).style!.color,
        scheme.onPrimary,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: emailFinder, matching: find.byType(Icon)),
            )
            .color,
        scheme.onPrimary,
      );

      // Apple: black fill with white logo and title on light, the reverse
      // on dark.
      final apple = tester.widget<Material>(
        find.descendant(of: _appleButton(), matching: find.byType(Material)),
      );
      final appleShape = apple.shape! as RoundedRectangleBorder;
      expect(apple.color, isDark ? Colors.white : Colors.black);
      final appleLogo = tester.widget<CustomPaint>(
        find.descendant(
          of: _appleButton(),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is AppleLogoPainter,
          ),
        ),
      );
      expect(
        (appleLogo.painter! as AppleLogoPainter).color,
        isDark ? Colors.black : Colors.white,
      );
      final appleTitle = tester.widget<Text>(
        find.text(l10n.signInWithApple),
      );
      expect(
        appleTitle.style!.color,
        isDark ? Colors.black : Colors.white,
      );

      // Each title in its brand's type (operator decision 2026-11-19):
      // Apple system font regular at 43 % of 48 pt, Google Sans Medium
      // (bundled as ProviderLabelSans), Email the app's button label.
      final appleStyle =
          tester.widget<Text>(find.text(l10n.signInWithApple)).style!;
      expect(appleStyle.fontFamily, '.SF Pro Text');
      expect(appleStyle.fontWeight, FontWeight.w400);
      expect(appleStyle.fontSize, AppButton.heightMedium * 0.43);
      final googleStyle =
          tester.widget<Text>(find.text(l10n.signInWithGoogle)).style!;
      expect(googleStyle.fontFamily, 'ProviderLabelSans');
      expect(googleStyle.fontWeight, FontWeight.w500);
      expect(googleStyle.fontSize, AppButton.label.fontSize);
      final emailStyle =
          tester.widget<Text>(find.text(l10n.signInWithEmail)).style!;
      expect(emailStyle.fontSize, AppButton.label.fontSize);
      expect(emailStyle.fontWeight, AppButton.label.fontWeight);

      // Logos line up: the same left edge and the same 20 pt box, and every
      // title is centred on its button.
      final logoLefts = [
        tester.getTopLeft(
          find.descendant(
            of: _appleButton(),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is AppleLogoPainter,
            ),
          ),
        ).dx,
        tester.getTopLeft(
          find.descendant(of: _googleButton(), matching: find.byType(Image)),
        ).dx,
        tester.getTopLeft(
          find.descendant(of: emailFinder, matching: find.byType(Icon)),
        ).dx,
      ];
      // Apple's glyph is narrower than its 20 pt box and centred in it.
      expect(logoLefts[1], logoLefts[2]);
      expect(logoLefts[0], closeTo(logoLefts[1] + (20 - 20 * 25 / 31) / 2, 0.01));
      for (final (button, label) in [
        (_appleButton(), l10n.signInWithApple),
        (_googleButton(), l10n.signInWithGoogle),
        (emailFinder, l10n.signInWithEmail),
      ]) {
        expect(
          tester.getCenter(find.text(label)).dx,
          closeTo(tester.getCenter(button).dx, 0.5),
        );
      }

      // Google: fill, stroke and label per the branding guideline, with the
      // matching G artwork.
      final google = tester.widget<Material>(
        find.descendant(
          of: _googleButton(),
          matching: find.byType(Material),
        ),
      );
      final shape = google.shape! as RoundedRectangleBorder;
      expect(
        google.color,
        isDark ? _googleDarkFill : _googleLightFill,
      );
      expect(shape.side.color, isDark ? _googleDarkStroke : _googleLightStroke);
      expect(
        tester.widget<Text>(find.text(l10n.signInWithGoogle)).style!.color,
        isDark ? _googleDarkText : _googleLightText,
      );
      final googleImage = tester.widget<Image>(
        find.descendant(of: _googleButton(), matching: find.byType(Image)),
      );
      expect(
        (googleImage.image as AssetImage).assetName,
        isDark
            ? 'assets/icons/google/google_g_dark.png'
            : 'assets/icons/google/google_g_light.png',
      );

      // Shared geometry: 48 pt tall, 12 pt corner radius. Apple's 21 pt
      // title wraps in the test font (much wider than SF), so it is only
      // held to the 48 pt minimum here; on device it is 48 pt (checked on
      // the simulator, evidence/090/a2d-*).
      for (final button in [_googleButton(), emailFinder]) {
        expect(tester.getSize(button).height, AppButton.heightMedium);
      }
      expect(
        tester.getSize(_appleButton()).height,
        greaterThanOrEqualTo(AppButton.heightMedium),
      );
      expect(appleShape.borderRadius, BorderRadius.circular(AppRadius.card));
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
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

  testWidgets('fits a 390 pt surface in de', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _openSheet(tester, results: [], locale: const Locale('de'));
    final l10n = _l10n(tester);

    expect(tester.takeException(), isNull);
    for (final button in [
      _appleButton(),
      _googleButton(),
      _emailButton(l10n),
    ]) {
      expect(button, findsOneWidget);
      // The test font is wider than SF, so a label may wrap here; the
      // button then grows rather than clipping.
      expect(
        tester.getSize(button).height,
        greaterThanOrEqualTo(AppButton.heightMedium),
      );
    }
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

  testWidgets('all three grow with the text scale and never cut a title', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _openSheet(tester, results: [], textScaler: TextScaler.linear(3));

    expect(tester.takeException(), isNull);
    // All three grow (how far depends on each label's length).
    for (final button in [
      _appleButton(),
      _googleButton(),
      _emailButton(_l10n(tester)),
    ]) {
      expect(
        tester.getSize(button).height,
        greaterThan(AppButton.heightMedium),
      );
    }
    // The title is never cut off: no line limit, no ellipsis, and the
    // paragraph lays out without exceeding its lines.
    final title = tester.widget<Text>(
      find.descendant(
        of: _appleButton(),
        matching: find.text(_l10n(tester).signInWithApple),
      ),
    );
    expect(title.maxLines, isNull);
    expect(title.overflow, isNot(TextOverflow.ellipsis));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: _appleButton(),
        matching: find.byType(RichText),
      ),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });
}
