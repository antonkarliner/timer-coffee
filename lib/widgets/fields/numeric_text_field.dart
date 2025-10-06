import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import 'labeled_field.dart';
import '../../l10n/app_localizations.dart';

/// A specialized numeric text field that prevents automatic decimal formatting
/// and handles natural number entry properly.
class NumericTextField extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed inside the field when empty
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial value of the field
  final double? initialValue;

  /// Callback when the field value changes
  final ValueChanged<double?>? onChanged;

  /// Callback when the field is submitted
  final ValueChanged<double?>? onSubmitted;

  /// Validator function for the field
  final FormFieldValidator<double?>? validator;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool required;

  /// Whether to allow decimal values
  final bool allowDecimal;

  /// Maximum number of decimal places allowed
  final int maxDecimalPlaces;

  /// Minimum allowed value
  final double? min;

  /// Maximum allowed value
  final double? max;

  /// Semantic identifier for accessibility
  final String? semanticIdentifier;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  const NumericTextField({
    Key? key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.allowDecimal = false,
    this.maxDecimalPlaces = 2,
    this.min,
    this.max,
    this.semanticIdentifier,
    this.focusNode,
  }) : super(key: key);

  @override
  State<NumericTextField> createState() => _NumericTextFieldState();
}

class _NumericTextFieldState extends State<NumericTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  String _lastValidInput = '';

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = TextEditingController();

    // Set initial value
    if (widget.initialValue != null) {
      _updateDisplayValue(widget.initialValue!);
    }

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(NumericTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update display value if initial value changed
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _getCurrentValue()) {
      if (widget.initialValue != null) {
        _updateDisplayValue(widget.initialValue!);
      } else {
        _controller.clear();
        _lastValidInput = '';
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Handle focus changes if needed
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      _lastValidInput = '';
      widget.onChanged?.call(null);
      return;
    }

    // Try to parse the input
    final value = double.tryParse(text);
    if (value == null) {
      // Invalid input, restore last valid value but preserve cursor position
      if (_lastValidInput.isNotEmpty) {
        final currentSelection = _controller.selection;
        _controller.value = TextEditingValue(
          text: _lastValidInput,
          selection: currentSelection.baseOffset < _lastValidInput.length
              ? TextSelection.collapsed(offset: currentSelection.baseOffset)
              : TextSelection.collapsed(offset: _lastValidInput.length),
        );
      }
      return;
    }

    _lastValidInput = text;
    widget.onChanged?.call(value);
  }

  void _updateDisplayValue(double value) {
    // Only show decimal places if the value is not a whole number
    if (widget.allowDecimal && value != value.truncate()) {
      _controller.text = value.toStringAsFixed(widget.maxDecimalPlaces);
    } else {
      _controller.text = value.truncate().toString();
    }
    _lastValidInput = _controller.text;
  }

  double? _getCurrentValue() {
    if (_controller.text.isEmpty) {
      return null;
    }
    return double.tryParse(_controller.text);
  }

  String? _validateInput(String? value) {
    if (widget.required && (value == null || value.isEmpty)) {
      return AppLocalizations.of(context)!.numericFieldRequiredError;
    }

    if (value == null || value.isEmpty) {
      return null;
    }

    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return AppLocalizations.of(context)!.numericFieldInvalidNumberError;
    }

    if (widget.min != null && numericValue < widget.min!) {
      return AppLocalizations.of(context)!
          .numericFieldMinValueError(widget.min!);
    }

    if (widget.max != null && numericValue > widget.max!) {
      return AppLocalizations.of(context)!
          .numericFieldMaxValueError(widget.max!);
    }

    // Call custom validator if provided
    if (widget.validator != null) {
      return widget.validator!(numericValue);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      initialValue: widget.initialValue?.toString(),
      keyboardType:
          TextInputType.text, // Use text to avoid automatic decimal formatting
      enabled: widget.enabled,
      required: widget.required,
      semanticIdentifier: widget.semanticIdentifier,
      focusNode: _focusNode,
      controller: _controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(widget.allowDecimal ? r'^\d+\.?\d*' : r'^\d+')),
      ],
      validator: _validateInput,
      onChanged: (value) {
        // This is handled by the _onTextChanged listener
      },
      onSubmitted: (value) {
        final numericValue = value.isNotEmpty ? double.tryParse(value) : null;
        widget.onSubmitted?.call(numericValue);
      },
    );
  }
}
