import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(
        l10n.unsavedChangesTitle,
        style: AppTextStyles.title,
      ),
      content: Text(
        l10n.unsavedChangesMessage,
        style: AppTextStyles.body,
      ),
      actions: [
        AppTextButton(
          label: l10n.unsavedChangesStay,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppElevatedButton(
          label: l10n.unsavedChangesDiscard,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
      ],
    );
  }
}
