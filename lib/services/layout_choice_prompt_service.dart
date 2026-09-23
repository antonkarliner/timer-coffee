import 'package:shared_preferences/shared_preferences.dart';

/// Decides whether the one-time layout picker should interrupt a Play tap
/// (plan 067 Phase 3), and which variant of it.
enum LayoutChoiceTrigger {
  /// Existing user, first brew after the picker shipped, no experiment arm.
  existingUser('existing_user'),

  /// The install carries an assigned experiment arm (plan 067 §2).
  secondBrew('second_brew'),

  /// Reserved for the finish-card entry point (plan 067, later phase);
  /// never returned by [resolvePickerTrigger] today.
  finishCard('finish_card');

  const LayoutChoiceTrigger(this.analyticsName);

  /// Value for the `trigger` property of the `layout_choice_*` events.
  final String analyticsName;
}

/// Whether and how to show the one-time "how do you want to brew?" picker.
///
/// Decisions only, no UI: the sheet itself lives in
/// `lib/widgets/brewing/layout_choice_sheet.dart`.
class LayoutChoicePromptService {
  LayoutChoicePromptService(this._prefs);

  static const _kSeenKey = 'layout_picker_seen';
  static const _kDismissedKey = 'layout_picker_dismissed';
  static const _kFinishCardShownKey = 'layout_finish_card_shown';
  static const _kFinishesSinceDismissalKey = 'layout_finishes_since_dismissal';

  /// Number of finish screens after dismissal before the second-chance card
  /// may appear. The immediate next finish is usually only minutes after the
  /// user declined the picker, so that finish is deliberately skipped.
  static const int kFinishesBeforeLayoutTry = 2;

  final SharedPreferences _prefs;

  /// Whether the picker has already been shown (or become moot) on this
  /// install. It shows at most once, ever.
  bool get pickerSeen => _prefs.getBool(_kSeenKey) ?? false;

  /// Whether the picker was shown and dismissed without a choice.
  bool get pickerDismissed => _prefs.getBool(_kDismissedKey) ?? false;

  /// Whether the finish-screen "second chance" card (plan 067 Phase 4) has
  /// already had its one shot. Shows at most once, ever — the same at-most-once
  /// contract as the picker itself.
  bool get finishCardShown => _prefs.getBool(_kFinishCardShownKey) ?? false;

  /// Finish screens recorded since the picker was dismissed, while the
  /// second-chance card still has an opportunity to appear.
  int get finishesSinceDismissal =>
      _prefs.getInt(_kFinishesSinceDismissalKey) ?? 0;

  Future<void> markPickerSeen() => _prefs.setBool(_kSeenKey, true);

  Future<void> markPickerDismissed() => _prefs.setBool(_kDismissedKey, true);

  Future<void> markFinishCardShown() =>
      _prefs.setBool(_kFinishCardShownKey, true);

  /// Records a finish only for users who dismissed the picker and have not
  /// already been shown the second-chance card. Keeping the counter scoped to
  /// that window prevents it growing for users who cannot see the card.
  Future<void> recordFinishForLayoutTry() async {
    if (!pickerDismissed || finishCardShown) return;
    await _prefs.setInt(
      _kFinishesSinceDismissalKey,
      finishesSinceDismissal + 1,
    );
  }

  /// Whether the finish-screen card may offer the immersive layout to a user
  /// who swiped the picker away without choosing (plan 067 Phase 4). The
  /// immediate next finish is commonly only minutes after the user
  /// declined, so eligibility starts on the second recorded finish after
  /// dismissal. Web is excluded (the picker is a mobile probe, same gate as
  /// [resolvePickerTrigger]), a card already shown is excluded (at most once,
  /// ever), and a user already brewing immersive has nothing to be offered.
  bool finishCardEligible({required bool isWeb, required bool pourEnabled}) =>
      !isWeb &&
      pickerDismissed &&
      !finishCardShown &&
      !pourEnabled &&
      finishesSinceDismissal >= kFinishesBeforeLayoutTry;

  /// Which picker variant to show on this Play tap, if any. Evaluated in a
  /// fixed order — web first, then seen, then the first-brew guard, then the
  /// experiment arm, then "already on immersive".
  ///
  /// **Contract:** this method is pure — it performs no writes. When it
  /// returns null because [pourEnabled] is true (the user is already brewing
  /// immersive, e.g. from the gear sheet, and has no arm), the caller MUST
  /// call [markSeenIfAlreadyOnPour] so the picker never asks about a choice
  /// the user has already made.
  LayoutChoiceTrigger? resolvePickerTrigger({
    required bool isWeb,
    required bool firstBrewDone,
    required String? arm,
    required bool pourEnabled,
  }) {
    // The picker is a mobile acquisition/adoption probe; web has its own
    // constraints.
    if (isWeb) return null;
    // It shows at most once, ever.
    if (pickerSeen) return null;
    // Never interrupt an install's very first brew.
    if (!firstBrewDone) return null;
    // An assigned arm already decided this install's layout; the picker's
    // job there is the second-brew "keep or switch" offer. This beats the
    // pourEnabled check below: a pour-arm install IS on pour by assignment,
    // not by choice, and still gets its one-time switch offer.
    if (arm != null) return LayoutChoiceTrigger.secondBrew;
    // Already brewing immersive by their own choice — nothing to ask; the
    // caller marks the picker seen via [markSeenIfAlreadyOnPour].
    if (pourEnabled) return null;
    return LayoutChoiceTrigger.existingUser;
  }

  /// Marks the picker seen when the user is already on the immersive layout
  /// without ever having been shown the picker. Re-checks the web and
  /// first-brew gates so no pref is written for installs that could never
  /// have seen it; a seen or dismissed picker is left untouched.
  Future<void> markSeenIfAlreadyOnPour({
    required bool isWeb,
    required bool firstBrewDone,
  }) async {
    if (isWeb || pickerSeen || !firstBrewDone) return;
    await markPickerSeen();
  }
}
