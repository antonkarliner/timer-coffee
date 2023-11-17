import 'package:flutter/material.dart';
import 'package:coffeico/coffeico.dart';

Icon getIconByBrewingMethod(String? brewingMethodId) {
  const Map<String, Icon> icons = {
    "aeropress": Icon(Coffeico.aeropress),
    "chemex": Icon(Coffeico.chemex),
    "clever_dripper": Icon(Coffeico.clever_dripper),
    "french_press": Icon(Coffeico.french_press),
    "hario_v60": Icon(Coffeico.hario_v60),
    "kalita_wave": Icon(Coffeico.kalita_wave),
    "origami": Icon(Coffeico.origami),
    "wilfa_svart": Icon(Coffeico.wilfa_svart),
  };

  return icons[brewingMethodId] ?? const Icon(Icons.error);
}
