import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class AdditionalNotesCard extends StatelessWidget {
  final String? notes;
  final ValueChanged<String> onNotesChanged;

  const AdditionalNotesCard({
    super.key,
    required this.notes,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.additionalNotes,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'notesInputField',
              label: loc.enterNotes,
              child: TextFormField(
                initialValue: notes ?? '',
                onChanged: onNotesChanged,
                decoration: InputDecoration(
                  labelText: loc.notes,
                  hintText: loc.enterNotes,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
