import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/autocomplete_tag_input_field.dart';
import 'package:coffee_timer/widgets/new_beans/section_header.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: Icons.local_cafe, title: loc.flavorProfile),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'tastingNotesInputField',
          label: loc.tastingNotes,
          child: AutocompleteTagInputField(
            label: loc.tastingNotes,
            hintText: loc.enterTastingNotes,
            initialOptions: tastingNotesOptions,
            onSelected: onTastingNotesChanged,
            initialValues: tastingNotes,
          ),
        ),
      ],
    );
  }
}
