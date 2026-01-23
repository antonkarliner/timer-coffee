import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.errorMessage),
      content: Text(message),
      actions: [
        AppTextButton(
          label: loc.ok,
          onPressed: () => Navigator.pop(context),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}
