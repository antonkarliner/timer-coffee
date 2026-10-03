import 'package:flutter/foundation.dart';

/// The language code the UI is actually rendered in — `main.dart`'s
/// resolution (saved pref → supported system locale → `en`), kept current by
/// [RecipeProvider.setLocale].
///
/// Exists for code without a `BuildContext` (the push-token write) that must
/// report the real app language rather than the `locale` pref, which is only
/// set when the user picks a language explicitly (plan 076 §1).
///
/// `null` until `main.dart` has resolved the locale; notification setup runs
/// before that, so listen rather than read once.
class ResolvedAppLocale {
  ResolvedAppLocale._();

  static final ValueNotifier<String?> languageCode = ValueNotifier<String?>(
    null,
  );
}
