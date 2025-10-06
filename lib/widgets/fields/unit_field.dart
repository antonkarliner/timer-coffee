import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Enum for supported unit types
enum UnitType {
  weight,
  elevation,
}

/// Enum for weight unit options
enum WeightUnit {
  grams,
  ounces,
}

/// Enum for elevation unit options
enum ElevationUnit {
  meters,
  feet,
}

/// A standardized numeric input field with unit conversion capabilities.
///
/// This component provides a consistent interface for numeric inputs that need
/// to support multiple units (e.g., grams/ounces for weight, meters/feet for elevation).
/// The internal value is always stored in the metric unit (grams for weight, meters for elevation)
/// but displayed in the user's preferred unit.
class UnitField extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed inside the field when empty
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial value in the base unit (grams for weight, meters for elevation)
  final double? initialValue;

  /// Callback when the field value changes (in base unit)
  final ValueChanged<double?>? onChanged;

  /// Callback when the field is submitted (in base unit)
  final ValueChanged<double?>? onSubmitted;

  /// Validator function for the field (receives value in base unit)
  final FormFieldValidator<double?>? validator;

  /// The type of units this field supports
  final UnitType unitType;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool required;

  /// Minimum allowed value (in base unit)
  final double? min;

  /// Maximum allowed value (in base unit)
  final double? max;

  /// Number of decimal places to display
  final int decimalPlaces;

  /// Semantic identifier for accessibility
  final String? semanticIdentifier;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  /// Text controller for the field
  final TextEditingController? controller;

  /// Whether to show the unit toggle button
  final bool showUnitToggle;

  /// Initial unit to display
  final WeightUnit? initialWeightUnit;

  /// Initial elevation unit to display
  final ElevationUnit? initialElevationUnit;

  const UnitField({
    Key? key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    required this.unitType,
    this.enabled = true,
    this.required = false,
    this.min,
    this.max,
    this.decimalPlaces = 2,
    this.semanticIdentifier,
    this.focusNode,
    this.controller,
    this.showUnitToggle = true,
    this.initialWeightUnit,
    this.initialElevationUnit,
  }) : super(key: key);

  @override
  State<UnitField> createState() => _UnitFieldState();
}

class _UnitFieldState extends State<UnitField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  late WeightUnit _currentWeightUnit;
  late ElevationUnit _currentElevationUnit;
  String _lastValidInput = '';

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();

    // Initialize units based on type
    if (widget.unitType == UnitType.weight) {
      _currentWeightUnit = widget.initialWeightUnit ?? WeightUnit.grams;
    } else {
      _currentElevationUnit =
          widget.initialElevationUnit ?? ElevationUnit.meters;
    }

    // Set initial value
    if (widget.initialValue != null) {
      _updateDisplayValue(widget.initialValue!);
    }

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(UnitField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update display value if initial value changed
    if (oldWidget.initialValue != widget.initialValue &&
        widget.controller == null &&
        widget.initialValue != null) {
      _updateDisplayValue(widget.initialValue!);
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
    final baseValue = _convertToBaseUnit(value);
    widget.onChanged?.call(baseValue);
  }

  void _updateDisplayValue(double baseValue) {
    final displayValue = _convertFromBaseUnit(baseValue);
    // Only show decimal places if the value is not a whole number
    if (displayValue == displayValue.truncate()) {
      _controller.text = displayValue.truncate().toString();
    } else {
      _controller.text = displayValue.toStringAsFixed(widget.decimalPlaces);
    }
    _lastValidInput = _controller.text;
  }

  double _convertToBaseUnit(double displayValue) {
    if (widget.unitType == UnitType.weight) {
      switch (_currentWeightUnit) {
        case WeightUnit.grams:
          return displayValue;
        case WeightUnit.ounces:
          return displayValue * 28.3495; // 1 oz = 28.3495 g
      }
    } else {
      switch (_currentElevationUnit) {
        case ElevationUnit.meters:
          return displayValue;
        case ElevationUnit.feet:
          return displayValue * 0.3048; // 1 ft = 0.3048 m
      }
    }
  }

  double _convertFromBaseUnit(double baseValue) {
    if (widget.unitType == UnitType.weight) {
      switch (_currentWeightUnit) {
        case WeightUnit.grams:
          return baseValue;
        case WeightUnit.ounces:
          return baseValue / 28.3495; // 1 g = 0.035274 oz
      }
    } else {
      switch (_currentElevationUnit) {
        case ElevationUnit.meters:
          return baseValue;
        case ElevationUnit.feet:
          return baseValue / 0.3048; // 1 m = 3.28084 ft
      }
    }
  }

  String _getCurrentUnitLabel() {
    if (widget.unitType == UnitType.weight) {
      switch (_currentWeightUnit) {
        case WeightUnit.grams:
          return 'g';
        case WeightUnit.ounces:
          return 'oz';
      }
    } else {
      switch (_currentElevationUnit) {
        case ElevationUnit.meters:
          return 'm';
        case ElevationUnit.feet:
          return 'ft';
      }
    }
  }

  void _toggleUnit() {
    setState(() {
      // Save current value in base unit
      final currentValue = _controller.text.isNotEmpty
          ? _convertToBaseUnit(double.tryParse(_controller.text) ?? 0)
          : null;

      // Toggle unit
      if (widget.unitType == UnitType.weight) {
        _currentWeightUnit = _currentWeightUnit == WeightUnit.grams
            ? WeightUnit.ounces
            : WeightUnit.grams;
      } else {
        _currentElevationUnit = _currentElevationUnit == ElevationUnit.meters
            ? ElevationUnit.feet
            : ElevationUnit.meters;
      }

      // Update display with new unit
      if (currentValue != null) {
        _updateDisplayValue(currentValue);
      }
    });
  }

  String? _validateInput(String? value) {
    if (widget.required && (value == null || value.isEmpty)) {
      return AppLocalizations.of(context)!.unitFieldRequiredError;
    }

    if (value == null || value.isEmpty) {
      return null;
    }

    final numericValue = double.tryParse(value);
    if (numericValue == null) {
      return AppLocalizations.of(context)!.unitFieldInvalidNumberError;
    }

    final baseValue = _convertToBaseUnit(numericValue);

    if (widget.min != null && baseValue < widget.min!) {
      return AppLocalizations.of(context)!.unitFieldMinValueError(widget.min!);
    }

    if (widget.max != null && baseValue > widget.max!) {
      return AppLocalizations.of(context)!.unitFieldMaxValueError(widget.max!);
    }

    // Call custom validator if provided
    if (widget.validator != null) {
      return widget.validator!(baseValue);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

        // Text Field with Unit Toggle
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: _validateInput,
          onFieldSubmitted: (value) {
            final baseValue = value.isNotEmpty
                ? _convertToBaseUnit(double.tryParse(value) ?? 0)
                : null;
            widget.onSubmitted?.call(baseValue);
          },
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            suffixIcon: widget.showUnitToggle
                ? _buildUnitToggle()
                : _buildUnitDisplay(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: const BorderSide(
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

  Widget _buildUnitToggle() {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? _toggleUnit : null,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                width: AppStroke.border,
              ),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getCurrentUnitLabel(),
                  style: AppTextStyles.body.copyWith(
                    color: widget.enabled
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.enabled) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.swap_horiz,
                    size: AppIconSize.small,
                    color: Colors.grey.shade600,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDisplay() {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        _getCurrentUnitLabel(),
        style: AppTextStyles.body.copyWith(
          color: widget.enabled
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
