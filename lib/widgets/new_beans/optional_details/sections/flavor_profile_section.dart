import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/fields/chip_input.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class FlavorProfileSection extends StatelessWidget {
  final List<String> tastingNotes;
  final Future<List<String>> tastingNotesOptions;
  final ValueChanged<List<String>> onTastingNotesChanged;

  const FlavorProfileSection({
    super.key,
    this.tastingNotes = const [],
    required this.tastingNotesOptions,
    required this.onTastingNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<List<String>>(
      future: tastingNotesOptions,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];

        return ChipInput(
          label: loc.tastingNotes,
          hintText: loc.enterTastingNotes,
          initialValues: tastingNotes,
          suggestions: suggestions,
          semanticIdentifier: 'tastingNotesInputField',
          onChanged: onTastingNotesChanged,
        );
      },
    );
  }
}
