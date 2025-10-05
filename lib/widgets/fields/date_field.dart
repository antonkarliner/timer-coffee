import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import 'labeled_field.dart';

/// A standardized date selection field component that provides a consistent
/// interface for date selection using the app's design system.
///
/// This component displays as a read-only field with a calendar icon that
/// opens a date picker when tapped. It handles locale-aware date formatting
/// and returns ISO string format for consistent data storage.
class DateField extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed when no date is selected
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial date value as an ISO string
  final String? initialValue;

  /// Callback when the date value changes
  final ValueChanged<String?>? onChanged;

  /// Validator function for the field
  final FormFieldValidator<String>? validator;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool required;

  /// Semantic identifier for accessibility
  final String? semanticIdentifier;

  /// The first date that can be selected
  final DateTime? firstDate;

  /// The last date that can be selected
  final DateTime? lastDate;

  /// The currently displayed date in the picker
  final DateTime? currentDate;

  /// Whether to show a clear button when a date is selected
  final bool showClearButton;

  const DateField({
    Key? key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.semanticIdentifier,
    this.firstDate,
    this.lastDate,
    this.currentDate,
    this.showClearButton = true,
  }) : super(key: key);

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  DateTime? _selectedDate;
  String? _displayValue;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _initializeDate();
  }

  @override
  void didUpdateWidget(DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _initializeDate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeDate() {
    if (widget.initialValue != null) {
      try {
        _selectedDate = DateTime.parse(widget.initialValue!);
        _updateDisplayValue();
      } catch (e) {
        // Handle invalid date format
        _selectedDate = null;
        _displayValue = null;
        _controller.clear();
      }
    } else {
      _selectedDate = null;
      _displayValue = null;
      _controller.clear();
    }
  }

  void _updateDisplayValue() {
    if (_selectedDate != null) {
      final loc = AppLocalizations.of(context)!;
      final localeName = loc.localeName;
      _displayValue = DateFormat.yMd(localeName).format(_selectedDate!);
      _controller.text = _displayValue!;
    } else {
      _displayValue = null;
      _controller.clear();
    }
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        currentDate: widget.currentDate ?? _selectedDate,
      ),
      dialogSize: const Size(325, 400),
      value: _selectedDate != null ? [_selectedDate!] : [],
      borderRadius: BorderRadius.circular(AppRadius.card),
    );

    if (results != null && results.isNotEmpty) {
      setState(() {
        _selectedDate = results[0];
        _updateDisplayValue();
      });

      // Convert to ISO string for consistent data storage
      final isoString = _selectedDate?.toIso8601String();
      widget.onChanged?.call(isoString);
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _displayValue = null;
      _controller.clear();
    });
    widget.onChanged?.call(null);
    // Unfocus the field to prevent cursor from remaining
    FocusScope.of(context).unfocus();
  }

  Widget? _buildSuffixIcon() {
    final theme = Theme.of(context);

    if (!widget.enabled) return null;

    if (widget.showClearButton && _selectedDate != null) {
      return IconButton(
        icon: Icon(
          Icons.clear,
          size: AppIconSize.small,
        ),
        onPressed: _clearDate,
        tooltip: AppLocalizations.of(context)!.dateFieldClearButtonTooltip,
      );
    }

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        // Ensure minimum hit target size of 44x44
        constraints: const BoxConstraints(
          minWidth: 44.0,
          minHeight: 44.0,
        ),
        child: Icon(
          Icons.calendar_today,
          size: AppIconSize.small,
          color: widget.enabled
              ? (theme.brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade600)
              : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hintText = widget.hintText ?? loc.selectDate;
    final theme = Theme.of(context);

    return Semantics(
      identifier: widget.semanticIdentifier,
      button: widget.enabled,
      onTap: widget.enabled ? _pickDate : null,
      label: widget.label,
      child: LabeledField(
        label: widget.label,
        // Only pass the actual hint text, not the display value
        hintText: hintText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        initialValue: _displayValue,
        enabled: widget.enabled,
        required: widget.required,
        semanticIdentifier: widget.semanticIdentifier,
        suffixIcon: _buildSuffixIcon(),
        // Make it read-only by preventing keyboard input
        // We're using the LabeledField as a base but overriding its behavior
        controller: _controller,
        // Prevent keyboard from appearing
        keyboardType: TextInputType.none,
        // Make the field explicitly read-only
        readOnly: true,
        // Add tap handler to open date picker
        onTap: widget.enabled ? _pickDate : null,
        // Custom validator that works with ISO strings
        validator: widget.validator != null
            ? (value) =>
                widget.validator!(_selectedDate?.toIso8601String() ?? '')
            : null,
        // Override onChanged to prevent manual text input
        onChanged: (value) {
          // No-op - we don't want to allow manual text input
        },
        // Use explicit styling to ensure date text has proper color
        // This ensures the date text is distinct from hint text
        style: theme.textTheme.bodyLarge?.copyWith(
          color: _displayValue != null
              ? theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface
              : null, // Use default for hint text
        ),
      ),
    );
  }
}
