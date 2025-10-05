import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
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
        // Processing Method Field
        DropdownSearchField(
          label: loc.processingMethod,
          hintText: loc.enterProcessingMethod,
          initialValue: widget.processingMethod,
          semanticIdentifier: 'processingMethodInputField',
          onSearch: (query) async {
            final options = await _processingMethodFuture;
            if (query.isEmpty) return options;
            return options
                .where((option) =>
                    option.toLowerCase().contains(query.toLowerCase()))
                .toList();
          },
          onChanged: (value) {
            widget.onProcessingMethodChanged(value.isEmpty ? null : value);
          },
        ),

        const SizedBox(height: AppSpacing.fieldGap),

        // Roast Level Field
        DropdownSearchField(
          label: loc.roastLevel,
          hintText: loc.enterRoastLevel,
          initialValue: widget.roastLevel,
          semanticIdentifier: 'roastLevelInputField',
          onSearch: (query) async {
            final options = await _roastLevelFuture;
            if (query.isEmpty) return options;
            return options
                .where((option) =>
                    option.toLowerCase().contains(query.toLowerCase()))
                .toList();
          },
          onChanged: (value) {
            widget.onRoastLevelChanged(value.isEmpty ? null : value);
          },
        ),
      ],
    );
  }
}
