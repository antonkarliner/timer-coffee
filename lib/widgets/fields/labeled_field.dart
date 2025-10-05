import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// A standardized form field component that wraps TextFormField with consistent
/// label, hint, helper, and error display using the app's design system.
class LabeledField extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed inside the field when empty
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial value of the field
  final String? initialValue;

  /// Callback when the field value changes
  final ValueChanged<String>? onChanged;

  /// Callback when the field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Validator function for the field
  final FormFieldValidator<String>? validator;

  /// Keyboard type for the field
  final TextInputType keyboardType;

  /// Whether the field is multiline
  final bool isMultiline;

  /// Maximum number of lines for multiline fields
  final int? maxLines;

  /// Minimum number of lines for multiline fields
  final int? minLines;

  /// Maximum number of characters allowed
  final int? maxLength;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool required;

  /// Input formatters for the field
  final List<TextInputFormatter>? inputFormatters;

  /// Text capitalization behavior
  final TextCapitalization textCapitalization;

  /// Semantic identifier for accessibility
  final String? semanticIdentifier;

  /// Action button to show on the keyboard
  final TextInputAction? textInputAction;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  /// Text controller for the field
  final TextEditingController? controller;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// Whether to show a clear button
  final bool showClearButton;

  /// Icon to show at the end of the field
  final Widget? suffixIcon;

  /// Icon to show at the beginning of the field
  final Widget? prefixIcon;

  /// Text style for the input field
  final TextStyle? style;

  /// Whether the field is read-only
  final bool readOnly;

  /// Callback when the field is tapped (useful for read-only fields)
  final VoidCallback? onTap;

  const LabeledField({
    Key? key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isMultiline = false,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.required = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.semanticIdentifier,
    this.textInputAction,
    this.focusNode,
    this.controller,
    this.obscureText = false,
    this.showClearButton = false,
    this.suffixIcon,
    this.prefixIcon,
    this.style,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(LabeledField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        widget.controller == null &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onTextChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _onClear() {
    _controller.clear();
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine field border color based on state and theme
    Color borderColor;
    if (widget.errorText != null) {
      borderColor = Colors.red;
    } else if (_isFocused) {
      borderColor = theme.brightness == Brightness.dark
          ? Colors.grey.shade300
          : Colors.grey.shade700;
    } else {
      borderColor = theme.brightness == Brightness.dark
          ? Colors.grey.shade500
          : Colors.grey.shade300;
    }

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
                style: AppTextStyles.fieldLabel.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Text Field
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          maxLines: widget.isMultiline ? (widget.maxLines ?? null) : 1,
          minLines: widget.isMultiline ? (widget.minLines ?? null) : null,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: widget.style ?? theme.textTheme.bodyLarge,
          readOnly: widget.readOnly,
          // Add tap handler when field is read-only
          onTap: widget.readOnly && widget.onTap != null ? widget.onTap : null,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: BorderSide(
                color: borderColor,
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
            // Use the provided style for the input text
            // This ensures the style is applied correctly
            helperStyle: AppTextStyles.body.copyWith(
              color: Colors.grey.shade600,
            ),
            errorStyle: AppTextStyles.body.copyWith(
              color: Colors.red,
            ),
          ),
        ),

        // Error message (if not shown in the field)
        if (widget.errorText != null && widget.errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.body.copyWith(
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    if (widget.showClearButton && _controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(
          Icons.clear,
          size: AppIconSize.small,
        ),
        onPressed: _onClear,
        tooltip: AppLocalizations.of(context)!.fieldClearButtonTooltip,
      );
    }

    return null;
  }
}
