import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../utils/app_logger.dart';

/// How long the undo window stays open. Mirrored by the delete-confirmation
/// copy ("You can undo this for a few seconds after deletion") — keep the two
/// in sync if this ever changes.
const Duration kUndoSnackBarDuration = Duration(seconds: 5);

/// The kind of entity the undo restores — the only property carried by the
/// `delete_undo_tapped` event. The event measures demand for a trash bin: a
/// high undo tap rate is evidence one is wanted, near-zero that it would be
/// dead UI (plan 056 Phase 5).
enum UndoEntityType { diary, bean, recipe }

/// Shows the shared "deleted — Undo" snackbar used by every delete flow.
///
/// [messenger] must be captured with `ScaffoldMessenger.of(context)` BEFORE
/// any `await`/navigation in the caller (see the delete flows): the captured
/// `ScaffoldMessengerState` keeps working after the route that deleted the
/// item has popped, whereas a fresh `ScaffoldMessenger.of(context)` lookup
/// after the pop reads a defunct element.
///
/// [entity] is tracked on the undo tap as `delete_undo_tapped` — every flow
/// that shows this snackbar must pass it, so the undo rate is measurable per
/// entity kind from one chokepoint.
///
/// [onUndo] runs when the user taps the action — call the matching
/// `restore*` provider method (and refresh whatever the undo callback owns).
/// A failed restore is logged, never thrown into the framework.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String undoLabel,
  required UndoEntityType entity,
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
          // The tap itself is the signal — track it before the restore runs,
          // so a failed restore still counts as wanted undo UI.
          AnalyticsService.maybeInstance?.track(
            'delete_undo_tapped',
            properties: {'entity': entity.name},
          );
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
