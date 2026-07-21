import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/user_stat_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../services/date_time_format_service.dart';
import '../theme/design_tokens.dart';
import '../utils/extraction_math.dart' as calc;
import '../utils/icon_utils.dart';
import '../widgets/base_buttons.dart';
import '../widgets/containers/sticky_action_bar.dart';
import '../widgets/extraction_calculator/learn_sections.dart';
import '../widgets/fields/numeric_text_field.dart';
import '../widgets/smart_back_button.dart';

@immutable
class ExtractionCalculatorResult {
  const ExtractionCalculatorResult({
    required this.tdsPercent,
    required this.extractionYieldPercent,
  });

  final double tdsPercent;
  final double extractionYieldPercent;
}

@RoutePage()
class ExtractionCalculatorScreen extends StatefulWidget {
  final String? statUuid;

  const ExtractionCalculatorScreen({
    super.key,
    @QueryParam('statUuid') this.statUuid,
  });

  @override
  State<ExtractionCalculatorScreen> createState() =>
      _ExtractionCalculatorScreenState();
}

class _ExtractionCalculatorScreenState
    extends State<ExtractionCalculatorScreen> {
  calc.BrewMode _mode = calc.BrewMode.filter;

  double? _dose;
  double? _beverage;
  double? _shotWeight;
  double? _tds;
  double? _water;

  bool _tdsLearnExpanded = false;
  final GlobalKey _tdsLearnKey = GlobalKey();

  // Bumped whenever a field is prefilled programmatically (via the
  // "estimate" button, or from a history pick / route arg) so the field
  // remounts instead of updating in place. NumericTextField only applies a
  // changed initialValue safely on mount (initState) — updating it via
  // didUpdateWidget re-triggers onChanged synchronously, which would call
  // setState mid-build.
  int _doseFieldGeneration = 0;
  int _beverageFieldGeneration = 0;
  int _waterFieldGeneration = 0;
  int _shotFieldGeneration = 0;
  int _tdsFieldGeneration = 0;

  // The logged brew (if any) the current inputs were prefilled from. Kept
  // for a later phase (pushing straight from the brew diary); for now it
  // only drives the "prefilled from history" badge.
  String? _attachedStatUuid;
  String? _attachedRecipeName;

  double? get _outputWeight =>
      _mode == calc.BrewMode.filter ? _beverage : _shotWeight;

  @override
  void initState() {
    super.initState();
    final initialStatUuid = widget.statUuid;
    if (initialStatUuid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStatForPrefill(initialStatUuid);
      });
    }
  }

  Future<void> _loadStatForPrefill(String statUuid) async {
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );
    final stat = await userStatProvider.fetchUserStatByUuid(statUuid);
    if (stat == null || !mounted) return;

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipeName = await recipeProvider.getLocalizedRecipeName(
      stat.recipeId,
    );
    if (!mounted) return;

    _applyStatPrefill(stat, recipeName: recipeName);
  }

  void _applyStatPrefill(UserStatsModel stat, {required String recipeName}) {
    setState(() {
      _attachedStatUuid = stat.statUuid;
      _attachedRecipeName = recipeName;
      _mode = stat.brewingMethodId == 'espresso'
          ? calc.BrewMode.espresso
          : calc.BrewMode.filter;
      _dose = stat.coffeeAmount;
      _doseFieldGeneration++;
      if (_mode == calc.BrewMode.filter) {
        _water = stat.waterAmount;
        _waterFieldGeneration++;
        _beverage = calc.estimatedBeverage(water: _water!, dose: _dose!);
        _beverageFieldGeneration++;
      } else {
        // For espresso recipes waterAmount is the target beverage weight,
        // so it maps directly onto the shot field.
        _shotWeight = stat.waterAmount;
        _shotFieldGeneration++;
      }
      if (stat.tdsPercent != null) {
        _tds = stat.tdsPercent;
        _tdsFieldGeneration++;
      }
    });
  }

  void _detachStat() {
    setState(() {
      _attachedStatUuid = null;
      _attachedRecipeName = null;
    });
  }

  Future<void> _openHistoryPicker() async {
    final picked = await showDialog<({UserStatsModel stat, String recipeName})>(
      context: context,
      builder: (dialogContext) => const _HistoryPickerDialog(),
    );
    if (picked == null || !mounted) return;
    _applyStatPrefill(picked.stat, recipeName: picked.recipeName);
  }

  void _applyEstimatedBeverage() {
    if (_water == null || _dose == null) return;
    setState(() {
      _beverage = calc.estimatedBeverage(water: _water!, dose: _dose!);
      _beverageFieldGeneration++;
    });
  }

  Future<void> _saveResultToStat(double eyValue) async {
    final statUuid = _attachedStatUuid;
    final tdsValue = _tds;
    if (statUuid == null || tdsValue == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final successMessage = AppLocalizations.of(
      context,
    )!.extractionCalcSaveSuccess;
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );

    await userStatProvider.updateUserStat(
      statUuid: statUuid,
      tdsPercent: tdsValue,
      extractionYieldPercent: eyValue,
    );

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(successMessage)));
    if (widget.statUuid != null) {
      await context.router.maybePop(
        ExtractionCalculatorResult(
          tdsPercent: tdsValue,
          extractionYieldPercent: eyValue,
        ),
      );
    }
  }

  void _expandTdsLearnSection() {
    setState(() => _tdsLearnExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tdsLearnKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final ey = calc.extractionYield(
      dose: _dose,
      beverage: _outputWeight,
      tdsPercent: _tds,
    );
    final canSave = _attachedStatUuid != null && ey != null;

    return Scaffold(
      bottomNavigationBar: canSave
          ? KeyboardAwareStickyActionBar(
              child: StickyActionBar(
                primaryLabel: l10n.extractionCalcSaveButton,
                semanticIdentifier: 'extractionCalcSaveBar',
                onPrimaryPressed: () => _saveResultToStat(ey),
              ),
            )
          : null,
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calculate_outlined),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.extractionCalcTitle),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                identifier: _attachedStatUuid == null
                    ? 'extractionCalcHistoryEntry'
                    : 'extractionCalcHistoryEntry_$_attachedStatUuid',
                child: _HistoryEntryPoint(
                  attachedRecipeName: _attachedRecipeName,
                  onPick: _openHistoryPicker,
                  onDetach: _detachStat,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ModeSwitch(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: AppSpacing.lg),
              NumericTextField(
                key: ValueKey('extractionCalcDoseField-$_doseFieldGeneration'),
                label: l10n.extractionCalcDoseLabel,
                allowDecimal: true,
                initialValue: _dose,
                onChanged: (v) => setState(() => _dose = v),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              if (_mode == calc.BrewMode.filter) ...[
                NumericTextField(
                  key: ValueKey(
                    'extractionCalcBeverageField-$_beverageFieldGeneration',
                  ),
                  label: l10n.extractionCalcBeverageLabel,
                  allowDecimal: true,
                  initialValue: _beverage,
                  onChanged: (v) => setState(() => _beverage = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                _BeverageEstimateHelper(
                  water: _water,
                  waterFieldGeneration: _waterFieldGeneration,
                  canEstimate: _water != null && _dose != null,
                  onWaterChanged: (v) => setState(() => _water = v),
                  onEstimate: _applyEstimatedBeverage,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
              ] else ...[
                NumericTextField(
                  key: ValueKey(
                    'extractionCalcShotField-$_shotFieldGeneration',
                  ),
                  label: l10n.extractionCalcShotLabel,
                  allowDecimal: true,
                  initialValue: _shotWeight,
                  onChanged: (v) => setState(() => _shotWeight = v),
                ),
                const SizedBox(height: AppSpacing.fieldGap),
              ],
              NumericTextField(
                key: ValueKey('extractionCalcTdsField-$_tdsFieldGeneration'),
                label: l10n.extractionCalcTdsLabel,
                allowDecimal: true,
                maxDecimalPlaces: 2,
                initialValue: _tds,
                onChanged: (v) => setState(() => _tds = v),
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: _expandTdsLearnSection,
                child: Text(
                  l10n.extractionCalcTdsCaption,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ResultBlock(mode: _mode, ey: ey, tds: _tds),
              const SizedBox(height: AppSpacing.lg),
              ExtractionCalculatorLearnSections(
                mode: _mode,
                tdsSectionKey: _tdsLearnKey,
                tdsInitiallyExpanded: _tdsLearnExpanded,
                onTdsExpansionChanged: (v) {
                  setState(() => _tdsLearnExpanded = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width Filter/Espresso segmented control, styled after the app's
/// existing [AnimatedToggleSwitch] usage in AppSwitchListTile.
class _ModeSwitch extends StatelessWidget {
  final calc.BrewMode mode;
  final ValueChanged<calc.BrewMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  String _label(AppLocalizations l10n, calc.BrewMode value) {
    return value == calc.BrewMode.filter
        ? l10n.extractionCalcModeFilter
        : l10n.extractionCalcModeEspresso;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 2;
        return AnimatedToggleSwitch<calc.BrewMode>.rolling(
          current: mode,
          values: const [calc.BrewMode.filter, calc.BrewMode.espresso],
          onChanged: onChanged,
          height: 44,
          borderWidth: 1.5,
          indicatorSize: Size.fromWidth(itemWidth),
          style: ToggleStyle(
            backgroundColor: colorScheme.surfaceContainerHighest,
            borderColor: colorScheme.outline,
            indicatorColor: colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.field),
            indicatorBorderRadius: BorderRadius.circular(AppRadius.small),
          ),
          iconBuilder: (value, foreground) => Center(
            child: Text(
              _label(l10n, value),
              style: AppTextStyles.fieldLabel.copyWith(
                color: foreground
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Filter-mode convenience: enter water weight to prefill the beverage
/// weight field. Purely a prefill — the beverage field stays editable.
class _BeverageEstimateHelper extends StatelessWidget {
  final double? water;
  final int waterFieldGeneration;
  final bool canEstimate;
  final ValueChanged<double?> onWaterChanged;
  final VoidCallback onEstimate;

  const _BeverageEstimateHelper({
    required this.water,
    required this.waterFieldGeneration,
    required this.canEstimate,
    required this.onWaterChanged,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NumericTextField(
                key: ValueKey('extractionCalcWaterField-$waterFieldGeneration'),
                label: l10n.extractionCalcWaterLabel,
                allowDecimal: true,
                initialValue: water,
                onChanged: onWaterChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AppTextButton(
                label: l10n.extractionCalcEstimateButton,
                isFullWidth: false,
                onPressed: canEstimate ? onEstimate : null,
              ),
            ),
          ],
        ),
        Text(
          l10n.extractionCalcEstimateHelperText,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Large extraction-yield result with a horizontal band indicator and,
/// in filter mode, a derived strength line.
class _ResultBlock extends StatelessWidget {
  final calc.BrewMode mode;
  final double? ey;
  final double? tds;

  const _ResultBlock({required this.mode, required this.ey, required this.tds});

  Color _bandColor(ColorScheme colorScheme, calc.ExtractionBand band) {
    switch (band) {
      case calc.ExtractionBand.under:
        return Colors.orange;
      case calc.ExtractionBand.target:
        return colorScheme.primary;
      case calc.ExtractionBand.over:
        return colorScheme.error;
    }
  }

  String _bandLabel(AppLocalizations l10n, calc.ExtractionBand band) {
    switch (band) {
      case calc.ExtractionBand.under:
        return l10n.extractionCalcBandUnder;
      case calc.ExtractionBand.target:
        return l10n.extractionCalcBandTarget;
      case calc.ExtractionBand.over:
        return l10n.extractionCalcBandOver;
    }
  }

  String _strengthLabel(AppLocalizations l10n, calc.TdsStrengthBand band) {
    switch (band) {
      case calc.TdsStrengthBand.weak:
        return l10n.extractionCalcStrengthWeak;
      case calc.TdsStrengthBand.ideal:
        return l10n.extractionCalcStrengthIdeal;
      case calc.TdsStrengthBand.strong:
        return l10n.extractionCalcStrengthStrong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (ey == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Text(
          l10n.extractionCalcResultPlaceholder,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final band = calc.classifyExtractionYield(ey!);
    final bandColor = _bandColor(colorScheme, band);
    final strengthBand = tds != null ? calc.classifyTdsStrength(tds!) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.extractionCalcResultLabel,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${ey!.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: bandColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _bandLabel(l10n, band),
            style: AppTextStyles.fieldLabel.copyWith(color: bandColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          _BandIndicator(band: band, colorScheme: colorScheme),
          if (mode == calc.BrewMode.filter && strengthBand != null) ...[
            const SizedBox(height: AppSpacing.base),
            Text(
              l10n.extractionCalcStrengthLine(
                _strengthLabel(l10n, strengthBand),
              ),
              style: AppTextStyles.body,
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple three-segment horizontal band indicator: under / target / over.
class _BandIndicator extends StatelessWidget {
  final calc.ExtractionBand band;
  final ColorScheme colorScheme;

  const _BandIndicator({required this.band, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    const height = 6.0;
    final segmentColors = {
      calc.ExtractionBand.under: Colors.orange,
      calc.ExtractionBand.target: colorScheme.primary,
      calc.ExtractionBand.over: colorScheme.error,
    };

    Widget segment(calc.ExtractionBand segmentBand) {
      final isActive = segmentBand == band;
      final color = segmentColors[segmentBand]!;
      return Expanded(
        child: Container(
          height: isActive ? height + 2 : height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      );
    }

    return Row(
      children: [
        segment(calc.ExtractionBand.under),
        segment(calc.ExtractionBand.target),
        segment(calc.ExtractionBand.over),
      ],
    );
  }
}

/// "From your history" entry point shown above the calculator inputs.
/// Renders as a plain button until a brew has been picked, then switches to
/// a badge naming the attached recipe with a "Change" action to re-pick.
class _HistoryEntryPoint extends StatelessWidget {
  final String? attachedRecipeName;
  final VoidCallback onPick;
  final VoidCallback onDetach;

  const _HistoryEntryPoint({
    required this.attachedRecipeName,
    required this.onPick,
    required this.onDetach,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final recipeName = attachedRecipeName;

    if (recipeName == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: AppTextButton(
          label: l10n.extractionCalcHistoryButton,
          icon: Icons.history,
          isFullWidth: false,
          onPressed: onPick,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: AppIconSize.small,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.extractionCalcHistoryPrefilledBadge(recipeName),
              style: AppTextStyles.body,
            ),
          ),
          AppTextButton(
            label: l10n.extractionCalcHistoryChangeButton,
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
            onPressed: onPick,
          ),
          Semantics(
            identifier: 'extractionCalcDetachButton',
            label: l10n.extractionCalcDetachTooltip,
            child: IconButton(
              icon: const Icon(Icons.close),
              iconSize: AppIconSize.small,
              tooltip: l10n.extractionCalcDetachTooltip,
              onPressed: onDetach,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog listing recent logged brews to prefill the calculator from.
/// Pops with the selected stat plus its already-resolved recipe name (so
/// the caller doesn't need to look it up again).
class _HistoryPickerDialog extends StatelessWidget {
  const _HistoryPickerDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Semantics(
                identifier: 'extractionCalcHistoryDialogAppBar',
                label: l10n.extractionCalcHistoryDialogTitle,
                child: Text(l10n.extractionCalcHistoryDialogTitle),
              ),
              automaticallyImplyLeading: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<UserStatsModel>>(
                future: userStatProvider.fetchRecentStats(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data!;
                  if (stats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          l10n.extractionCalcHistoryEmptyHint,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, index) =>
                        _HistoryPickerRow(stat: stats[index]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTextButton(
                    label: l10n.cancel,
                    isFullWidth: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable row in [_HistoryPickerDialog]: brewing-method icon,
/// bold recipe name, an optional bean-name line, and a date + dose/water
/// summary line. Dose/water values are joined to their unit with a
/// no-break space so "g" never wraps onto its own line.
class _HistoryPickerRow extends StatelessWidget {
  final UserStatsModel stat;

  const _HistoryPickerRow({required this.stat});

  String _formatAmount(double value) {
    return value == value.truncate()
        ? value.truncate().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final fmtSvc = Provider.of<DateTimeFormatService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat(
      fmtSvc.datePattern(l10n.dateFormat),
      Localizations.localeOf(context).toString(),
    ).format(stat.createdAt.toLocal());
    // Non-breaking space (\u00A0) between each value and its unit so the
    // unit never wraps onto its own line; ' · ' separators may still wrap.
    const nbsp = '\u00A0';
    final metaLine =
        '$dateStr · '
        '${_formatAmount(stat.coffeeAmount)}$nbsp${l10n.unitGramsShort} · '
        '${_formatAmount(stat.waterAmount)}$nbsp${l10n.unitGramsShort}';
    final beanName = stat.beans;
    final hasBeanName = beanName != null && beanName.trim().isNotEmpty;

    return FutureBuilder<List<String>>(
      future: Future.wait([
        recipeProvider.getBrewingMethodName(stat.brewingMethodId),
        recipeProvider.getLocalizedRecipeName(stat.recipeId),
      ]),
      builder: (context, snapshot) {
        final methodName = snapshot.data?[0];
        final recipeName = snapshot.data?[1];
        final title = recipeName ?? methodName ?? '';

        return ListTile(
          leading: getIconByBrewingMethod(stat.brewingMethodId),
          title: Text(
            title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasBeanName)
                Text(
                  beanName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body,
                ),
              Text(
                metaLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onTap: snapshot.hasData
              ? () => Navigator.of(
                  context,
                ).pop((stat: stat, recipeName: recipeName ?? methodName ?? ''))
              : null,
        );
      },
    );
  }
}
