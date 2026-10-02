/// Settings grammar v2 (plan 077) — rules for every Settings page and sheet:
///
/// 1. A page is a `SettingsPageScaffold` of `SettingsSection`s, with no bare
///    rows. Root rows only navigate. No `ExpansionTile` anywhere in Settings.
/// 2. A section is an optional header, rows (or one visual-options block) and
///    an optional footer note. Sections sit `AppSpacing.sectionGap` apart, the
///    Hub's rhythm. Head a section only when it holds two or more rows or a
///    non-row block; a one-section page has no header.
/// 3. Every row shares one geometry: 16 pt horizontal padding, the theme's
///    density, title `AppTextStyles.itemTitle`, subtitle `AppTextStyles.caption`
///    in `onSurfaceVariant`. Leading icons only on root category rows, the
///    account card and content icons (brewing methods, sign-in providers).
///    On the root a subtitle summarises state; on pages it says what the
///    setting does, never its value.
/// 4. Exactly one trailing element: a switch (`SettingsSwitchRow`), a value
///    with `Icons.unfold_more` (`SettingsChoiceRow`, `SettingsValueRow`), a
///    chevron (`SettingsNavRow`), or nothing (`SettingsActionRow`). A value
///    takes at most half the row and wraps to two lines; it never goes in
///    `ListTile.trailing`, whose intrinsic width once broke German titles
///    mid-word. The sign-in method rows on the Account page are the one
///    exception: a text action (Change, Link, Unlink) or its progress
///    indicator.
/// 5. The only non-row blocks are visual options, choices whose options are
///    pictures (brewing-screen layout cards, the app-icon grid): equal-width
///    options, label under the picture, a tap selects at once, and the
///    selection shows a 2 pt ring and a check badge.
/// 6. Sheets show a drag handle and an `AppTextStyles.title` heading and use
///    the same rows. A choice inside a sheet is expanded
///    (`SettingsInlineChoice`), never a row that opens a second sheet.
/// 7. Dependent rows sit directly under their parent in an always-present
///    slot. Keep the widget type at a tree position stable and use
///    `SizedBox.shrink()` when it is empty. Changing the returned type
///    recreates the child element, re-runs `initState`, and has caused a
///    blank-field bug here before.
/// 8. Copy: sentence case; descriptions are present-tense fragments without a
///    final period; short value labels; curly ’; one name per setting.
/// 9. Design-system tokens and components only; `showAppTimePicker` for
///    times; dates and times through `DateTimeFormatService`.
/// 10. A new setting joins an existing section. A new root row needs a new
///    category.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/design_tokens.dart';
import '../app_switch_list_tile.dart';
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

/// A Settings section whose headed form is pixel-identical to the Hub's
/// `_HubSection`.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.header,
    required this.children,
    this.footer,
  });

  final String? header;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)
            SettingsSectionHeader(title: header!)
          else
            const SizedBox(height: AppSpacing.sm),
          ...children,
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.base,
                AppSpacing.xs,
                AppSpacing.base,
                0,
              ),
              child: Text(
                footer!,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.titleColor,
  });

  final Widget? leading;
  final Widget title;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.base,
      ),
      leading: leading,
      title: DefaultTextStyle.merge(
        style: AppTextStyles.itemTitle.copyWith(color: titleColor),
        child: title,
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
              child: Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: enabled
                      ? subtitleColor ?? colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
      trailing: trailing,
      onTap: enabled ? onTap : null,
      enabled: enabled,
      selected: selected,
    );
  }
}

/// A Settings row that opens another page or flow.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.identifier,
    this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });

  final String identifier;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      button: true,
      container: true,
      child: _SettingsRow(
        leading: icon == null ? null : Icon(icon, size: AppIconSize.medium),
        title: Text(title),
        subtitle: subtitle,
        subtitleColor: subtitleColor,
        trailing: const Icon(Icons.chevron_right, size: AppIconSize.medium),
        onTap: onTap,
      ),
    );
  }
}

/// A Settings row that displays a value and opens a picker or flow.
class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow({
    super.key,
    required this.identifier,
    required this.title,
    required this.value,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final String identifier;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: identifier,
      button: true,
      container: true,
      child: _SettingsRow(
        title: _TitleValueLayout(
          textDirection: Directionality.of(context),
          title: Text(title),
          value: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.body.copyWith(
              color: enabled ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        subtitle: subtitle,
        trailing: const Icon(Icons.unfold_more, size: AppIconSize.medium),
        onTap: onTap,
        enabled: enabled,
      ),
    );
  }
}

class _TitleValueLayout extends MultiChildRenderObjectWidget {
  _TitleValueLayout({
    required Widget title,
    required Widget value,
    required this.textDirection,
  }) : super(children: [title, value]);

  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTitleValueLayout(
      gap: AppSpacing.base,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTitleValueLayout renderObject,
  ) {
    renderObject.textDirection = textDirection;
  }
}

class _TitleValueParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTitleValueLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitleValueParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TitleValueParentData> {
  _RenderTitleValueLayout({
    required double gap,
    required TextDirection textDirection,
  }) : _gap = gap,
       _textDirection = textDirection;

  final double _gap;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _title => firstChild!;
  RenderBox get _value => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitleValueParentData) {
      child.parentData = _TitleValueParentData();
    }
  }

  BoxConstraints _childConstraints(
    double maxWidth,
    BoxConstraints constraints,
  ) {
    return BoxConstraints(maxWidth: maxWidth, maxHeight: constraints.maxHeight);
  }

  /// Sizes both children (for real, or dry): the value gets at most half the
  /// width, the title the rest.
  ({
    Size size,
    BoxConstraints titleConstraints,
    Size titleSize,
    Size valueSize,
  })
  _measure(BoxConstraints constraints, {required bool dry}) {
    final boundedWidth = constraints.hasBoundedWidth;
    final valueMaxWidth = boundedWidth
        ? math.max(0.0, (constraints.maxWidth - _gap) / 2)
        : double.infinity;
    final valueConstraints = _childConstraints(valueMaxWidth, constraints);
    final valueSize = dry
        ? _value.getDryLayout(valueConstraints)
        : (_value..layout(valueConstraints, parentUsesSize: true)).size;
    final titleMaxWidth = boundedWidth
        ? math.max(0.0, constraints.maxWidth - _gap - valueSize.width)
        : double.infinity;
    final titleConstraints = _childConstraints(titleMaxWidth, constraints);
    final titleSize = dry
        ? _title.getDryLayout(titleConstraints)
        : (_title..layout(titleConstraints, parentUsesSize: true)).size;
    final width = boundedWidth
        ? constraints.maxWidth
        : titleSize.width + _gap + valueSize.width;
    final size = constraints.constrain(
      Size(width, math.max(titleSize.height, valueSize.height)),
    );
    return (
      size: size,
      titleConstraints: titleConstraints,
      titleSize: titleSize,
      valueSize: valueSize,
    );
  }

  @override
  void performLayout() {
    final measured = _measure(constraints, dry: false);
    size = measured.size;
    final titleParentData = _title.parentData! as _TitleValueParentData;
    final valueParentData = _value.parentData! as _TitleValueParentData;
    final titleY = (size.height - measured.titleSize.height) / 2;
    final valueY = (size.height - measured.valueSize.height) / 2;
    if (_textDirection == TextDirection.ltr) {
      titleParentData.offset = Offset(0, titleY);
      valueParentData.offset = Offset(
        size.width - measured.valueSize.width,
        valueY,
      );
    } else {
      titleParentData.offset = Offset(
        size.width - measured.titleSize.width,
        titleY,
      );
      valueParentData.offset = Offset(0, valueY);
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _measure(constraints, dry: true).size;
  }

  // The row's baseline is the title's: ListTile places a title by its
  // baseline when there is a subtitle, so without this a value row with an
  // explanation would sit higher than every other two-line Settings row.
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final titleBaseline = _title.getDistanceToActualBaseline(baseline);
    if (titleBaseline == null) return null;
    final titleParentData = _title.parentData! as _TitleValueParentData;
    return titleBaseline + titleParentData.offset.dy;
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final measured = _measure(constraints, dry: true);
    final titleBaseline = _title.getDryBaseline(
      measured.titleConstraints,
      baseline,
    );
    if (titleBaseline == null) return null;
    return titleBaseline +
        (measured.size.height - measured.titleSize.height) / 2;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _title.getMinIntrinsicWidth(height) +
        _gap +
        _value.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _title.getMaxIntrinsicWidth(height) +
        _gap +
        _value.getMaxIntrinsicWidth(height);
  }

  double _intrinsicHeight(double width, {required bool maximum}) {
    if (!width.isFinite) {
      final titleHeight = maximum
          ? _title.getMaxIntrinsicHeight(double.infinity)
          : _title.getMinIntrinsicHeight(double.infinity);
      final valueHeight = maximum
          ? _value.getMaxIntrinsicHeight(double.infinity)
          : _value.getMinIntrinsicHeight(double.infinity);
      return titleHeight > valueHeight ? titleHeight : valueHeight;
    }

    final valueWidth = ((width - _gap) / 2).clamp(0.0, double.infinity);
    final measuredValueWidth = maximum
        ? _value.getMaxIntrinsicWidth(double.infinity).clamp(0.0, valueWidth)
        : _value.getMinIntrinsicWidth(double.infinity).clamp(0.0, valueWidth);
    final titleWidth = (width - _gap - measuredValueWidth).clamp(
      0.0,
      double.infinity,
    );
    final titleHeight = maximum
        ? _title.getMaxIntrinsicHeight(titleWidth)
        : _title.getMinIntrinsicHeight(titleWidth);
    final valueHeight = maximum
        ? _value.getMaxIntrinsicHeight(valueWidth)
        : _value.getMinIntrinsicHeight(valueWidth);
    return titleHeight > valueHeight ? titleHeight : valueHeight;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _intrinsicHeight(width, maximum: false);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _intrinsicHeight(width, maximum: true);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
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

/// A Settings row that displays and changes one value from a fixed list.
class SettingsChoiceRow<T> extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.identifier,
    required this.title,
    required this.options,
    required this.current,
    required this.onChanged,
    this.sheetTitle,
    this.subtitle,
  });

  final String identifier;
  final String title;
  final List<SettingsChoiceOption<T>> options;
  final T current;
  final ValueChanged<T> onChanged;
  final String? sheetTitle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final currentLabel = options
        .where((option) => option.value == current)
        .firstOrNull
        ?.label;

    return SettingsValueRow(
      identifier: identifier,
      title: title,
      value: currentLabel ?? '',
      subtitle: subtitle,
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
    );
  }
}

/// A Settings row controlled by an app-standard toggle.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.identifier,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final String identifier;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      container: true,
      toggled: value,
      child: _SettingsRow(
        leading: leading,
        title: Text(title),
        subtitle: subtitle,
        trailing: AppToggleSwitch(value: value, onChanged: onChanged),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        enabled: onChanged != null,
      ),
    );
  }
}

/// A Settings row that performs an action without a trailing control.
class SettingsActionRow extends StatelessWidget {
  const SettingsActionRow({
    super.key,
    required this.identifier,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String identifier;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: identifier,
      button: true,
      container: true,
      child: _SettingsRow(
        title: Text(title),
        subtitle: subtitle,
        onTap: enabled ? onTap : null,
        enabled: enabled,
        titleColor: enabled && destructive ? colorScheme.error : null,
      ),
    );
  }
}

/// An expanded list of options for use inside a Settings choice sheet.
class SettingsInlineChoice<T> extends StatelessWidget {
  const SettingsInlineChoice({
    super.key,
    required this.options,
    required this.current,
    required this.onChanged,
  });

  final List<SettingsChoiceOption<T>> options;
  final T current;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        final isCurrent = option.value == current;
        return Semantics(
          identifier: option.identifier,
          selected: isCurrent,
          button: true,
          container: true,
          child: _SettingsRow(
            title: Text(option.label),
            subtitle: option.subtitle,
            selected: isCurrent,
            trailing: isCurrent
                ? Icon(
                    Icons.check,
                    color: colorScheme.primary,
                    size: AppIconSize.medium,
                  )
                : const SizedBox.square(dimension: AppIconSize.medium),
            onTap: () => onChanged(option.value),
          ),
        );
      }).toList(),
    );
  }
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
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
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
                  AppSpacing.xs,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: Text(title, style: AppTextStyles.title),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: SettingsInlineChoice<T>(
                    options: options,
                    current: current,
                    onChanged: (value) => Navigator.of(sheetContext).pop(value),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
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
