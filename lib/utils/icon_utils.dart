import 'package:flutter/material.dart';
import 'package:coffeico/coffeico.dart';

Icon getIconByBrewingMethod(String? brewingMethodId) {
  const Map<String, Icon> icons = {
    "aeropress": Icon(Coffeico.aeropress),
    "chemex": Icon(Coffeico.chemex),
    "clever": Icon(Coffeico.clever_dripper),
    "frenchpress": Icon(Coffeico.french_press),
    "v60": Icon(Coffeico.hario_v60),
    "kalita": Icon(Coffeico.kalita_wave),
    "origami": Icon(Coffeico.origami),
    "wilfa": Icon(Coffeico.wilfa_svart),
    "espresso": Icon(Coffeico.portafilter),
    "batchbrew": Icon(Coffeico.coffee_maker),
    "switch": Icon(Coffeico.hario_switch)
  };

  return icons[brewingMethodId] ?? const Icon(Coffeico.bean);
}
