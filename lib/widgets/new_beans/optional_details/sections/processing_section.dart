import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/autocomplete_input_field.dart';
import 'package:coffee_timer/widgets/new_beans/section_header.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class ProcessingSection extends StatefulWidget {
  final String? processingMethod;
  final String? roastLevel;

  final Future<List<String>> processingMethodOptions;
  final Future<List<String>> roastLevelOptions;

  final ValueChanged<String?> onProcessingMethodChanged;
  final ValueChanged<String?> onRoastLevelChanged;

  const ProcessingSection({
    super.key,
    this.processingMethod,
    this.roastLevel,
    required this.processingMethodOptions,
    required this.roastLevelOptions,
    required this.onProcessingMethodChanged,
    required this.onRoastLevelChanged,
  });

  @override
  State<ProcessingSection> createState() => _ProcessingSectionState();
}

class _ProcessingSectionState extends State<ProcessingSection> {
  late Future<List<String>> _processingMethodFuture;
  late Future<List<String>> _roastLevelFuture;

  @override
  void initState() {
    super.initState();
    _processingMethodFuture = widget.processingMethodOptions;
    _roastLevelFuture = widget.roastLevelOptions;
  }

  @override
  void didUpdateWidget(covariant ProcessingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.processingMethodOptions != widget.processingMethodOptions) {
      _processingMethodFuture = widget.processingMethodOptions;
    }
    if (oldWidget.roastLevelOptions != widget.roastLevelOptions) {
      _roastLevelFuture = widget.roastLevelOptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: Icons.settings, title: loc.processing),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'processingMethodInputField',
          label: loc.processingMethod,
          child: AutocompleteInputField(
            label: loc.processingMethod,
            hintText: loc.enterProcessingMethod,
            initialOptions: _processingMethodFuture,
            // Only commit changes when a suggestion is selected to avoid rebuilds while typing.
            onSelected: (v) =>
                widget.onProcessingMethodChanged(v.isEmpty ? null : v),
            onChanged: (v) => widget.onProcessingMethodChanged(
                v.isEmpty ? null : v), // Add onChanged callback
            initialValue: widget.processingMethod,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'roastLevelInputField',
          label: loc.roastLevel,
          child: AutocompleteInputField(
            label: loc.roastLevel,
            hintText: loc.enterRoastLevel,
            initialOptions: _roastLevelFuture,
            // Only commit on selection to avoid focus loss during typing.
            onSelected: (v) => widget.onRoastLevelChanged(v.isEmpty ? null : v),
            onChanged: (v) => widget.onRoastLevelChanged(
                v.isEmpty ? null : v), // Add onChanged callback
            initialValue: widget.roastLevel,
          ),
        ),
      ],
    );
  }
}
