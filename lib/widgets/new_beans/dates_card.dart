import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../containers/section_card.dart';
import '../fields/date_field.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';

class DatesCard extends StatefulWidget {
  final DateTime? harvestDate;
  final DateTime? roastDate;
  final ValueChanged<DateTime?> onHarvestDateChanged;
  final ValueChanged<DateTime?> onRoastDateChanged;

  /// The roast date exactly as printed on the scanned label, or null when
  /// unavailable (no scan happened, or the label showed no date at all).
  final String? roastDateRawText;

  /// True when the server flagged the scanned label's roast date as
  /// ambiguous (missing, or no 4-digit year) and the user should confirm it.
  final bool needsConfirmation;

  /// Called when the user taps the confirm action to dismiss the
  /// confirmation hint. Only rendered when this is non-null.
  final VoidCallback? onRoastDateConfirmed;

  const DatesCard({
    super.key,
    required this.harvestDate,
    required this.roastDate,
    required this.onHarvestDateChanged,
    required this.onRoastDateChanged,
    this.roastDateRawText,
    this.needsConfirmation = false,
    this.onRoastDateConfirmed,
  });

  @override
  State<DatesCard> createState() => _DatesCardState();
}

class _DatesCardState extends State<DatesCard> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SectionCard(
      title: loc.importantDates,
      icon: Icons.calendar_today,
      isCollapsible: false,
      semanticIdentifier: 'datesCard',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use side-by-side layout on wider screens
          final isSideBySide = constraints.maxWidth > 600;

          if (isSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildHarvestDateField(context, loc),
                ),
                const SizedBox(width: AppSpacing.fieldGap),
                Expanded(
                  child: _buildRoastDateField(context, loc),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHarvestDateField(context, loc),
                const SizedBox(height: AppSpacing.fieldGap),
                _buildRoastDateField(context, loc),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildHarvestDateField(BuildContext context, AppLocalizations loc) {
    return DateField(
      label: loc.harvestDate,
      initialValue: widget.harvestDate?.toIso8601String(),
      onChanged: (value) {
        final date = value != null ? DateTime.parse(value) : null;
        widget.onHarvestDateChanged(date);
      },
      semanticIdentifier: 'harvestDatePickerButton',
      hintText: loc.selectHarvestDate,
    );
  }

  Widget _buildRoastDateField(BuildContext context, AppLocalizations loc) {
    final dateField = DateField(
      label: loc.roastDate,
      initialValue: widget.roastDate?.toIso8601String(),
      onChanged: (value) {
        final date = value != null ? DateTime.parse(value) : null;
        widget.onRoastDateChanged(date);
      },
      semanticIdentifier: 'roastDatePickerButton',
      hintText: loc.selectRoastDate,
    );

    final hint = _buildRoastDateHint(context, loc);

    // Always return the same widget shape (a Column with a fixed slot for
    // the hint) so the DateField element is never destroyed/recreated just
    // because the hint starts or stops being shown. On a scan, roastDate,
    // roastDateRawText and needsConfirmation all arrive in the same
    // setState — if this method returned a bare DateField in one case and a
    // Column wrapping a DateField in the other, Flutter would see a
    // different widget type at this tree position and remount DateField
    // from scratch (running initState again, this time with a non-null
    // initialValue). Using SizedBox.shrink() as the empty-hint placeholder
    // keeps the visual result identical to the old bare-DateField case: no
    // extra gap, no layout shift.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dateField,
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          hint,
        ] else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget? _buildRoastDateHint(BuildContext context, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final rawText = widget.roastDateRawText;
    final hasRawText = rawText != null && rawText.trim().isNotEmpty;

    if (widget.needsConfirmation) {
      return Semantics(
        identifier: 'roastDateConfirmationHint',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: AppIconSize.small,
              color: colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                hasRawText
                    ? loc.roastDateConfirmPrompt(rawText)
                    : loc.roastDateNotFound,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.primary,
                ),
                softWrap: true,
              ),
            ),
            if (widget.onRoastDateConfirmed != null)
              AppTextButton(
                label: loc.roastDateConfirmAction,
                onPressed: widget.onRoastDateConfirmed,
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: AppButton.paddingSmall,
              ),
          ],
        ),
      );
    }

    if (hasRawText) {
      return Text(
        loc.roastDateFromLabel(rawText),
        style: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        softWrap: true,
      );
    }

    return null;
  }
}
