import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'dart:io';

// Enum for sign-in method
enum SignInMethod { apple, google, email, cancel }

/// Widget that shows the initial sign-in prompt modal
class SignInPromptModal extends StatelessWidget {
  const SignInPromptModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16.0, 16.0, 16.0, 16.0 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.signInRequiredTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.signInRequiredBodyShare, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
              SignInButton(
                isDarkMode ? Buttons.apple : Buttons.appleDark,
                text: l10n.signInWithApple,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 16),
            ],
            SignInButton(
              isDarkMode ? Buttons.google : Buttons.googleDark,
              text: l10n.signInWithGoogle,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 16),
            SignInButtonBuilder(
              text: l10n.signInWithEmail,
              icon: Icons.email,
              onPressed: () => Navigator.pop(context, true),
              backgroundColor:
                  isDarkMode ? Colors.white : Colors.blueGrey.shade700,
              textColor: isDarkMode ? Colors.black87 : Colors.white,
              iconColor: isDarkMode ? Colors.black87 : Colors.white,
            ),
            const SizedBox(height: 16),
            AppTextButton(
              label: l10n.dialogCancel,
              onPressed: () => Navigator.pop(context, false),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Widget that shows the sign-in method selection modal
class SignInMethodSelectionModal extends StatelessWidget {
  const SignInMethodSelectionModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16.0, 16.0, 16.0, 16.0 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.signInCreate,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
              SignInButton(
                isDarkMode ? Buttons.apple : Buttons.appleDark,
                text: l10n.signInWithApple,
                onPressed: () => Navigator.pop(context, SignInMethod.apple),
              ),
              const SizedBox(height: 16),
            ],
            SignInButton(
              isDarkMode ? Buttons.google : Buttons.googleDark,
              text: l10n.signInWithGoogle,
              onPressed: () => Navigator.pop(context, SignInMethod.google),
            ),
            const SizedBox(height: 16),
            SignInButtonBuilder(
              text: l10n.signInWithEmail,
              icon: Icons.email,
              onPressed: () => Navigator.pop(context, SignInMethod.email),
              backgroundColor:
                  isDarkMode ? Colors.white : Colors.blueGrey.shade700,
              textColor: isDarkMode ? Colors.black87 : Colors.white,
              iconColor: isDarkMode ? Colors.black87 : Colors.white,
            ),
            const SizedBox(height: 16),
            AppTextButton(
              label: l10n.dialogCancel,
              onPressed: () => Navigator.pop(context, SignInMethod.cancel),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Widget that shows the email input dialog
class EmailSignInDialog extends StatelessWidget {
  final Function(String) onEmailSubmitted;

  const EmailSignInDialog({
    Key? key,
    required this.onEmailSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController emailController = TextEditingController();

    return AlertDialog(
      title: Text(l10n.enterEmail),
      content: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: l10n.emailHint,
        ),
      ),
      actions: <Widget>[
        AppTextButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppTextButton(
          label: l10n.sendOTP,
          onPressed: () {
            Navigator.of(context).pop();
            onEmailSubmitted(emailController.text);
          },
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}

/// Widget that shows the OTP verification dialog
class OTPVerificationDialog extends StatelessWidget {
  final String email;
  final Function(String, String) onOTPSubmitted;

  const OTPVerificationDialog({
    Key? key,
    required this.email,
    required this.onOTPSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController otpController = TextEditingController();

    return AlertDialog(
      title: Text(l10n.enterOTP),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.otpSentMessage),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.otpHint2,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        AppTextButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppTextButton(
          label: l10n.verify,
          onPressed: () {
            onOTPSubmitted(email, otpController.text);
          },
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}

/// Helper class to show authentication dialogs
class AuthenticationDialogs {
  /// Shows the initial sign-in prompt and returns whether user wants to sign in
  static Future<bool> showSignInPrompt(BuildContext context) async {
    final bool? signedIn = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) => const SignInPromptModal(),
    );
    return signedIn ?? false;
  }

  /// Shows the sign-in method selection and returns the chosen method
  static Future<SignInMethod?> showSignInMethodSelection(
      BuildContext context) async {
    return await showModalBottomSheet<SignInMethod>(
      context: context,
      builder: (BuildContext context) => const SignInMethodSelectionModal(),
    );
  }

  /// Shows the email input dialog
  static void showEmailSignInDialog(
    BuildContext context,
    Function(String) onEmailSubmitted,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => EmailSignInDialog(
        onEmailSubmitted: onEmailSubmitted,
      ),
    );
  }

  /// Shows the OTP verification dialog
  static void showOTPVerificationDialog(
    BuildContext context,
    String email,
    Function(String, String) onOTPSubmitted,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => OTPVerificationDialog(
        email: email,
        onOTPSubmitted: onOTPSubmitted,
      ),
    );
  }
}
