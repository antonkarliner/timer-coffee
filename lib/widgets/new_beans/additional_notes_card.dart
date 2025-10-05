import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../containers/section_card.dart';
import '../fields/labeled_field.dart';

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

    return SectionCard(
      title: loc.additionalNotes,
      icon: Icons.note,
      isCollapsible: false,
      semanticIdentifier: 'additionalNotesCard',
      child: LabeledField(
        label: loc.notes,
        hintText: loc.enterNotes,
        initialValue: notes ?? '',
        onChanged: onNotesChanged,
        isMultiline: true,
        maxLines: 4,
        keyboardType: TextInputType.multiline,
        semanticIdentifier: 'notesInputField',
      ),
    );
  }
}
