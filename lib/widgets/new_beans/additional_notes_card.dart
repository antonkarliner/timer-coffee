import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import '../containers/section_card.dart';
import '../fields/dropdown_search_field.dart';
import '../fields/labeled_field.dart';

class AdditionalNotesCard extends StatefulWidget {
  final String? notes;
  final ValueChanged<String> onNotesChanged;
  final String? grindSize;
  final Future<List<String>> grindSizeOptions;
  final ValueChanged<String?> onGrindSizeChanged;

  const AdditionalNotesCard({
    super.key,
    required this.notes,
    required this.onNotesChanged,
    required this.grindSize,
    required this.grindSizeOptions,
    required this.onGrindSizeChanged,
  });

  @override
  State<AdditionalNotesCard> createState() => _AdditionalNotesCardState();
}

class _AdditionalNotesCardState extends State<AdditionalNotesCard> {
  late Future<List<String>> _grindSizeFuture;

  @override
  void initState() {
    super.initState();
    _grindSizeFuture = widget.grindSizeOptions;
  }

  @override
  void didUpdateWidget(covariant AdditionalNotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.grindSizeOptions != widget.grindSizeOptions) {
      _grindSizeFuture = widget.grindSizeOptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SectionCard(
      title: loc.beanNotesPreferences,
      icon: Icons.note,
      isCollapsible: false,
      semanticIdentifier: 'additionalNotesCard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grind Size Field
          DropdownSearchField(
            label: loc.grindsize,
            hintText: loc.enterBeanGrindSize,
            initialValue: widget.grindSize,
            semanticIdentifier: 'grindSizeInputField',
            onSearch: (query) async {
              final options = await _grindSizeFuture;
              if (query.isEmpty) return options;
              return options
                  .where((option) =>
                      option.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            },
            onChanged: widget.onGrindSizeChanged,
          ),

          const SizedBox(height: AppSpacing.fieldGap),

          // Notes Field
          LabeledField(
            label: loc.additionalNotes,
            hintText: loc.enterNotes,
            initialValue: widget.notes ?? '',
            onChanged: widget.onNotesChanged,
            isMultiline: true,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            semanticIdentifier: 'notesInputField',
          ),
        ],
      ),
    );
  }
}
