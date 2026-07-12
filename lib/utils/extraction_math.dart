/// Pure Dart math for the brew (extraction) calculator.
///
/// No Flutter imports — this file is safe to use from tests or any other
/// non-UI context.
library;

/// Lower bound (%) of the "target" extraction yield band.
const double extractionYieldTargetMin = 18.0;

/// Upper bound (%) of the "target" extraction yield band.
const double extractionYieldTargetMax = 22.0;

/// Lower bound (%) of the "ideal" TDS strength band (filter coffee).
const double tdsStrengthIdealMin = 1.15;

/// Upper bound (%) of the "ideal" TDS strength band (filter coffee).
const double tdsStrengthIdealMax = 1.45;

/// Grams of water grounds retain per gram of dry coffee dosed, used to
/// estimate beverage weight from water poured.
const double groundsRetentionFactor = 2.0;

/// The two brewing modes the calculator supports.
enum BrewMode { filter, espresso }

/// Where an extraction yield percentage falls relative to the target band
/// (18–22%).
enum ExtractionBand { under, target, over }

/// Where a TDS percentage falls relative to the ideal strength band
/// (1.15–1.45%, filter coffee).
enum TdsStrengthBand { weak, ideal, strong }

/// Extraction yield (%) = beverage weight (g) x TDS (%) / dose (g).
///
/// Returns null when any input is missing or non-positive — the calculator
/// should show a neutral empty state rather than an error in that case.
double? extractionYield({
  required double? dose,
  required double? beverage,
  required double? tdsPercent,
}) {
  if (dose == null || beverage == null || tdsPercent == null) return null;
  if (dose <= 0 || beverage <= 0 || tdsPercent <= 0) return null;
  return beverage * tdsPercent / dose;
}

/// Estimates beverage weight from water poured, accounting for the water
/// grounds retain (~[groundsRetentionFactor] g per g of dose). Clamped at 0.
double estimatedBeverage({required double water, required double dose}) {
  final estimate = water - groundsRetentionFactor * dose;
  return estimate < 0 ? 0 : estimate;
}

/// Classifies an extraction yield percentage into under/target/over,
/// inclusive of the [extractionYieldTargetMin]/[extractionYieldTargetMax]
/// boundaries (i.e. exactly 18.0 or 22.0 is "target").
ExtractionBand classifyExtractionYield(double eyPercent) {
  if (eyPercent < extractionYieldTargetMin) return ExtractionBand.under;
  if (eyPercent > extractionYieldTargetMax) return ExtractionBand.over;
  return ExtractionBand.target;
}

/// Classifies a TDS percentage into weak/ideal/strong, inclusive of the
/// [tdsStrengthIdealMin]/[tdsStrengthIdealMax] boundaries.
TdsStrengthBand classifyTdsStrength(double tdsPercent) {
  if (tdsPercent < tdsStrengthIdealMin) return TdsStrengthBand.weak;
  if (tdsPercent > tdsStrengthIdealMax) return TdsStrengthBand.strong;
  return TdsStrengthBand.ideal;
}
