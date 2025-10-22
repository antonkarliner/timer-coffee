import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';

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
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.unsavedChangesStay,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.unsavedChangesDiscard,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
