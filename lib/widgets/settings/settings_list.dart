/// Shared rules for every Settings page:
///
/// 1. Root rows only navigate. No `ExpansionTile` anywhere in Settings.
/// 2. There are three control types: a switch row (`AppSwitchListTile`); a
///    choice row (value on the right, opening a bottom sheet that checks the
///    current option); and a navigation row (chevron, opening a page or flow).
///    The App icon grid is the one sanctioned exception because its options
///    are images.
/// 3. A choice row shows its current value; a switch subtitle is a one-line
///    explanation.
/// 4. Section headers use `SettingsSectionHeader`, matching the Hub style.
/// 5. Dependent rows live in an always-present slot. Keep the widget type at a
///    tree position stable and use `SizedBox.shrink()` when it is empty.
///    Changing the returned type recreates the child element, re-runs
///    `initState`, and has caused a blank-field bug here before.
/// 6. A new setting joins an existing page. A new root row needs a new
///    category.
/// 7. Use design-system tokens and components only, and `showAppTimePicker`
///    for times. Do not hardcode pixels.
library;

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../smart_back_button.dart';

/// A Settings section label matching the Hub section-header style.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.base,
          AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.xs,
        ),
        child: Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// A Settings row that opens another page or flow.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.identifier,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });

  final String identifier;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: identifier,
      button: true,
      container: true,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.base,
        ),
        leading: Icon(icon, size: AppIconSize.medium),
        title: Text(title, style: AppTextStyles.body),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
                child: Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: subtitleColor ?? colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
        trailing: const Icon(Icons.chevron_right, size: AppIconSize.medium),
        onTap: onTap,
      ),
    );
  }
}

/// One value offered by a Settings choice sheet.
class SettingsChoiceOption<T> {
  const SettingsChoiceOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.identifier,
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? identifier;
}

/// Shows a full-width, scrollable Settings choice sheet.
Future<T?> showSettingsChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<SettingsChoiceOption<T>> options,
  required T current,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;

      // Short lists size to their content; long ones (languages) cap at 80%
      // of the screen and scroll.
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: Text(title, style: AppTextStyles.title),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isCurrent = option.value == current;
                    final tile = ListTile(
                      title: Text(option.label, style: AppTextStyles.body),
                      subtitle: option.subtitle == null
                          ? null
                          : Text(
                              option.subtitle!,
                              style: AppTextStyles.caption,
                            ),
                      trailing: isCurrent
                          ? Icon(
                              Icons.check,
                              color: colorScheme.primary,
                              size: AppIconSize.medium,
                            )
                          : null,
                      selected: isCurrent,
                      onTap: () => Navigator.of(context).pop(option.value),
                    );

                    return Semantics(
                      identifier: option.identifier,
                      selected: isCurrent,
                      container: true,
                      child: tile,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A Settings row that displays and changes one value from a fixed list.
class SettingsChoiceRow<T> extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.identifier,
    required this.title,
    this.icon,
    required this.options,
    required this.current,
    required this.onChanged,
    this.sheetTitle,
  });

  final String identifier;
  final String title;
  final IconData? icon;
  final List<SettingsChoiceOption<T>> options;
  final T current;
  final ValueChanged<T> onChanged;
  final String? sheetTitle;

  @override
  Widget build(BuildContext context) {
    // A value missing from the options (e.g. a stale stored locale) shows no
    // label rather than throwing during build.
    final currentLabel = options
        .where((option) => option.value == current)
        .firstOrNull
        ?.label;

    return Semantics(
      identifier: identifier,
      button: true,
      container: true,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.base,
        ),
        leading: icon == null ? null : Icon(icon, size: AppIconSize.medium),
        title: Text(title, style: AppTextStyles.body),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentLabel ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, size: AppIconSize.medium),
          ],
        ),
        onTap: () async {
          final value = await showSettingsChoiceSheet<T>(
            context: context,
            title: sheetTitle ?? title,
            options: options,
            current: current,
          );
          if (!context.mounted) return;
          if (value != null && value != current) onChanged(value);
        },
      ),
    );
  }
}

/// Standard scaffold for a Settings category page.
class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.backButtonIdentifier = 'settingsBackButton',
  });

  final String title;
  final List<Widget> children;
  final String backButtonIdentifier;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: backButtonIdentifier,
          button: true,
          container: true,
          child: const SmartBackButton(),
        ),
        title: Text(title),
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.only(
          bottom: bottomInset + AppSpacing.base,
        ),
        children: children,
      ),
    );
  }
}
