import 'package:intl/intl.dart';

/// Dates in ar use Latin digits, like every number the app formats in ar.
///
/// flutter_localizations installs its own date symbols, and for `ar` they use
/// Arabic-Indic digits (٠–٩), while intl's number symbols give `ar` Latin ones.
/// Without this a Settings row read "11 من 30" beside a date of "٠٢/١٠/٢٠٢٦"
/// (plan 077 phase 13). fa needs nothing: both sources use Persian digits.
///
/// Call once at startup, before any DateFormat for ar is created — a
/// DateFormat reads this default the first time it formats.
void configureDateDigits() {
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
}
