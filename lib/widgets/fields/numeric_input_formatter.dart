import 'package:flutter/services.dart';

/// A custom TextInputFormatter that allows natural numeric input
/// without automatically formatting or adding decimal points.
class NumericInputFormatter extends TextInputFormatter {
  /// Whether to allow decimal points
  final bool allowDecimal;

  /// Whether to allow negative numbers
  final bool allowNegative;

  /// Maximum number of decimal places allowed (only used if allowDecimal is true)
  final int? maxDecimalPlaces;

  const NumericInputFormatter({
    this.allowDecimal = true,
    this.allowNegative = false,
    this.maxDecimalPlaces,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, allow it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Check if the input is valid
    final String text = newValue.text;

    // Allow negative sign at the beginning if negative numbers are allowed
    if (allowNegative && text == '-') {
      return newValue;
    }

    // Special case: prevent automatic decimal insertion
    // This handles the case where typing "5" becomes "5."
    // We need to check if this is a single digit that should remain as is
    if (oldValue.text.isEmpty &&
        text.length == 1 &&
        RegExp(r'\d').hasMatch(text)) {
      return newValue;
    }

    // Special case: handle the case where typing "55" becomes "5.5"
    // This happens when the system tries to insert a decimal automatically
    if (oldValue.text.length == 1 &&
        RegExp(r'\d').hasMatch(oldValue.text) &&
        text.length == 3 &&
        text.contains('.') &&
        text[0] == oldValue.text &&
        text[2] == oldValue.text) {
      // Replace with "55"
      return TextEditingValue(
        text: oldValue.text + text[2],
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    // Create a regex pattern based on the allowed characters
    String pattern = r'^';

    if (allowNegative) {
      pattern += r'-?';
    }

    pattern += r'\d';

    if (allowDecimal) {
      pattern +=
          r'(?:\.\d{0,' + (maxDecimalPlaces?.toString() ?? '10') + r'})?';
    }

    pattern += r'$';

    final regex = RegExp(pattern);

    // If the input doesn't match the pattern, reject it
    if (!regex.hasMatch(text)) {
      return oldValue;
    }

    // If we're allowing decimals but there's already a decimal point,
    // don't allow another one
    if (allowDecimal && text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2) {
        return oldValue;
      }

      // Check if we exceed the maximum decimal places
      if (maxDecimalPlaces != null && parts.length == 2) {
        if (parts[1].length > maxDecimalPlaces!) {
          return oldValue;
        }
      }
    }

    return newValue;
  }
}
