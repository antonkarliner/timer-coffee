import 'package:flutter/material.dart';

import '../utils/app_logger.dart';

/// How long the undo window stays open. Mirrored by the delete-confirmation
/// copy ("You can undo this for a few seconds after deletion") — keep the two
/// in sync if this ever changes.
const Duration kUndoSnackBarDuration = Duration(seconds: 5);

/// Shows the shared "deleted — Undo" snackbar used by every delete flow.
///
/// [messenger] must be captured with `ScaffoldMessenger.of(context)` BEFORE
/// any `await`/navigation in the caller (see the delete flows): the captured
/// `ScaffoldMessengerState` keeps working after the route that deleted the
/// item has popped, whereas a fresh `ScaffoldMessenger.of(context)` lookup
/// after the pop reads a defunct element.
///
/// [onUndo] runs when the user taps the action — call the matching
/// `restore*` provider method (and refresh whatever the undo callback owns).
/// A failed restore is logged, never thrown into the framework.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
}) {
  if (!messenger.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: kUndoSnackBarDuration,
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () async {
          try {
            await onUndo();
          } catch (e, st) {
            AppLogger.error('Undo action failed', errorObject: e, stackTrace: st);
          }
        },
      ),
    ),
  );
}
