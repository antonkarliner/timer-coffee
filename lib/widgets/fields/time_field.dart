import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import 'labeled_field.dart';

/// A standardized time selection field component that provides a consistent
/// interface for time selection using the app's design system.
///
/// Mirrors [DateField] in structure and styling. Displays as a read-only field
/// with a clock icon that opens a custom scroll-wheel time picker dialog when
/// tapped. Respects the device's 24h/12h format preference.
class TimeField extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed when no time is selected
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial time value
  final TimeOfDay? initialValue;

  /// Callback when the time value changes
  final ValueChanged<TimeOfDay?>? onChanged;

  /// Whether the field is enabled
  final bool enabled;

  const TimeField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  TimeOfDay? _selectedTime;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _selectedTime = widget.initialValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDisplayValue();
  }

  @override
  void didUpdateWidget(TimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _selectedTime = widget.initialValue;
      _updateDisplayValue();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDisplayValue() {
    if (_selectedTime != null) {
      final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
      final dt = DateTime(2000, 1, 1, _selectedTime!.hour, _selectedTime!.minute);
      _controller.text =
          use24h ? DateFormat('HH:mm').format(dt) : DateFormat('h:mm a').format(dt);
    } else {
      _controller.clear();
    }
  }

  Future<void> _pickTime() async {
    if (!widget.enabled) return;

    final result = await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TimePickerDialog(
        initialTime: _selectedTime ?? TimeOfDay.now(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTime = result;
        _updateDisplayValue();
      });
      widget.onChanged?.call(result);
    }
  }

  Widget _buildSuffixIcon() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.enabled ? _pickTime : null,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        constraints: const BoxConstraints(
          minWidth: 44.0,
          minHeight: 44.0,
        ),
        child: Icon(
          Icons.access_time,
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
    final hintText = widget.hintText ?? loc.selectTime;
    final theme = Theme.of(context);

    return Semantics(
      button: widget.enabled,
      onTap: widget.enabled ? _pickTime : null,
      label: widget.label,
      child: LabeledField(
        label: widget.label,
        hintText: hintText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        initialValue: _controller.text.isNotEmpty ? _controller.text : null,
        enabled: widget.enabled,
        suffixIcon: _buildSuffixIcon(),
        controller: _controller,
        keyboardType: TextInputType.none,
        readOnly: true,
        onTap: widget.enabled ? _pickTime : null,
        onChanged: (_) {},
        style: theme.textTheme.bodyLarge?.copyWith(
          color: _selectedTime != null
              ? theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Public helper — use this anywhere you need the app's scroll-wheel picker
// ---------------------------------------------------------------------------

/// Opens the app's custom scroll-wheel time picker dialog.
/// Returns the selected [TimeOfDay], or `null` if cancelled.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _TimePickerDialog(initialTime: initialTime),
  );
}

// ---------------------------------------------------------------------------
// Internal time picker dialog
// ---------------------------------------------------------------------------

class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const _TimePickerDialog({required this.initialTime});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late bool _use24h;
  late int _hour; // 0–23
  late int _minute;
  late bool _isAm;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _isAm = _hour < 12;
    // Use platform dispatcher for 24h check in initState (no BuildContext needed)
    _use24h = WidgetsBinding
        .instance.platformDispatcher.alwaysUse24HourFormat;
    final displayHour = _use24h
        ? _hour
        : (_hour == 0
            ? 12
            : _hour > 12
                ? _hour - 12
                : _hour);
    _hourController = FixedExtentScrollController(
      initialItem: _use24h ? _hour : (displayHour - 1),
    );
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update _use24h for rendering; controllers are NOT recreated
    _use24h = MediaQuery.of(context).alwaysUse24HourFormat;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int get _hourCount => _use24h ? 24 : 12;

  int _resolveHour(int displayIndex) {
    if (_use24h) return displayIndex;
    // 12h: index 0 = 12, index 1 = 1, ..., index 11 = 11
    final h = displayIndex + 1; // 1–12
    if (_isAm) {
      return h == 12 ? 0 : h;
    } else {
      return h == 12 ? 12 : h + 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(
        loc.selectTime,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        height: 176,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hours
            _buildColumn(
              controller: _hourController,
              count: _hourCount,
              selectedIndex: _use24h
                  ? _hour
                  : (_hour == 0
                          ? 12
                          : _hour > 12
                              ? _hour - 12
                              : _hour) -
                      1,
              labelBuilder: (i) => _use24h
                  ? i.toString().padLeft(2, '0')
                  : (i + 1).toString(),
              onChanged: (i) => setState(() {
                _hour = _resolveHour(i);
              }),
              colorScheme: colorScheme,
            ),

            // Separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // Minutes
            _buildColumn(
              controller: _minuteController,
              count: 60,
              selectedIndex: _minute,
              labelBuilder: (i) => i.toString().padLeft(2, '0'),
              onChanged: (i) => setState(() => _minute = i),
              colorScheme: colorScheme,
            ),

            // AM/PM toggle (12h only)
            if (!_use24h) ...[
              const SizedBox(width: 12),
              _buildAmPmToggle(colorScheme),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(TimeOfDay(hour: _hour, minute: _minute)),
          child: Text(loc.ok),
        ),
      ],
    );
  }

  Widget _buildColumn({
    required FixedExtentScrollController controller,
    required int count,
    required int selectedIndex,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: 56,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index >= count) return null;
            final isSelected = index == selectedIndex;
            return Center(
              child: Text(
                labelBuilder(index),
                style: TextStyle(
                  fontSize: isSelected ? 20 : 16,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          },
          childCount: count,
        ),
      ),
    );
  }

  Widget _buildAmPmToggle(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AmPmButton(
          label: 'AM',
          selected: _isAm,
          onTap: () {
            if (!_isAm) {
              setState(() {
                _isAm = true;
                _hour = _hour >= 12 ? _hour - 12 : _hour;
              });
            }
          },
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 8),
        _AmPmButton(
          label: 'PM',
          selected: !_isAm,
          onTap: () {
            if (_isAm) {
              setState(() {
                _isAm = false;
                _hour = _hour < 12 ? _hour + 12 : _hour;
              });
            }
          },
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _AmPmButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _AmPmButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
