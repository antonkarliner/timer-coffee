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
    "switch": Icon(Coffeico.hario_switch),
    "melitacone": Icon(Coffeico.melita_cone),
    "beehousedripper": Icon(Coffeico.bee_house_dripper),
    "phinfilter": Icon(Coffeico.phin_filter),
    "neapolitanflippot": Icon(Coffeico.neapolitan_flip_pot),
    "mokapot": Icon(Coffeico.moka_pot),
    "siphonbrewer": Icon(Coffeico.siphon_brewer),
    "cezve": Icon(Coffeico.cezve),
    "tricolate": Icon(Coffeico.tricolate),
    "pulsar": Icon(Coffeico.pulsar),
    "ufodripper": Icon(Coffeico.ufo_dripper),
    "oreabrewer": Icon(Coffeico.orea_brewer),
    "aprilbrewer": Icon(Coffeico.april_brewer),
    "ceadohoopbrewer": Icon(Coffeico.ceado_hoop_brewer),
    "oxorapidbrewer": Icon(Coffeico.oxo_rapid_brewer),
  };

  return icons[brewingMethodId] ?? const Icon(Coffeico.bean);
}
