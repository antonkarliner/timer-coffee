import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class ContinueCameraDialog extends StatelessWidget {
  const ContinueCameraDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.takeAdditionalPhoto),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.no),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(loc.yes),
        ),
      ],
    );
  }
}
