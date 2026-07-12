import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import '../../utils/extraction_math.dart';
import '../containers/section_card.dart';

/// The four collapsible "Learn" explainer sections shown at the bottom of
/// the brew calculator screen. The fourth (beverage weight estimate) only
/// applies to filter mode.
class ExtractionCalculatorLearnSections extends StatelessWidget {
  final BrewMode mode;
  final GlobalKey tdsSectionKey;
  final bool tdsInitiallyExpanded;
  final ValueChanged<bool> onTdsExpansionChanged;

  const ExtractionCalculatorLearnSections({
    super.key,
    required this.mode,
    required this.tdsSectionKey,
    required this.tdsInitiallyExpanded,
    required this.onTdsExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: l10n.extractionCalcLearnWhatIsEyTitle,
          icon: Icons.info_outline,
          semanticIdentifier: 'extractionCalcLearnWhatIsEy',
          child: Text(
            l10n.extractionCalcLearnWhatIsEyBody,
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SectionCard(
          key: tdsSectionKey,
          title: l10n.extractionCalcLearnTdsTitle,
          icon: Icons.science_outlined,
          initiallyExpanded: tdsInitiallyExpanded,
          onExpansionChanged: onTdsExpansionChanged,
          semanticIdentifier: 'extractionCalcLearnTds',
          child: Text(
            l10n.extractionCalcLearnTdsBody,
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SectionCard(
          title: l10n.extractionCalcLearnStrengthVsExtractionTitle,
          icon: Icons.compare_arrows_outlined,
          semanticIdentifier: 'extractionCalcLearnStrengthVsExtraction',
          child: Text(
            l10n.extractionCalcLearnStrengthVsExtractionBody,
            style: AppTextStyles.body,
          ),
        ),
        if (mode == BrewMode.filter) ...[
          const SizedBox(height: AppSpacing.sm),
          SectionCard(
            title: l10n.extractionCalcLearnBeverageEstimateTitle,
            icon: Icons.scale_outlined,
            semanticIdentifier: 'extractionCalcLearnBeverageEstimate',
            child: Text(
              l10n.extractionCalcLearnBeverageEstimateBody,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ],
    );
  }
}
