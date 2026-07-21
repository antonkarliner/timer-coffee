import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Returns [chips] plus the not-yet-committed [pendingText] from a chip
/// input field, so saving never silently drops text the user typed but did
/// not submit as a chip. The pending text is trimmed and skipped when empty
/// or already present, mirroring [ChipInput]'s duplicate rule.
List<String> chipsWithPending(List<String> chips, String pendingText) {
  final pending = pendingText.trim();
  if (pending.isEmpty || chips.contains(pending)) return chips;
  return [...chips, pending];
}

/// A standardized chip input component that provides tag/chip input functionality
/// with autocomplete suggestions, validation, and consistent styling.
class ChipInput extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed inside the field when empty
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial list of chips/tags
  final List<String>? initialValues;

  /// Callback when chips are added or removed
  final ValueChanged<List<String>>? onChanged;

  /// List of suggestions for autocomplete
  final List<String> suggestions;

  /// Whether to show autocomplete suggestions
  final bool showSuggestions;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool required;

  /// Maximum number of chips allowed
  final int? maxChips;

  /// Validator function for individual chips
  final FormFieldValidator<String>? chipValidator;

  /// Whether to allow duplicate chips
  final bool allowDuplicates;

  /// Whether to trim whitespace from chip values
  final bool trimWhitespace;

  /// Semantic identifier for accessibility
  final String? semanticIdentifier;

  /// Input formatters for the text field
  final List<TextInputFormatter>? inputFormatters;

  /// Text capitalization behavior
  final TextCapitalization textCapitalization;

  /// Whether the platform may autocorrect text while it is entered.
  final bool autocorrect;

  /// Whether committed chip labels use the component's title-case display.
  final bool capitalizeChipLabels;

  /// Optional external controller for the underlying text field.
  ///
  /// Typed text only becomes a chip on submit or suggestion tap; callers that
  /// save through an external button can read this controller's text at save
  /// time so pending input is not silently dropped. Not disposed by ChipInput.
  final TextEditingController? controller;

  /// One-tap "recent" picks rendered below the input field, visible without
  /// typing (unlike [suggestions], which only appear once the user types a
  /// matching query). Picks already present in the current chips are
  /// filtered out and the row is capped at 8 entries.
  final List<String> quickPicks;

  const ChipInput({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValues,
    this.onChanged,
    this.suggestions = const [],
    this.showSuggestions = true,
    this.enabled = true,
    this.required = false,
    this.maxChips,
    this.chipValidator,
    this.allowDuplicates = false,
    this.trimWhitespace = true,
    this.semanticIdentifier,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.capitalizeChipLabels = true,
    this.controller,
    this.quickPicks = const [],
  });

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  List<String> _chips = [];
  bool _isFocused = false;
  bool _isCommittingComma = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _textController = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    if (widget.initialValues != null) {
      _chips = List.from(widget.initialValues!);
    }

    _focusNode.addListener(_onFocusChange);
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(ChipInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _textController.removeListener(_onTextChanged);
      if (oldWidget.controller == null) _textController.dispose();
      _textController = widget.controller ?? TextEditingController();
      _textController.addListener(_onTextChanged);
    }

    if (oldWidget.initialValues != widget.initialValues) {
      if (widget.initialValues != null) {
        _chips = List.from(widget.initialValues!);
      } else {
        _chips.clear();
      }
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    if (widget.controller == null) _textController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });

      if (_isFocused) {
        _showSuggestions();
      } else {
        _removeOverlay();
      }
    }
  }

  void _onTextChanged() {
    _commitOnComma();
    if (_isFocused && widget.showSuggestions) {
      _showSuggestions();
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Commits every comma-delimited segment but the last as a chip, leaving
  /// the remainder (text after the final comma) pending in the field.
  ///
  /// Guarded by [_isCommittingComma] so the controller mutations this makes
  /// (via [_addChip]'s clear and the final remainder assignment) don't
  /// re-enter this method — those re-entrant calls see the flag set and
  /// return immediately.
  void _commitOnComma() {
    if (_isCommittingComma) return;
    final text = _textController.text;
    if (!text.contains(',')) return;

    _isCommittingComma = true;
    try {
      final segments = text.split(',');
      final remainder = segments.removeLast();
      for (final segment in segments) {
        final trimmed = segment.trim();
        if (trimmed.isNotEmpty) {
          _addChip(trimmed);
        }
      }
      _textController.text = remainder;
      _textController.selection = TextSelection.collapsed(
        offset: remainder.length,
      );
    } finally {
      _isCommittingComma = false;
    }
  }

  bool get _atMaxChips =>
      widget.maxChips != null && _chips.length >= widget.maxChips!;

  bool get _canCommitPendingText =>
      _textController.text.trim().isNotEmpty && !_atMaxChips;

  List<String> get _visibleQuickPicks {
    if (widget.quickPicks.isEmpty || _atMaxChips) return const [];
    final lowerChips = _chips.map((chip) => chip.toLowerCase()).toSet();
    return widget.quickPicks
        .where((pick) => !lowerChips.contains(pick.toLowerCase()))
        .take(8)
        .toList();
  }

  void _showSuggestions() {
    if (!widget.showSuggestions || widget.suggestions.isEmpty) {
      _removeOverlay();
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    final filteredSuggestions = _getFilteredSuggestions(text);
    if (filteredSuggestions.isEmpty) {
      _removeOverlay();
      return;
    }

    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _SuggestionsOverlay(
        fieldKey: _fieldKey,
        suggestions: filteredSuggestions,
        onSelect: _addChip,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<String> _getFilteredSuggestions(String query) {
    return widget.suggestions
        .where(
          (suggestion) =>
              suggestion.toLowerCase().contains(query.toLowerCase()) &&
              (!_chips.contains(suggestion) || widget.allowDuplicates),
        )
        .take(8) // Limit to 8 suggestions
        .toList();
  }

  void _addChip(String chip) {
    String processedChip = widget.trimWhitespace ? chip.trim() : chip;

    if (processedChip.isEmpty) return;

    // Validate chip if validator is provided
    if (widget.chipValidator != null) {
      final validationResult = widget.chipValidator!(processedChip);
      if (validationResult != null) {
        _showError(validationResult);
        return;
      }
    }

    // Check for duplicates
    if (!widget.allowDuplicates && _chips.contains(processedChip)) {
      _showError(AppLocalizations.of(context)!.chipInputDuplicateError);
      return;
    }

    // Check max chips limit
    if (widget.maxChips != null && _chips.length >= widget.maxChips!) {
      _showError(
        AppLocalizations.of(context)!.chipInputMaxTagsError(widget.maxChips!),
      );
      return;
    }

    setState(() {
      _chips.add(processedChip);
      _textController.clear();
    });

    _removeOverlay();
    widget.onChanged?.call(_chips);

    // Keep focus on the input field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _removeChip(String chip) {
    setState(() {
      _chips.remove(chip);
    });
    widget.onChanged?.call(_chips);

    // Keep focus on the input field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onFieldSubmitted(String value) {
    if (value.isNotEmpty) {
      _addChip(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: AppTextStyles.fieldLabel.copyWith(
                color: widget.enabled
                    ? theme.textTheme.titleMedium?.color
                    : Colors.grey,
              ),
            ),
            if (widget.required) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '*',
                style: AppTextStyles.fieldLabel.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Chips display area
        if (_chips.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _chips
                .map(
                  (chip) => Chip(
                    label: Text(
                      widget.capitalizeChipLabels ? _capitalize(chip) : chip,
                      style: chipTheme.labelStyle,
                    ),
                    onDeleted: widget.enabled ? () => _removeChip(chip) : null,
                    backgroundColor: chipTheme.backgroundColor,
                    deleteIcon: Icon(
                      Icons.close,
                      size: AppIconSize.small,
                      color: chipTheme.labelStyle?.color,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Input field
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            key: _fieldKey,
            child: TextFormField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: widget.enabled,
              textCapitalization: widget.textCapitalization,
              autocorrect: widget.autocorrect,
              inputFormatters: widget.inputFormatters,
              onFieldSubmitted: _onFieldSubmitted,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText:
                    widget.hintText ??
                    AppLocalizations.of(context)!.chipInputHintText,
                helperText: widget.helperText,
                errorText: widget.errorText,
                suffixIcon: IconButton(
                  tooltip: AppLocalizations.of(context)!.chipInputHintText,
                  icon: const Icon(Icons.add),
                  onPressed: widget.enabled && _canCommitPendingText
                      ? () => _onFieldSubmitted(_textController.text)
                      : null,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.cardPadding,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: AppStroke.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade500
                        : Colors.grey.shade300,
                    width: AppStroke.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                    width: AppStroke.focus,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: AppStroke.border,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: AppStroke.focus,
                  ),
                ),
                hintStyle: AppTextStyles.body.copyWith(
                  color: Colors.grey.shade600,
                ),
                helperStyle: AppTextStyles.body.copyWith(
                  color: Colors.grey.shade600,
                ),
                errorStyle: AppTextStyles.body.copyWith(color: Colors.red),
              ),
            ),
          ),
        ),

        // Quick picks: one-tap "recent" row, visible without typing.
        if (_visibleQuickPicks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _visibleQuickPicks
                .map(
                  (pick) => ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      Icons.add,
                      size: AppIconSize.small,
                      color: chipTheme.labelStyle?.color,
                    ),
                    label: Text(
                      pick,
                      style: AppTextStyles.caption.copyWith(
                        color: chipTheme.labelStyle?.color,
                      ),
                    ),
                    backgroundColor: chipTheme.backgroundColor,
                    onPressed: widget.enabled ? () => _addChip(pick) : null,
                  ),
                )
                .toList(),
          ),
        ],

        // Error message (if not shown in the field)
        if (widget.errorText != null && widget.errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.body.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  String _capitalize(String input) {
    return input
        .split(' ')
        .map((str) {
          if (str.isNotEmpty) {
            return str[0].toUpperCase() + str.substring(1).toLowerCase();
          }
          return str;
        })
        .join(' ');
  }
}

/// Overlay widget for displaying autocomplete suggestions
class _SuggestionsOverlay extends StatefulWidget {
  final GlobalKey fieldKey;
  final List<String> suggestions;
  final Function(String) onSelect;

  const _SuggestionsOverlay({
    required this.fieldKey,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  State<_SuggestionsOverlay> createState() => _SuggestionsOverlayState();
}

class _SuggestionsOverlayState extends State<_SuggestionsOverlay> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renderBox =
        widget.fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final mediaQuery = MediaQuery.of(context);

    if (renderBox == null) return const SizedBox.shrink();

    final fieldSize = renderBox.size;
    final fieldPosition = renderBox.localToGlobal(Offset.zero);

    // Calculate available space
    final safeAreaBottom = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;

    // Position dropdown below the input field
    final top = fieldPosition.dy + fieldSize.height + 4;
    final bottom = screenHeight - safeAreaBottom;

    // Calculate height for dropdown based on actual content
    final maxItemHeight = 48.0;
    final contentHeight = widget.suggestions.length * maxItemHeight;
    final availableHeight = bottom - top - 16; // 16px padding from bottom
    final dropdownHeight = math.min(contentHeight, availableHeight);

    // Calculate horizontal position to stay within screen bounds
    final dropdownWidth = fieldSize.width;
    final screenWidth = mediaQuery.size.width;
    final left = math.max(
      0,
      math.min(fieldPosition.dx, screenWidth - dropdownWidth),
    );

    return Positioned(
      left: left.toDouble(),
      top: top,
      width: dropdownWidth,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: dropdownHeight),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
                width: AppStroke.border,
              ),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                return InkWell(
                  onTap: () => widget.onSelect(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPadding,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
