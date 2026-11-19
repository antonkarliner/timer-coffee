import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// "Sign in with Google" button following Google's branding guidelines
/// (https://developers.google.com/identity/branding-guidelines,
/// checked 2026-11-19).
///
/// The standard-colour G artwork is drawn at Google's prescribed 20 px and is
/// never resized or recoloured. Its background exactly matches the button
/// fill, so the image needs no backing of its own.
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

  // Brand-mandated metrics from the same guideline. On iOS the spacing is
  // 16 px before the G, 12 px between G and text, 16 px after the text; on
  // Android and web it is 12 / 10 / 12. Google asks for Google Sans Medium as
  // the label font — we keep the app's own button label style instead, a
  // known deviation.
  static const double _iosLeading = 16;
  static const double _iosGap = 12;
  static const double _iosTrailing = 16;
  static const double _androidWebLeading = 12;
  static const double _androidWebGap = 10;
  static const double _androidWebTrailing = 12;

  /// Google's standard-colour G at its official 20 px size.
  static const double _logoSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? _darkFill : _lightFill;
    final strokeColor = isDark ? _darkStroke : _lightStroke;
    final textColor = isDark ? _darkText : _lightText;
    final isIos = theme.platform == TargetPlatform.iOS;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(
        width: 1,
        color: strokeColor,
        strokeAlign: BorderSide.strokeAlignInside,
      ),
    );

    final padding = EdgeInsetsDirectional.fromSTEB(
      isIos ? _iosLeading : _androidWebLeading,
      0,
      isIos ? _iosTrailing : _androidWebTrailing,
      0,
    );

    return Semantics(
      button: true,
      identifier: 'signInWithGoogleButton',
      child: Material(
        color: fill,
        shape: shape,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          // A minimum, not a fixed height: Google sets no height rule, so
          // the button grows with large text scales instead of clipping.
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppButton.heightMedium,
            ),
            padding: padding,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isDark
                      ? 'assets/icons/google/google_g_dark.png'
                      : 'assets/icons/google/google_g_light.png',
                  width: _logoSize,
                  height: _logoSize,
                ),
                SizedBox(width: isIos ? _iosGap : _androidWebGap),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppButton.label.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
