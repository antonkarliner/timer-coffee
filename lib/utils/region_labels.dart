import 'package:coffee_timer/l10n/app_localizations.dart';

/// Standardized region codes coming from backend:
/// EU, NA, AS, AU, WW, AF, ME, SA
String localizeRegion(String code, AppLocalizations l10n) {
  final c = code.trim().toUpperCase();
  switch (c) {
    case 'EU':
    case 'EUROPE':
      return l10n.regionEurope;
    case 'NA':
    case 'NORTH AMERICA':
      return l10n.regionNorthAmerica;
    case 'AS':
    case 'ASIA':
      return l10n.regionAsia;
    case 'AU':
    case 'OCEANIA':
    case 'AUSTRALIA':
      return l10n.regionAustralia;
    case 'AF':
    case 'AFRICA':
      return l10n.regionAfrica;
    case 'ME':
    case 'MIDDLE EAST':
      return l10n.regionMiddleEast;
    case 'SA':
    case 'SOUTH AMERICA':
      return l10n.regionSouthAmerica;
    case 'WW':
    case 'WORLDWIDE':
      return l10n.regionWorldwide;
    default:
      return code; // fallback to raw value
  }
}
