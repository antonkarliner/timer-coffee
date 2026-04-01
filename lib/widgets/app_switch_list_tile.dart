import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// App-standard replacement for [SwitchListTile].
///
/// Uses [AnimatedToggleSwitch.dual] so the thumb and track sizes are
/// fully independent — no oval distortion, full color control per state.
/// Tapping anywhere on the tile toggles the value.
class AppSwitchListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      // Tighter vertical rhythm — sheds ~4 dp vs the default ListTile height.
      visualDensity: const VisualDensity(vertical: -1),
      // Lock horizontal padding to the app baseline (16 dp).
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 1),
              ),
            )
          : null,
      trailing: AnimatedToggleSwitch<bool>.dual(
        current: value,
        first: false,
        second: true,
        height: 30,
        spacing: 5,
        indicatorSize: const Size(22, 22),
        borderWidth: 1.5,
        // Horizontal gap between thumb and track edge; vertical kept tight.
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        styleBuilder: (v) => ToggleStyle(
          // Track: transparent + outline when off, primary filled when on
          backgroundColor: v ? colorScheme.primary : Colors.transparent,
          borderColor: v ? colorScheme.primary : colorScheme.outline,
          // Thumb: white when on, muted when off
          indicatorColor: v
              ? colorScheme.onPrimary
              : colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(15),
          indicatorBorderRadius: BorderRadius.circular(11),
        ),
        onChanged: onChanged != null ? (v) => onChanged!(v) : null,
      ),
      onTap: onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}
