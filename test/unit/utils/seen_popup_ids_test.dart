import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/utils/seen_popup_ids.dart';
import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// With audience targeting (plan 076 §3) the popup a viewer is served can
/// move back to an older one they already closed. Seen-state must remember
/// more than the last id, or that popup shows again — seen on the simulator
/// on 2026-10-03 after a targeted test popup was deleted.
void main() {
  const key = 'lastPopupId_en';

  group('SeenPopupIds', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('remembers earlier ids, not only the last', () async {
      await SeenPopupIds.add(prefs, key, 5659);
      await SeenPopupIds.add(prefs, key, 5681);

      expect(SeenPopupIds.contains(prefs, key, 5681), isTrue);
      expect(SeenPopupIds.contains(prefs, key, 5659), isTrue);
      expect(SeenPopupIds.contains(prefs, key, 5682), isFalse);
    });

    test('keeps writing the last id to the legacy key', () async {
      await SeenPopupIds.add(prefs, key, 7);
      await SeenPopupIds.add(prefs, key, 9);
      expect(prefs.getInt(key), 9);
    });

    test('honours the last id an older install saved', () async {
      SharedPreferences.setMockInitialValues({key: 5659});
      prefs = await SharedPreferences.getInstance();
      expect(SeenPopupIds.contains(prefs, key, 5659), isTrue);

      // ...and keeps it once the next popup is recorded.
      await SeenPopupIds.add(prefs, key, 5681);
      expect(SeenPopupIds.contains(prefs, key, 5659), isTrue);
    });

    test('keys are independent (home vs finish surface)', () async {
      await SeenPopupIds.add(prefs, key, 1);
      expect(
        SeenPopupIds.contains(prefs, 'lastPopupIdSeenAtFinish_en', 1),
        isFalse,
      );
    });

    test('bounds the history, dropping the oldest', () async {
      for (var id = 1; id <= 60; id++) {
        await SeenPopupIds.add(prefs, key, id);
      }
      expect(prefs.getStringList('${key}_history'), hasLength(50));
      expect(SeenPopupIds.contains(prefs, key, 60), isTrue);
      expect(SeenPopupIds.contains(prefs, key, 11), isTrue);
      expect(SeenPopupIds.contains(prefs, key, 10), isFalse);
    });

    test('re-adding an id moves it to the newest end', () async {
      await SeenPopupIds.add(prefs, key, 1);
      await SeenPopupIds.add(prefs, key, 2);
      await SeenPopupIds.add(prefs, key, 1);
      expect(prefs.getStringList('${key}_history'), ['2', '1']);
    });
  });

  group('home launch popup', () {
    setUp(() async {
      LaunchPopupWidget.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'launch_popup_first_session_done': true,
      });
      AnalyticsService.resetForTesting();
      await AnalyticsService.initialize(await SharedPreferences.getInstance());
    });

    tearDown(AnalyticsService.resetForTesting);

    LaunchPopupModel popup(int id) => LaunchPopupModel(
      id: id,
      content: 'Popup $id',
      locale: 'en',
      createdAt: DateTime.utc(2026, 10, 1),
      platform: 'all',
    );

    /// Launches the home popup once with [served]; closes it if shown.
    /// Returns whether a dialog appeared.
    Future<bool> launchWith(
      WidgetTester tester,
      LaunchPopupModel served,
    ) async {
      LaunchPopupWidget.resetForTesting();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: LaunchPopupWidget(
              key: UniqueKey(),
              fetchPopupOverride: (context, locale) async => served,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shown = find.byType(AlertDialog).evaluate().isNotEmpty;
      if (shown) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
      return shown;
    }

    testWidgets('a closed popup does not return after a targeted one ends', (
      tester,
    ) async {
      final untargeted = popup(5659);
      final targeted = popup(5681);

      expect(await launchWith(tester, untargeted), isTrue);
      expect(await launchWith(tester, targeted), isTrue);
      // The targeted popup is gone; the RPC serves the older one again.
      expect(await launchWith(tester, untargeted), isFalse);
    });
  });
}
