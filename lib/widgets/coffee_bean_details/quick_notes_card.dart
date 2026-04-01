import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';

import '../../controllers/coffee_beans_detail_controller.dart';
import '../../models/coffee_beans_model.dart';

/// Inline quick-edit notes card for the coffee beans detail screen.
///
/// Always renders (even when notes are empty) so users can quickly add notes
/// without navigating to the full edit screen.
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
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _textController.text = widget.bean.notes ?? '';
    setState(() => _isEditing = false);
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    await widget.controller.saveNotes(context, _textController.text);
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
                  Text(
                    loc.additionalNotes,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
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
                      onTap: _isSaving ? null : _saveNotes,
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

              const SizedBox(height: AppSpacing.sm),

              if (_isEditing)
                LabeledField(
                  controller: _textController,
                  label: loc.notes,
                  isMultiline: true,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  semanticIdentifier: 'quickNotesInputField',
                )
              else
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
          ),
        ),
      ),
    );
  }
}
