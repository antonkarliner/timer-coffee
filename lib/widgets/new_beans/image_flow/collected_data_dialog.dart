import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class CollectedDataDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(String key) humanizeKey;

  const CollectedDataDialog({
    super.key,
    required this.data,
    required this.humanizeKey,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.collectedInformation),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: data.entries.map((entry) {
            return Text(
              '${humanizeKey(entry.key)}: ${entry.value ?? 'N/A'}',
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.ok),
        ),
      ],
    );
  }
}
