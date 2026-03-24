import 'package:flutter/material.dart';
import 'package:l10n_countries/l10n_countries.dart';

/// Returns the localized display name for a given ISO 3166-1 alpha-2 country
/// code (e.g. "FR") in the given [locale]. Falls back to English if the
/// locale has no translation. Returns null for unknown/null codes.
String? localizedCountryName(String? alpha2, Locale locale) {
  if (alpha2 == null || alpha2.isEmpty) return null;
  final alpha3 = _alpha2ToAlpha3[alpha2.toUpperCase()];
  if (alpha3 == null) return null;
  final mapper = CountriesLocaleMapper();
  final result = mapper.localize(
    {alpha3},
    mainLocale: locale.toLanguageTag(),
    fallbackLocale: 'en',
  );
  return result.values.firstOrNull;
}

/// Returns the locale-specific country fragment required after a "from"
/// preposition in the given locale (e.g. Russian genitive "из Франции",
/// Greek "την Ελλάδα", Turkish "Türkiye'den").
///
/// Falls back to [localizedCountryName] (nominative) for languages that don't
/// inflect country names or for unknown country codes.
///
/// Languages with curated "from-country" forms: ru, uk, pl, hr, fi, el, tr.
/// German keeps the nominative for most countries and only overrides the small
/// set that require a mandatory article after "aus".
String? localizedCountryNameGenitive(String? alpha2, Locale locale) {
  if (alpha2 == null || alpha2.isEmpty) return null;
  final code = alpha2.toUpperCase();
  switch (locale.languageCode) {
    case 'ru':
      return _ruGenitiveNames[code] ?? localizedCountryName(code, locale);
    case 'uk':
      return _ukGenitiveNames[code] ?? localizedCountryName(code, locale);
    case 'pl':
      return _plGenitiveNames[code] ?? localizedCountryName(code, locale);
    case 'hr':
      return _hrGenitiveNames[code] ?? localizedCountryName(code, locale);
    case 'fi':
      return _fiFromNames[code] ?? localizedCountryName(code, locale);
    case 'el':
      return _elFromNames[code] ?? localizedCountryName(code, locale);
    case 'tr':
      return _trFromNames[code] ?? localizedCountryName(code, locale);
    case 'de':
      return _deFromNames[code] ?? localizedCountryName(code, locale);
  }
  return localizedCountryName(alpha2, locale);
}

Map<String, String> _buildCountryFormMap({
  required Locale locale,
  required String Function(String code, String nominative) builder,
}) {
  final mapper = CountriesLocaleMapper();
  final localized = mapper.localize(
    _alpha2ToAlpha3.values.toSet(),
    mainLocale: locale.toLanguageTag(),
    fallbackLocale: 'en',
  );
  final namesByIso = <String, String>{};
  for (final entry in localized.entries) {
    namesByIso.putIfAbsent(entry.key.isoCode, () => entry.value);
  }

  final result = <String, String>{};
  for (final entry in _alpha2ToAlpha3.entries) {
    final nominative = namesByIso[entry.value];
    if (nominative != null) {
      result[entry.key] = builder(entry.key, nominative);
    }
  }
  return result;
}

final Map<String, String> _fiFromNames = _buildCountryFormMap(
  locale: const Locale('fi'),
  builder: _buildFinnishFromName,
);

final Map<String, String> _elFromNames = _buildCountryFormMap(
  locale: const Locale('el'),
  builder: _buildGreekFromName,
);

final Map<String, String> _trFromNames = _buildCountryFormMap(
  locale: const Locale('tr'),
  builder: _buildTurkishFromName,
);

const Map<String, String> _deFromNames = {
  'CH': 'der Schweiz',
  'NL': 'den Niederlanden',
  'TR': 'der Türkei',
  'US': 'den USA',
};

const Map<String, String> _fiFromOverrides = {
  'AE': 'Arabiemiraateista',
  'AX': 'Ahvenanmaalta',
  'BS': 'Bahamasaarista',
  'CC': 'Kookossaarista',
  'CK': 'Cookinsaarista',
  'FI': 'Suomesta',
  'FK': 'Falkandinsaarista',
  'FO': 'Färsaarista',
  'GB': 'Yhdistyneestä kuningaskunnasta',
  'GR': 'Kreikasta',
  'GS': 'Etelä-Georgiasta ja Eteläisistä Sandwichsaarista',
  'HM': 'Heard- ja McDonaldinsaarista',
  'KM': 'Komoreista',
  'MH': 'Marshallinsaarista',
  'MP': 'Pohjois-Mariaaneista',
  'NL': 'Alankomaista',
  'PH': 'Filippiineistä',
  'SC': 'Seychelleistä',
  'SB': 'Salomonsaarista',
  'SE': 'Ruotsista',
  'SJ': 'Huippuvuorista',
  'TC': 'Turks- ja Caicossaarista',
  'TF': 'Ranskan eteläisistä ja antarktisista alueista',
  'TR': 'Turkista',
  'UM': 'Yhdysvaltain asumattomista saarista',
  'US': 'Yhdysvalloista',
  'VC': 'Saint Vincentistä ja Grenadiineista',
  'VG': 'Neitsytsaarista',
  'VI': 'Neitsytsaarista',
};

const Map<String, String> _elFromOverrides = {
  'AE': 'τα Ηνωμένα Αραβικά Εμιράτα',
  'BL': 'τον Άγιο Βαρθολομαίο',
  'MF': 'τον Άγιο Μαρτίνο (Γαλλικό τμήμα)',
  'SM': 'τον Άγιο Μαρίνο',
  'SX': 'τον Άγιο Μαρτίνο (Ολλανδικό τμήμα)',
  'US': 'τις Ηνωμένες Πολιτείες',
  'VC': 'τον Άγιο Βικέντιο και τις Γρεναδίνες',
};

const Set<String> _elMasculineCodes = {
  'CA',
  'LB',
  'MU',
  'PA',
};

const Set<String> _elFeminineOsCodes = {
  'CY',
  'EG',
};

const Set<String> _elNeuterOsCodes = {
  'BB',
  'LA',
};

const Set<String> _elPluralFeminineCodes = {
  'BS',
  'KM',
  'MV',
  'PH',
  'SC',
  'VG',
  'VI',
};

String _buildFinnishFromName(String code, String nominative) {
  final override = _fiFromOverrides[code];
  if (override != null) return override;

  final suffix = _finnishStaSuffix(nominative);
  if (nominative.endsWith('kki')) {
    return '${nominative.substring(0, nominative.length - 3)}ki$suffix';
  }
  if (nominative.endsWith('kka')) {
    return '${nominative.substring(0, nominative.length - 3)}ka$suffix';
  }
  if (nominative.endsWith('kko')) {
    return '${nominative.substring(0, nominative.length - 3)}ko$suffix';
  }
  if (_fiOldIStemCodes.contains(code) && nominative.endsWith('i')) {
    return '${nominative.substring(0, nominative.length - 1)}e$suffix';
  }
  return '$nominative$suffix';
}

String _finnishStaSuffix(String value) {
  return _usesFinnishFrontHarmony(value) ? 'stä' : 'sta';
}

bool _usesFinnishFrontHarmony(String value) {
  var sawBack = false;
  var sawFront = false;

  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (_fiBackVowels.contains(char)) sawBack = true;
    if (_fiFrontVowels.contains(char)) sawFront = true;
  }

  return sawFront && !sawBack;
}

const Set<String> _fiOldIStemCodes = {
  'CH',
  'FI',
  'SE',
};

const Set<String> _fiBackVowels = {
  'a',
  'o',
  'u',
};

const Set<String> _fiFrontVowels = {
  'y',
  'ä',
  'ö',
};

String _buildGreekFromName(String code, String nominative) {
  final override = _elFromOverrides[code];
  if (override != null) return override;

  if (_elPluralFeminineCodes.contains(code)) {
    return 'τις $nominative';
  }
  if (nominative.startsWith('Νήσοι ')) {
    return 'τις ${nominative.replaceFirst('Νήσοι ', 'Νήσους ')}';
  }
  if (nominative.endsWith(' Νήσοι')) {
    return 'τις ${nominative.replaceFirst(' Νήσοι', ' Νήσους')}';
  }
  if (nominative.startsWith('Ηνωμένα ')) {
    return 'τα $nominative';
  }
  if (_elFeminineOsCodes.contains(code)) {
    return 'την ${_toGreekFeminineAccusative(nominative)}';
  }
  if (_elNeuterOsCodes.contains(code) ||
      nominative.startsWith('Ηνωμένο ') ||
      _looksGreekNeuter(nominative)) {
    return 'το $nominative';
  }
  if (_elMasculineCodes.contains(code) || _looksGreekMasculine(nominative)) {
    return 'τον ${_toGreekMasculineAccusative(nominative)}';
  }
  if (_looksGreekFeminine(nominative)) {
    return 'την ${_toGreekFeminineAccusative(nominative)}';
  }

  return 'το $nominative';
}

bool _looksGreekFeminine(String value) {
  return value.endsWith('ία') ||
      value.endsWith('η') ||
      value.endsWith('α') ||
      value.endsWith('ά');
}

bool _looksGreekMasculine(String value) {
  return value.startsWith('Άγιος ') ||
      value.endsWith('άς') ||
      value.endsWith('ης');
}

bool _looksGreekNeuter(String value) {
  return value.endsWith('ο') ||
      value.endsWith('ι') ||
      value.endsWith('ν') ||
      value.endsWith('μ') ||
      value.endsWith('ύ');
}

String _toGreekMasculineAccusative(String value) {
  if (value.startsWith('Άγιος ')) {
    return value.replaceFirst('Άγιος ', 'Άγιο ');
  }
  if (value.endsWith('ος')) {
    return '${value.substring(0, value.length - 2)}ο';
  }
  if (value.endsWith('άς')) {
    return '${value.substring(0, value.length - 2)}ά';
  }
  if (value.endsWith('ης')) {
    return '${value.substring(0, value.length - 2)}η';
  }
  return value;
}

String _toGreekFeminineAccusative(String value) {
  if (value.endsWith('ος')) {
    return '${value.substring(0, value.length - 2)}ο';
  }
  return value;
}

String _buildTurkishFromName(String _, String nominative) {
  final trimmed = nominative.trim();
  if (trimmed.isEmpty) return trimmed;

  final lower = trimmed.toLowerCase();
  final lastLetter = _lastAlphabeticChar(lower);
  final lastVowel = _lastTurkishVowel(lower);
  final buffer = _needsTurkishBufferN(lower) ? 'n' : '';

  final consonant = lastLetter != null && _trVoicelessConsonants.contains(lastLetter)
      ? 't'
      : 'd';
  final vowel = lastVowel != null && _trBackVowels.contains(lastVowel) ? 'a' : 'e';

  return "$trimmed'$buffer$consonant${vowel}n";
}

String? _lastAlphabeticChar(String value) {
  for (var i = value.length - 1; i >= 0; i--) {
    final char = value[i];
    if (_trAlphabet.contains(char)) return char;
  }
  return null;
}

String? _lastTurkishVowel(String value) {
  for (var i = value.length - 1; i >= 0; i--) {
    final char = value[i];
    if (_trVowels.contains(char)) return char;
  }
  return null;
}

bool _needsTurkishBufferN(String value) {
  return value.endsWith('sı') ||
      value.endsWith('si') ||
      value.endsWith('su') ||
      value.endsWith('sü') ||
      value.endsWith('ları') ||
      value.endsWith('leri');
}

const Set<String> _trAlphabet = {
  'a',
  'b',
  'c',
  'ç',
  'd',
  'e',
  'f',
  'g',
  'ğ',
  'h',
  'ı',
  'i',
  'j',
  'k',
  'l',
  'm',
  'n',
  'o',
  'ö',
  'p',
  'r',
  's',
  'ş',
  't',
  'u',
  'ü',
  'v',
  'y',
  'z',
};

const Set<String> _trVowels = {
  'a',
  'e',
  'ı',
  'i',
  'o',
  'ö',
  'u',
  'ü',
};

const Set<String> _trBackVowels = {
  'a',
  'ı',
  'o',
  'u',
};

const Set<String> _trVoicelessConsonants = {
  'ç',
  'f',
  'h',
  'k',
  'p',
  's',
  'ş',
  't',
};

// ─────────────────────────────────────────────────────────────────────────────
// Russian genitive forms — used after "из"
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _ruGenitiveNames = {
  'AD': 'Андорры',
  'AE': 'ОАЭ',               // indeclinable acronym
  'AM': 'Армении',
  'AR': 'Аргентины',
  'AT': 'Австрии',
  'AU': 'Австралии',
  'AZ': 'Азербайджана',
  'BA': 'Боснии и Герцеговины',
  'BD': 'Бангладеш',          // indeclinable in modern Russian norm
  'BE': 'Бельгии',
  'BG': 'Болгарии',
  'BO': 'Боливии',
  'BR': 'Бразилии',
  'BY': 'Беларуси',           // official self-designation
  'CA': 'Канады',
  'CH': 'Швейцарии',
  'CL': 'Чили',               // indeclinable
  'CN': 'Китая',
  'CO': 'Колумбии',
  'CY': 'Кипра',
  'CZ': 'Чехии',
  'DE': 'Германии',
  'DK': 'Дании',
  'DZ': 'Алжира',
  'EC': 'Эквадора',
  'EE': 'Эстонии',
  'EG': 'Египта',
  'ES': 'Испании',
  'ET': 'Эфиопии',
  'FI': 'Финляндии',
  'FR': 'Франции',
  'GB': 'Великобритании',
  'GE': 'Грузии',
  'GH': 'Ганы',
  'GR': 'Греции',
  'HK': 'Гонконга',
  'HR': 'Хорватии',
  'HU': 'Венгрии',
  'ID': 'Индонезии',
  'IE': 'Ирландии',
  'IL': 'Израиля',
  'IN': 'Индии',
  'IQ': 'Ирака',
  'IR': 'Ирана',
  'IS': 'Исландии',
  'IT': 'Италии',
  'JO': 'Иордании',
  'JP': 'Японии',
  'KE': 'Кении',
  'KH': 'Камбоджи',
  'KR': 'Южной Кореи',
  'KW': 'Кувейта',
  'KZ': 'Казахстана',
  'LA': 'Лаоса',
  'LB': 'Ливана',
  'LK': 'Шри-Ланки',
  'LT': 'Литвы',
  'LU': 'Люксембурга',
  'LV': 'Латвии',
  'MA': 'Марокко',            // indeclinable
  'MD': 'Молдовы',
  'ME': 'Черногории',
  'MK': 'Северной Македонии',
  'MM': 'Мьянмы',
  'MN': 'Монголии',
  'MX': 'Мексики',
  'MY': 'Малайзии',
  'NG': 'Нигерии',
  'NL': 'Нидерландов',        // plurale tantum
  'NO': 'Норвегии',
  'NP': 'Непала',
  'NZ': 'Новой Зеландии',
  'PE': 'Перу',               // indeclinable
  'PH': 'Филиппин',           // plurale tantum
  'PK': 'Пакистана',
  'PL': 'Польши',
  'PT': 'Португалии',
  'QA': 'Катара',
  'RO': 'Румынии',
  'RS': 'Сербии',
  'RU': 'России',
  'SA': 'Саудовской Аравии',
  'SE': 'Швеции',
  'SG': 'Сингапура',
  'SI': 'Словении',
  'SK': 'Словакии',
  'TH': 'Таиланда',
  'TN': 'Туниса',
  'TR': 'Турции',
  'TW': 'Тайваня',
  'TZ': 'Танзании',
  'UA': 'Украины',
  'UG': 'Уганды',
  'US': 'США',                // indeclinable acronym
  'UZ': 'Узбекистана',
  'VE': 'Венесуэлы',
  'VN': 'Вьетнама',
  'ZA': 'ЮАР',               // indeclinable acronym
  'ZM': 'Замбии',
};

// ─────────────────────────────────────────────────────────────────────────────
// Ukrainian genitive forms — used after "з" / "зі"
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _ukGenitiveNames = {
  'AD': 'Андорри',
  'AE': 'ОАЕ',               // indeclinable acronym
  'AM': 'Вірменії',
  'AR': 'Аргентини',
  'AT': 'Австрії',
  'AU': 'Австралії',
  'AZ': 'Азербайджану',
  'BA': 'Боснії і Герцеговини',
  'BD': 'Бангладеш',          // indeclinable
  'BE': 'Бельгії',
  'BG': 'Болгарії',
  'BO': 'Болівії',
  'BR': 'Бразилії',
  'BY': 'Білорусі',
  'CA': 'Канади',
  'CH': 'Швейцарії',
  'CL': 'Чилі',               // indeclinable
  'CN': 'Китаю',
  'CO': 'Колумбії',
  'CY': 'Кіпру',
  'CZ': 'Чехії',
  'DE': 'Німеччини',
  'DK': 'Данії',
  'DZ': 'Алжиру',
  'EC': 'Еквадору',
  'EE': 'Естонії',
  'EG': 'Єгипту',
  'ES': 'Іспанії',
  'ET': 'Ефіопії',
  'FI': 'Фінляндії',
  'FR': 'Франції',
  'GB': 'Великої Британії',
  'GE': 'Грузії',
  'GH': 'Гани',
  'GR': 'Греції',
  'HK': 'Гонконгу',
  'HR': 'Хорватії',
  'HU': 'Угорщини',
  'ID': 'Індонезії',
  'IE': 'Ірландії',
  'IL': 'Ізраїлю',
  'IN': 'Індії',
  'IQ': 'Іраку',
  'IR': 'Ірану',
  'IS': 'Ісландії',
  'IT': 'Італії',
  'JO': 'Йорданії',
  'JP': 'Японії',
  'KE': 'Кенії',
  'KH': 'Камбоджі',
  'KR': 'Південної Кореї',
  'KW': 'Кувейту',
  'KZ': 'Казахстану',
  'LA': 'Лаосу',
  'LB': 'Лівану',
  'LK': 'Шрі-Ланки',
  'LT': 'Литви',
  'LU': 'Люксембургу',
  'LV': 'Латвії',
  'MA': 'Марокко',            // indeclinable
  'MD': 'Молдови',
  'ME': 'Чорногорії',
  'MK': 'Північної Македонії',
  'MM': 'М\'янми',
  'MN': 'Монголії',
  'MX': 'Мексики',
  'MY': 'Малайзії',
  'NG': 'Нігерії',
  'NL': 'Нідерландів',        // plurale tantum
  'NO': 'Норвегії',
  'NP': 'Непалу',
  'NZ': 'Нової Зеландії',
  'PE': 'Перу',               // indeclinable
  'PH': 'Філіппін',           // plurale tantum
  'PK': 'Пакистану',
  'PL': 'Польщі',
  'PT': 'Португалії',
  'QA': 'Катару',
  'RO': 'Румунії',
  'RS': 'Сербії',
  'RU': 'Росії',
  'SA': 'Саудівської Аравії',
  'SE': 'Швеції',
  'SG': 'Сингапуру',
  'SI': 'Словенії',
  'SK': 'Словаччини',
  'TH': 'Таїланду',
  'TN': 'Тунісу',
  'TR': 'Туреччини',
  'TW': 'Тайваню',
  'TZ': 'Танзанії',
  'UA': 'України',
  'UG': 'Уганди',
  'US': 'США',                // indeclinable acronym
  'UZ': 'Узбекистану',
  'VE': 'Венесуели',
  'VN': 'В\'єтнаму',
  'ZA': 'ПАР',               // indeclinable acronym
  'ZM': 'Замбії',
};

// ─────────────────────────────────────────────────────────────────────────────
// Polish genitive forms — used after "z" / "ze"
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _plGenitiveNames = {
  'AD': 'Andory',
  'AE': 'Zjednoczonych Emiratów Arabskich',
  'AM': 'Armenii',
  'AR': 'Argentyny',
  'AT': 'Austrii',
  'AU': 'Australii',
  'AZ': 'Azerbejdżanu',
  'BA': 'Bośni i Hercegowiny',
  'BD': 'Bangladeszu',
  'BE': 'Belgii',
  'BG': 'Bułgarii',
  'BO': 'Boliwii',
  'BR': 'Brazylii',
  'BY': 'Białorusi',
  'CA': 'Kanady',
  'CH': 'Szwajcarii',
  'CL': 'Chile',              // indeclinable
  'CN': 'Chin',               // plurale tantum
  'CO': 'Kolumbii',
  'CY': 'Cypru',
  'CZ': 'Czech',              // plurale tantum
  'DE': 'Niemiec',            // plurale tantum
  'DK': 'Danii',
  'DZ': 'Algierii',
  'EC': 'Ekwadoru',
  'EE': 'Estonii',
  'EG': 'Egiptu',
  'ES': 'Hiszpanii',
  'ET': 'Etiopii',
  'FI': 'Finlandii',
  'FR': 'Francji',
  'GB': 'Wielkiej Brytanii',
  'GE': 'Gruzji',
  'GH': 'Ghany',
  'GR': 'Grecji',
  'HK': 'Hongkongu',
  'HR': 'Chorwacji',
  'HU': 'Węgier',             // plurale tantum
  'ID': 'Indonezji',
  'IE': 'Irlandii',
  'IL': 'Izraela',
  'IN': 'Indii',              // plurale tantum
  'IQ': 'Iraku',
  'IR': 'Iranu',
  'IS': 'Islandii',
  'IT': 'Włoch',              // plurale tantum
  'JO': 'Jordanii',
  'JP': 'Japonii',
  'KE': 'Kenii',
  'KH': 'Kambodży',
  'KR': 'Korei Południowej',
  'KW': 'Kuwejtu',
  'KZ': 'Kazachstanu',
  'LA': 'Laosu',
  'LB': 'Libanu',
  'LK': 'Sri Lanki',
  'LT': 'Litwy',
  'LU': 'Luksemburga',
  'LV': 'Łotwy',
  'MA': 'Maroka',
  'MD': 'Mołdawii',
  'ME': 'Czarnogóry',
  'MK': 'Macedonii Północnej',
  'MM': 'Mjanmy',
  'MN': 'Mongolii',
  'MX': 'Meksyku',
  'MY': 'Malezji',
  'NG': 'Nigerii',
  'NL': 'Niderlandów',        // plurale tantum
  'NO': 'Norwegii',
  'NP': 'Nepalu',
  'NZ': 'Nowej Zelandii',
  'PE': 'Peru',               // indeclinable
  'PH': 'Filipin',            // plurale tantum
  'PK': 'Pakistanu',
  'PL': 'Polski',
  'PT': 'Portugalii',
  'QA': 'Kataru',
  'RO': 'Rumunii',
  'RS': 'Serbii',
  'RU': 'Rosji',
  'SA': 'Arabii Saudyjskiej',
  'SE': 'Szwecji',
  'SG': 'Singapuru',
  'SI': 'Słowenii',
  'SK': 'Słowacji',
  'TH': 'Tajlandii',
  'TN': 'Tunezji',
  'TR': 'Turcji',
  'TW': 'Tajwanu',
  'TZ': 'Tanzanii',
  'UA': 'Ukrainy',
  'UG': 'Ugandy',
  'US': 'Stanów Zjednoczonych', // plurale tantum
  'UZ': 'Uzbekistanu',
  'VE': 'Wenezueli',
  'VN': 'Wietnamu',
  'ZA': 'Republiki Południowej Afryki',
  'ZM': 'Zambii',
};

// ─────────────────────────────────────────────────────────────────────────────
// Croatian genitive forms — used after "iz"
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> _hrGenitiveNames = {
  'AD': 'Andore',
  'AE': 'Ujedinjenih Arapskih Emirata',
  'AM': 'Armenije',
  'AR': 'Argentine',
  'AT': 'Austrije',
  'AU': 'Australije',
  'AZ': 'Azerbajdžana',
  'BA': 'Bosne i Hercegovine',
  'BD': 'Bangladeša',
  'BE': 'Belgije',
  'BG': 'Bugarske',
  'BO': 'Bolivije',
  'BR': 'Brazila',
  'BY': 'Bjelorusije',
  'CA': 'Kanade',
  'CH': 'Švicarske',
  'CL': 'Čilea',
  'CN': 'Kine',
  'CO': 'Kolumbije',
  'CY': 'Cipra',
  'CZ': 'Češke',
  'DE': 'Njemačke',
  'DK': 'Danske',
  'DZ': 'Alžira',
  'EC': 'Ekvadora',
  'EE': 'Estonije',
  'EG': 'Egipta',
  'ES': 'Španjolske',
  'ET': 'Etiopije',
  'FI': 'Finske',
  'FR': 'Francuske',
  'GB': 'Velike Britanije',
  'GE': 'Gruzije',
  'GH': 'Gane',
  'GR': 'Grčke',
  'HK': 'Hong Konga',
  'HR': 'Hrvatske',
  'HU': 'Mađarske',
  'ID': 'Indonezije',
  'IE': 'Irske',
  'IL': 'Izraela',
  'IN': 'Indije',
  'IQ': 'Iraka',
  'IR': 'Irana',
  'IS': 'Islanda',
  'IT': 'Italije',
  'JO': 'Jordana',
  'JP': 'Japana',
  'KE': 'Kenije',
  'KH': 'Kambodže',
  'KR': 'Južne Koreje',
  'KW': 'Kuvajta',
  'KZ': 'Kazahstana',
  'LA': 'Laosa',
  'LB': 'Libanona',
  'LK': 'Šri Lanke',
  'LT': 'Litve',
  'LU': 'Luksemburga',
  'LV': 'Latvije',
  'MA': 'Maroka',
  'MD': 'Moldavije',
  'ME': 'Crne Gore',
  'MK': 'Sjeverne Makedonije',
  'MM': 'Mjanmara',
  'MN': 'Mongolije',
  'MX': 'Meksika',
  'MY': 'Malezije',
  'NG': 'Nigerije',
  'NL': 'Nizozemske',
  'NO': 'Norveške',
  'NP': 'Nepala',
  'NZ': 'Novog Zelanda',
  'PE': 'Perua',
  'PH': 'Filipina',           // plurale tantum
  'PK': 'Pakistana',
  'PL': 'Poljske',
  'PT': 'Portugala',
  'QA': 'Katara',
  'RO': 'Rumunjske',
  'RS': 'Srbije',
  'RU': 'Rusije',
  'SA': 'Saudijske Arabije',
  'SE': 'Švedske',
  'SG': 'Singapura',
  'SI': 'Slovenije',
  'SK': 'Slovačke',
  'TH': 'Tajlanda',
  'TN': 'Tunisa',
  'TR': 'Turske',
  'TW': 'Tajvana',
  'TZ': 'Tanzanije',
  'UA': 'Ukrajine',
  'UG': 'Ugande',
  'US': 'SAD-a',              // acronym + genitive clitic
  'UZ': 'Uzbekistana',
  'VE': 'Venezuele',
  'VN': 'Vijetnama',
  'ZA': 'Južnoafričke Republike',
  'ZM': 'Zambije',
};

/// ISO 3166-1 alpha-2 → alpha-3 lookup table (249 codes).
const Map<String, String> _alpha2ToAlpha3 = {
  'AF': 'AFG', 'AX': 'ALA', 'AL': 'ALB', 'DZ': 'DZA', 'AS': 'ASM',
  'AD': 'AND', 'AO': 'AGO', 'AI': 'AIA', 'AQ': 'ATA', 'AG': 'ATG',
  'AR': 'ARG', 'AM': 'ARM', 'AW': 'ABW', 'AU': 'AUS', 'AT': 'AUT',
  'AZ': 'AZE', 'BS': 'BHS', 'BH': 'BHR', 'BD': 'BGD', 'BB': 'BRB',
  'BY': 'BLR', 'BE': 'BEL', 'BZ': 'BLZ', 'BJ': 'BEN', 'BM': 'BMU',
  'BT': 'BTN', 'BO': 'BOL', 'BQ': 'BES', 'BA': 'BIH', 'BW': 'BWA',
  'BV': 'BVT', 'BR': 'BRA', 'IO': 'IOT', 'BN': 'BRN', 'BG': 'BGR',
  'BF': 'BFA', 'BI': 'BDI', 'CV': 'CPV', 'KH': 'KHM', 'CM': 'CMR',
  'CA': 'CAN', 'KY': 'CYM', 'CF': 'CAF', 'TD': 'TCD', 'CL': 'CHL',
  'CN': 'CHN', 'CX': 'CXR', 'CC': 'CCK', 'CO': 'COL', 'KM': 'COM',
  'CG': 'COG', 'CD': 'COD', 'CK': 'COK', 'CR': 'CRI', 'HR': 'HRV',
  'CU': 'CUB', 'CW': 'CUW', 'CY': 'CYP', 'CZ': 'CZE', 'CI': 'CIV',
  'DK': 'DNK', 'DJ': 'DJI', 'DM': 'DMA', 'DO': 'DOM', 'EC': 'ECU',
  'EG': 'EGY', 'SV': 'SLV', 'GQ': 'GNQ', 'ER': 'ERI', 'EE': 'EST',
  'SZ': 'SWZ', 'ET': 'ETH', 'FK': 'FLK', 'FO': 'FRO', 'FJ': 'FJI',
  'FI': 'FIN', 'FR': 'FRA', 'GF': 'GUF', 'PF': 'PYF', 'TF': 'ATF',
  'GA': 'GAB', 'GM': 'GMB', 'GE': 'GEO', 'DE': 'DEU', 'GH': 'GHA',
  'GI': 'GIB', 'GR': 'GRC', 'GL': 'GRL', 'GD': 'GRD', 'GP': 'GLP',
  'GU': 'GUM', 'GT': 'GTM', 'GG': 'GGY', 'GN': 'GIN', 'GW': 'GNB',
  'GY': 'GUY', 'HT': 'HTI', 'HM': 'HMD', 'VA': 'VAT', 'HN': 'HND',
  'HK': 'HKG', 'HU': 'HUN', 'IS': 'ISL', 'IN': 'IND', 'ID': 'IDN',
  'IR': 'IRN', 'IQ': 'IRQ', 'IE': 'IRL', 'IM': 'IMN', 'IL': 'ISR',
  'IT': 'ITA', 'JM': 'JAM', 'JP': 'JPN', 'JE': 'JEY', 'JO': 'JOR',
  'KZ': 'KAZ', 'KE': 'KEN', 'KI': 'KIR', 'KP': 'PRK', 'KR': 'KOR',
  'KW': 'KWT', 'KG': 'KGZ', 'LA': 'LAO', 'LV': 'LVA', 'LB': 'LBN',
  'LS': 'LSO', 'LR': 'LBR', 'LY': 'LBY', 'LI': 'LIE', 'LT': 'LTU',
  'LU': 'LUX', 'MO': 'MAC', 'MG': 'MDG', 'MW': 'MWI', 'MY': 'MYS',
  'MV': 'MDV', 'ML': 'MLI', 'MT': 'MLT', 'MH': 'MHL', 'MQ': 'MTQ',
  'MR': 'MRT', 'MU': 'MUS', 'YT': 'MYT', 'MX': 'MEX', 'FM': 'FSM',
  'MD': 'MDA', 'MC': 'MCO', 'MN': 'MNG', 'ME': 'MNE', 'MS': 'MSR',
  'MA': 'MAR', 'MZ': 'MOZ', 'MM': 'MMR', 'NA': 'NAM', 'NR': 'NRU',
  'NP': 'NPL', 'NL': 'NLD', 'NC': 'NCL', 'NZ': 'NZL', 'NI': 'NIC',
  'NE': 'NER', 'NG': 'NGA', 'NU': 'NIU', 'NF': 'NFK', 'MK': 'MKD',
  'MP': 'MNP', 'NO': 'NOR', 'OM': 'OMN', 'PK': 'PAK', 'PW': 'PLW',
  'PS': 'PSE', 'PA': 'PAN', 'PG': 'PNG', 'PY': 'PRY', 'PE': 'PER',
  'PH': 'PHL', 'PN': 'PCN', 'PL': 'POL', 'PT': 'PRT', 'PR': 'PRI',
  'QA': 'QAT', 'RE': 'REU', 'RO': 'ROU', 'RU': 'RUS', 'RW': 'RWA',
  'BL': 'BLM', 'SH': 'SHN', 'KN': 'KNA', 'LC': 'LCA', 'MF': 'MAF',
  'PM': 'SPM', 'VC': 'VCT', 'WS': 'WSM', 'SM': 'SMR', 'ST': 'STP',
  'SA': 'SAU', 'SN': 'SEN', 'RS': 'SRB', 'SC': 'SYC', 'SL': 'SLE',
  'SG': 'SGP', 'SX': 'SXM', 'SK': 'SVK', 'SI': 'SVN', 'SB': 'SLB',
  'SO': 'SOM', 'ZA': 'ZAF', 'GS': 'SGS', 'SS': 'SSD', 'ES': 'ESP',
  'LK': 'LKA', 'SD': 'SDN', 'SR': 'SUR', 'SJ': 'SJM', 'SE': 'SWE',
  'CH': 'CHE', 'SY': 'SYR', 'TW': 'TWN', 'TJ': 'TJK', 'TZ': 'TZA',
  'TH': 'THA', 'TL': 'TLS', 'TG': 'TGO', 'TK': 'TKL', 'TO': 'TON',
  'TT': 'TTO', 'TN': 'TUN', 'TR': 'TUR', 'TM': 'TKM', 'TC': 'TCA',
  'TV': 'TUV', 'UG': 'UGA', 'UA': 'UKR', 'AE': 'ARE', 'GB': 'GBR',
  'US': 'USA', 'UM': 'UMI', 'UY': 'URY', 'UZ': 'UZB', 'VU': 'VUT',
  'VE': 'VEN', 'VN': 'VNM', 'VG': 'VGB', 'VI': 'VIR', 'WF': 'WLF',
  'EH': 'ESH', 'YE': 'YEM', 'ZM': 'ZMB', 'ZW': 'ZWE', 'EL': 'GRC',
};
