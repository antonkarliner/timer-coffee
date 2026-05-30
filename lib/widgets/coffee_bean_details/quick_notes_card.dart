import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';

import '../../controllers/coffee_beans_detail_controller.dart';
import '../../models/coffee_beans_model.dart';
import '../../providers/coffee_beans_provider.dart';
import 'detail_item_row.dart';

/// Inline quick-edit "Notes & Preferences" card for the coffee beans detail
/// screen. Holds the grind size and additional notes fields.
///
/// Always renders (even when empty) so users can quickly add a grind size or
/// notes without navigating to the full edit screen.
class QuickNotesCard extends StatefulWidget {
  final CoffeeBeansModel bean;
  final CoffeeBeansDetailController controller;

  const QuickNotesCard({
    super.key,
    required this.bean,
    required this.controller,
  });

  @override
  State<QuickNotesCard> createState() => _QuickNotesCardState();
}

class _QuickNotesCardState extends State<QuickNotesCard> {
  late final TextEditingController _textController;
  String _grindSizeValue = '';
  Future<List<String>> _grindSizeOptions = Future.value(const []);
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.bean.notes ?? '');
  }

  @override
  void didUpdateWidget(QuickNotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.bean.notes != widget.bean.notes) {
      _textController.text = widget.bean.notes ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startEditing() {
    _textController.text = widget.bean.notes ?? '';
    _grindSizeValue = widget.bean.grindSize ?? '';
    _grindSizeOptions =
        Provider.of<CoffeeBeansProvider>(context, listen: false)
            .fetchAllDistinctGrindSizes();
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _textController.text = widget.bean.notes ?? '';
    _grindSizeValue = widget.bean.grindSize ?? '';
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.controller.saveNotesAndGrindSize(
      context,
      notes: _textController.text,
      grindSize: _grindSizeValue,
    );
    if (mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hasNotes = (widget.bean.notes ?? '').isNotEmpty;
    final hasGrindSize = (widget.bean.grindSize ?? '').isNotEmpty;

    return Semantics(
      identifier: 'quickNotesCard_${widget.bean.beansUuid}',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row — edit/save/cancel icons always visible here
              Row(
                children: [
                  Icon(
                    Icons.note,
                    color: colorScheme.primary,
                    size: AppIconSize.medium,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      loc.beanNotesPreferences,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isEditing) ...[
                    GestureDetector(
                      onTap: _isSaving ? null : _cancelEditing,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: _isSaving ? null : _save,
                      child: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.check,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                    ),
                  ] else
                    GestureDetector(
                      onTap: _startEditing,
                      child: const Icon(Icons.edit, size: 18),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.base),

              if (_isEditing) ...[
                // Grind Size Field
                DropdownSearchField(
                  label: loc.grindsize,
                  hintText: loc.enterBeanGrindSize,
                  initialValue: _grindSizeValue,
                  semanticIdentifier: 'quickGrindSizeInputField',
                  onSearch: (query) async {
                    final options = await _grindSizeOptions;
                    if (query.isEmpty) return options;
                    return options
                        .where((option) =>
                            option.toLowerCase().contains(query.toLowerCase()))
                        .toList();
                  },
                  onChanged: (v) => _grindSizeValue = v,
                ),

                const SizedBox(height: AppSpacing.fieldGap),

                // Notes Field
                LabeledField(
                  controller: _textController,
                  label: loc.additionalNotes,
                  isMultiline: true,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  semanticIdentifier: 'quickNotesInputField',
                ),
              ] else ...[
                // Grind size (read-only) — tap to edit
                if (hasGrindSize) ...[
                  GestureDetector(
                    onTap: _startEditing,
                    behavior: HitTestBehavior.opaque,
                    child: DetailItemRow(
                      label: loc.grindsize,
                      value: widget.bean.grindSize,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // Notes (read-only) — tap to edit
                GestureDetector(
                  onTap: _startEditing,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    identifier: 'additionalNotes_${widget.bean.beansUuid}',
                    label: hasNotes
                        ? '${loc.additionalNotes}: ${widget.bean.notes}'
                        : loc.additionalNotes,
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Text(
                          hasNotes ? widget.bean.notes! : '–',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: hasNotes
                                ? null
                                : colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
