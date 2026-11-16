import '../l10n/app_localizations.dart';

/// Coffee processing labels for the stock feed's vocabulary. Unknown values
/// remain absent rather than exposing server identifiers to the user.
String? stockProcessLabel(AppLocalizations l10n, String? value) =>
    switch (value) {
      'washed' => l10n.stockProcessWashed,
      'natural' => l10n.stockProcessNatural,
      'honey' => l10n.stockProcessHoney,
      'experimental' => l10n.stockProcessExperimental,
      'wet_hulled' => l10n.stockProcessWetHulled,
      _ => null,
    };

/// Flavour labels shared with the flavour wheel where the meanings match.
String? stockFlavorLabel(AppLocalizations l10n, String? value) =>
    switch (value) {
      'fruity' => l10n.flavorCatFruity,
      'berry' => l10n.flavorSubBerry,
      'citrus' => l10n.flavorSubCitrus,
      'tropical' => l10n.flavorSubTropical,
      'floral' => l10n.flavorCatFloral,
      'nutty' => l10n.flavorSubNutty,
      'spice' => l10n.flavorCatSpices,
      'caramel_sweet' => l10n.flavorSubCaramel,
      'chocolate' => l10n.stockFlavorChocolate,
      'stone_fruit' => l10n.stockFlavorStoneFruit,
      'tea_like' => l10n.stockFlavorTeaLike,
      'winey_fermented' => l10n.stockFlavorWiney,
      'earthy' => l10n.stockFlavorEarthy,
      _ => null,
    };
