import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../base_buttons.dart';
import 'provider_sign_in_button.dart';

/// The option picked in the sign-in sheet.
enum SignInMethod { apple, google, email, cancel }

/// Shows the sign-in sheet and returns the chosen method: [SignInMethod.cancel]
/// for Cancel, `null` when the sheet is dismissed. Signing in itself is
/// `AuthenticationService.promptSignIn`'s job.
Future<SignInMethod?> showSignInSheet(
  BuildContext context, {
  required String title,
  required String bodyText,
  required bool showApple,
}) {
  return showModalBottomSheet<SignInMethod>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SignInSheet(
        title: title,
        bodyText: bodyText,
        showApple: showApple,
      ),
    ),
  );
}

/// The sheet's content: heading, body, the provider buttons at one width,
/// and Cancel.
@visibleForTesting
class SignInSheet extends StatelessWidget {
  const SignInSheet({
    super.key,
    required this.title,
    required this.bodyText,
    required this.showApple,
  });

  /// Keeps the buttons button-sized in a wide iPad or web window.
  static const double _maxButtonWidth = 400;

  final String title;
  final String bodyText;
  final bool showApple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.xs,
          AppSpacing.base,
          AppSpacing.base + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(bodyText, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxButtonWidth),
                // Stretch gives Apple, Google and Email one width: they
                // would otherwise each size to their own text.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showApple) ...[
                      AppleSignInButton(
                        label: l10n.signInWithApple,
                        onPressed: () =>
                            Navigator.pop(context, SignInMethod.apple),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],
                    GoogleSignInButton(
                      label: l10n.signInWithGoogle,
                      onPressed: () =>
                          Navigator.pop(context, SignInMethod.google),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Semantics(
                      identifier: 'signInWithEmailButton',
                      child: AppElevatedButton(
                        label: l10n.signInWithEmail,
                        icon: Icons.email,
                        onPressed: () =>
                            Navigator.pop(context, SignInMethod.email),
                        height: AppButton.heightMedium,
                        elevation: 0,
                        // `height` is only a minimum: the default medium
                        // padding would grow the button past the 48 pt token
                        // height, so use the small padding to stay at 48.
                        padding: AppButton.paddingSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Center(
              child: AppTextButton(
                label: l10n.dialogCancel,
                onPressed: () => Navigator.pop(context, SignInMethod.cancel),
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: AppButton.paddingSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
        ),
      ),
    );
  }
}
