const Set<String> scalableUnits = {
  // Common English abbreviations and variants
  'g', 'g.', 'gs',
  'gr', 'gr.', 'grs',
  'mg', 'mg.', 'mgs',
  'ml', 'ml.', 'mll',
  'oz', 'oz.', 'ozs',
  'l', 'l.', 'ls',

  // English long forms
  'gram', 'grams',
  'milligram', 'milligrams',
  'milliliter', 'milliliters',
  'ounce', 'ounces',
  'liter', 'liters',

  // French
  'gramme', 'grammes',
  'milligramme', 'milligrammes',
  'millilitre', 'millilitres',
  'once', 'onces',
  'litre', 'litres',

  // Arabic
  'غ', 'غ.', 'جرام', 'جرامات',
  'ملغ', 'ملغ.', 'مليغرام', 'ملليغرام',
  'مل', 'مل.', 'ملليلتر',
  'أونصة',
  'لتر',

  // Spanish
  'gramo', 'gramos',
  'miligramo', 'miligramos',
  'mililitro', 'mililitros',
  'onza', 'onzas',
  'litro', 'litros',

  // Persian
  'گرم', 'گرم.',
  'میلی‌گرم', 'میلی گرم',
  'میلی‌لیتر', 'میلی لیتر',
  'اونس',
  'لیتر',

  // German
  'gramm', 'grammen', 'gramms',
  'milligramm',
  'unze', 'unzen',

  // Indonesian
  'miligram',
  'mililiter',
  'ons',

  // Italian
  'grammo', 'grammi',
  'milligrammo', 'milligrammi',
  'millilitro', 'millilitri',
  'oncia',

  // Japanese
  'グラム',
  'ミリグラム',
  'ミリリットル',
  'オンス',
  'リットル',

  // Korean
  '그램',
  '밀리그램',
  '밀리리터',
  '온스',
  '리터',

  // Greek
  'γρ', 'γρ.',
  'γραμμάριο', 'γραμμάρια',
  'χιλιοστόγραμμο', 'χιλιοστόγραμμα',
  'χιλιοστόλιτρο', 'χιλιοστόλιτρα',
  'ουγγιά', 'ουγγιές',
  'λίτρο', 'λίτρα',

  // Dutch

  // Polish
  'gramy',
  'miligramy', // 'miligram' shared with Indonesian section

  'mililitr', 'mililitry',
  'uncja', 'uncje',
  'litr', 'litry',

  // Portuguese
  'grama', 'gramas',
  'miligrama', 'miligramas',
  'onça', 'onças',

  // Romanian
  'miligrame', // 'miligram' shared with Indonesian section

  'mililitru', 'mililitri',
  'uncie', 'uncii',
  'litru', 'litri',

  // Russian
  'г', 'г.', 'гр', 'гр.',
  'мг', 'мг.',
  'мл', 'мл.',
  'грамм', 'граммы',
  'миллиграмм', 'миллиграммы',
  'миллилитр', 'миллилитры',
  'унция', 'унции',
  'литр', 'литры',

  // Turkish ('miligram' shared with Indonesian section)
  'mililitre',

  // Ukrainian ('мг', 'мг.' shared with Russian section)
  'грам', 'грами',
  'міліграм', 'міліграми',
  'мілілітр', 'мілілітри',
  'унція', 'унції',
  'літр', 'літри',

  // Chinese
  '克',
  '毫克',
  '毫升',
  '盎司',
  '升',
};
