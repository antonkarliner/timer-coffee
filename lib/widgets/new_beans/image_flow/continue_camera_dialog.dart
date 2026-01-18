import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

class ContinueCameraDialog extends StatelessWidget {
  const ContinueCameraDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.takeAdditionalPhoto),
      actions: [
        AppTextButton(
          label: loc.no,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
        ),
        AppElevatedButton(
          label: loc.yes,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
        ),
      ],
    );
  }
}
