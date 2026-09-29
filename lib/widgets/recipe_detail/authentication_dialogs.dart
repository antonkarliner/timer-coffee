import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/otp_code_field.dart';
import 'package:flutter/material.dart';

/// Widget that shows the email input dialog.
class EmailSignInDialog extends StatelessWidget {
  const EmailSignInDialog({
    super.key,
    required this.onEmailSubmitted,
    this.onCancel,
  });

  final void Function(String email) onEmailSubmitted;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();

    return AlertDialog(
      title: Text(l10n.enterEmail),
      content: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(hintText: l10n.emailHint),
      ),
      actions: <Widget>[
        AppTextButton(
          label: l10n.cancel,
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
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

/// Widget that shows the OTP verification dialog.
class OTPVerificationDialog extends StatefulWidget {
  const OTPVerificationDialog({
    super.key,
    required this.email,
    required this.onOTPSubmitted,
    this.onCancel,
  });

  final String email;
  final void Function(String email, String token) onOTPSubmitted;
  final VoidCallback? onCancel;

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(l10n.enterOTP),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.otpSentMessage),
          const SizedBox(height: AppSpacing.base),
          OtpCodeField(
            controller: _otpController,
            label: l10n.otpHint2,
            autofocus: true,
          ),
        ],
      ),
      actions: <Widget>[
        AppTextButton(
          label: l10n.cancel,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel?.call();
          },
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppTextButton(
          label: l10n.verify,
          onPressed: () {
            widget.onOTPSubmitted(widget.email, _otpController.text);
          },
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}

/// Helper class to show authentication dialogs.
class AuthenticationDialogs {
  static void showEmailSignInDialog(
    BuildContext context,
    void Function(String email) onEmailSubmitted, {
    VoidCallback? onCancel,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EmailSignInDialog(
        onEmailSubmitted: onEmailSubmitted,
        onCancel: onCancel,
      ),
    );
  }

  static void showOTPVerificationDialog(
    BuildContext context,
    String email,
    void Function(String email, String token) onOTPSubmitted, {
    VoidCallback? onCancel,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OTPVerificationDialog(
        email: email,
        onOTPSubmitted: onOTPSubmitted,
        onCancel: onCancel,
      ),
    );
  }
}
