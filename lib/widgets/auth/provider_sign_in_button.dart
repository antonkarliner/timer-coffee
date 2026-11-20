import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// The sign-in sheet's three buttons (Apple, Google, Email) share one frame:
// the same 48 pt minimum height, 12 pt corners, and the logo pinned at the
// leading edge with the title centred on the button (operator decision
// 2026-11-19, plan 090 Track A). Each title uses its own brand's type:
// - Apple: the system font, regular, at 43 % of the button height, as Apple's
//   HIG asks for the title-to-height proportion; the HIG also allows insetting
//   the logo to line up with other providers' logos
//   (https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple,
//   checked 2026-11-19).
// - Google: Google Sans Medium, as Google's branding guidelines ask
//   (https://developers.google.com/identity/branding-guidelines, checked
//   2026-11-19). Bundled as `ProviderLabelSans`, a trimmed copy under the
//   OFL (see fonts/ProviderLabelSans-OFL.txt).
// - Email: the app's own button label.

/// Google's standard-colour G is drawn at its official 20 px; the Apple logo
/// and the email icon use the same box so the three line up.
const double _logoSize = 20;

// Google's padding (brand-mandated, no design token for 12 / 10): on iOS 16 px
// before the logo and 12 px between logo and text; on Android and web 12 / 10.
// All three buttons use it so their logos sit at the same x.
const double _iosLeading = 16;
const double _iosGap = 12;
const double _androidWebLeading = 12;
const double _androidWebGap = 10;

/// The shared frame: fill, optional stroke, leading logo, centred title.
class _SignInButtonFrame extends StatelessWidget {
  const _SignInButtonFrame({
    required this.semanticIdentifier,
    required this.label,
    required this.onPressed,
    required this.logo,
    required this.fill,
    required this.textColor,
    required this.titleStyle,
    this.strokeColor,
  });

  final String semanticIdentifier;
  final String label;
  final VoidCallback onPressed;
  final Widget logo;
  final Color fill;
  final Color textColor;
  final TextStyle titleStyle;
  final Color? strokeColor;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final leading = isIos ? _iosLeading : _androidWebLeading;
    final gap = isIos ? _iosGap : _androidWebGap;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: strokeColor == null
          ? BorderSide.none
          : BorderSide(
              width: AppStroke.border,
              color: strokeColor!,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
    );

    return Semantics(
      button: true,
      identifier: semanticIdentifier,
      child: Material(
        color: fill,
        shape: shape,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          // A minimum, not a fixed height: the button grows with large text
          // sizes instead of clipping.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppButton.heightMedium,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: leading,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox.square(dimension: _logoSize, child: logo),
                  SizedBox(width: gap),
                  // No line limit: a provider's name must never be cut off,
                  // so the button grows instead.
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: titleStyle.copyWith(color: textColor),
                    ),
                  ),
                  // Mirrors the logo and gap so the title is centred on the
                  // whole button, not on the space after the logo.
                  SizedBox(width: gap + _logoSize),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sign in with Apple": black fill on light, white on dark, logo and title
/// in the contrasting colour, with Apple's logo artwork as shipped by the
/// `sign_in_with_apple` package ([AppleLogoPainter]).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  // Apple's mandated black / white treatments.
  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);

  /// Apple's title: the system font, regular weight, 43 % of the button
  /// height (≈ 21 pt at 48 pt), matching the system Sign in with Apple
  /// button and the `sign_in_with_apple` package's own style.
  static const TextStyle _title = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: AppButton.heightMedium * 0.43,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark ? _black : _white;
    return _SignInButtonFrame(
      semanticIdentifier: 'signInWithAppleButton',
      label: label,
      onPressed: onPressed,
      fill: isDark ? _white : _black,
      textColor: contentColor,
      titleStyle: _title,
      // The glyph is 25:31 (width:height); fit it to the shared logo height.
      logo: Center(
        child: SizedBox(
          width: _logoSize * 25 / 31,
          height: _logoSize,
          child: CustomPaint(painter: AppleLogoPainter(color: contentColor)),
        ),
      ),
    );
  }
}

/// "Sign in with Google" in Google's brand colours. The standard-colour G
/// is never resized or recoloured, and its background matches the fill
/// exactly, so it needs no backing of its own.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  // Brand-mandated colours from Google's "Sign in with Google" branding
  // guidelines. These hex literals are Google's brand values, so the
  // scheme-roles rule does not apply to them.
  static const Color _lightFill = Color(0xFFFFFFFF);
  static const Color _lightStroke = Color(0xFF747775);
  static const Color _lightText = Color(0xFF1F1F1F);
  static const Color _darkFill = Color(0xFF131314);
  static const Color _darkStroke = Color(0xFF8E918F);
  static const Color _darkText = Color(0xFFE3E3E3);

  /// Google Sans Medium (bundled as `ProviderLabelSans`) at the app's
  /// button-label size.
  static TextStyle get _title => AppButton.label.copyWith(
    fontFamily: 'ProviderLabelSans',
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SignInButtonFrame(
      semanticIdentifier: 'signInWithGoogleButton',
      label: label,
      onPressed: onPressed,
      fill: isDark ? _darkFill : _lightFill,
      strokeColor: isDark ? _darkStroke : _lightStroke,
      textColor: isDark ? _darkText : _lightText,
      titleStyle: _title,
      logo: Image.asset(
        isDark
            ? 'assets/icons/google/google_g_dark.png'
            : 'assets/icons/google/google_g_light.png',
        width: _logoSize,
        height: _logoSize,
      ),
    );
  }
}

/// "Sign in with Email" in the app's primary colours. It uses the shared
/// sign-in frame rather than `AppElevatedButton` (which centres its icon next
/// to the label) so its icon lines up with the Apple and Google logos.
class EmailSignInButton extends StatelessWidget {
  const EmailSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SignInButtonFrame(
      semanticIdentifier: 'signInWithEmailButton',
      label: label,
      onPressed: onPressed,
      fill: scheme.primary,
      textColor: scheme.onPrimary,
      titleStyle: AppButton.label,
      logo: Icon(Icons.email, size: _logoSize, color: scheme.onPrimary),
    );
  }
}
