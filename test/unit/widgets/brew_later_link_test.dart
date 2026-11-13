import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brew_later_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// English ARB strings the tests interact with.
const _linkLabel = 'Brew later';
const _sheetTitle = 'Remind me at coffee time';
const _sheetBody = 'We’ll send a reminder with this recipe ready to go.';
const _timeRowLabel = 'Time';
const _confirmLabel = 'Set reminder';
const _cancelLabel = 'Cancel reminder';
const _deniedMessage = 'Notifications are off, so we can’t remind you.';
const _openSettingsLabel = 'Open Settings';

final Finder _linkSlot = find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == 'brewLaterLink',
);

/// Records every collaborator call so assertions run against plain data —
/// nothing here touches platform channels.
class FakeCollaborators {
  FakeCollaborators({DateTime? now}) : now = now ?? DateTime(2026, 11, 10, 7, 30);

  final DateTime now;
  bool isEligible = true;
  bool permissionUsable = false;
  bool permissionRequestResult = true;
  bool setReminderResult = true;
  TimeOfDay sheetDefaultTime = const TimeOfDay(hour: 9, minute: 15);

  /// When set, [requestPermission] parks on this until the test completes it —
  /// keeps the confirm button observable in its in-flight (disabled) state.
  Completer<bool>? permissionRequestGate;

  ({String recipeId, String methodId, DateTime fireAt})? pending;

  final List<Map<String, Object?>> setCalls = [];
  final List<String> cancelReasons = [];
  int permissionChecks = 0;
  int permissionRequests = 0;

  Future<bool> loadIsEligible() async => isEligible;

  Future<({String recipeId, String methodId, DateTime fireAt})?>
      readPending() async => pending;

  Future<bool> setReminder({
    required String recipeId,
    required String methodId,
    required DateTime fireAt,
    required String source,
    required String locale,
    required String recipeName,
  }) async {
    setCalls.add({
      'recipeId': recipeId,
      'methodId': methodId,
      'fireAt': fireAt,
      'source': source,
      'locale': locale,
      'recipeName': recipeName,
    });
    if (setReminderResult) {
      // Mirror the real scheduler: a successful set leaves a pending entry.
      pending = (recipeId: recipeId, methodId: methodId, fireAt: fireAt);
    }
    return setReminderResult;
  }

  Future<void> cancelReminder({required String reason}) async {
    cancelReasons.add(reason);
    pending = null;
  }

  Future<bool> checkPermissionUsable() async {
    permissionChecks++;
    return permissionUsable;
  }

  Future<bool> requestPermission() async {
    permissionRequests++;
    final gate = permissionRequestGate;
    if (gate != null) return gate.future;
    return permissionRequestResult;
  }

  Future<TimeOfDay> defaultTime() async => sheetDefaultTime;
}

List<Map<String, dynamic>> eventsNamed(String name) => AnalyticsService
    .instance
    .bufferedEventsForTesting
    .where((event) => event['event_name'] == name)
    .toList();

Future<void> pumpLink(WidgetTester tester, FakeCollaborators fakes) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<DateTimeFormatService>.value(
      value: DateTimeFormatService(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BrewLaterLink(
            recipeId: 'recipe-1',
            methodId: 'v60',
            recipeName: 'Test recipe',
            source: 'recipe_detail',
            loadIsEligible: fakes.loadIsEligible,
            readPending: fakes.readPending,
            setReminder: fakes.setReminder,
            cancelReminder: fakes.cancelReminder,
            checkPermissionUsable: fakes.checkPermissionUsable,
            requestPermission: fakes.requestPermission,
            defaultTime: fakes.defaultTime,
            now: () => fakes.now,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text(_linkLabel));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('brewLaterFireTime', () {
    test('29 minutes ahead rolls to tomorrow', () {
      final now = DateTime(2026, 11, 10, 7, 31);
      expect(
        brewLaterFireTime(now, const TimeOfDay(hour: 8, minute: 0)),
        DateTime(2026, 11, 11, 8, 0),
      );
    });

    test('exactly 30 minutes ahead stays today', () {
      final now = DateTime(2026, 11, 10, 7, 30);
      expect(
        brewLaterFireTime(now, const TimeOfDay(hour: 8, minute: 0)),
        DateTime(2026, 11, 10, 8, 0),
      );
    });

    test('a time earlier today rolls to tomorrow', () {
      final now = DateTime(2026, 11, 10, 9, 0);
      expect(
        brewLaterFireTime(now, const TimeOfDay(hour: 8, minute: 0)),
        DateTime(2026, 11, 11, 8, 0),
      );
    });

    test('crossing midnight (and a month boundary) stays on the clock', () {
      final now = DateTime(2026, 11, 30, 23, 0);
      expect(
        brewLaterFireTime(now, const TimeOfDay(hour: 8, minute: 0)),
        DateTime(2026, 12, 1, 8, 0),
      );
    });
  });

  testWidgets('zero brews → link visible inside its stable slot', (
    tester,
  ) async {
    final fakes = FakeCollaborators()..isEligible = true;
    await pumpLink(tester, fakes);

    expect(_linkSlot, findsOneWidget);
    expect(find.text(_linkLabel), findsOneWidget);
    final shown = eventsNamed('brew_later_shown');
    expect(shown, hasLength(1));
    expect(shown.single['properties'], {
      'source': 'recipe_detail',
      'recipe_id': 'recipe-1',
      'state': 'idle',
    });

    await openSheet(tester);
    Navigator.of(tester.element(find.text(_sheetTitle))).pop();
    await tester.pumpAndSettle();
    await pumpLink(tester, fakes);
    await tester.pump();
    expect(eventsNamed('brew_later_shown'), hasLength(1));
  });

  testWidgets('one brew → nothing rendered, slot stays in place', (
    tester,
  ) async {
    final fakes = FakeCollaborators()..isEligible = false;
    // Pump the loading frame before the eligibility answer arrives, so the
    // slot is present from the first frame.
    await tester.pumpWidget(
      ChangeNotifierProvider<DateTimeFormatService>.value(
        value: DateTimeFormatService(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BrewLaterLink(
              recipeId: 'recipe-1',
              methodId: 'v60',
              recipeName: 'Test recipe',
              source: 'recipe_detail',
              loadIsEligible: fakes.loadIsEligible,
              readPending: fakes.readPending,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(_linkLabel), findsNothing);
    await tester.pumpAndSettle();

    expect(_linkSlot, findsOneWidget); // stable wrapper still present
    expect(find.byType(AppTextButton), findsNothing);
    expect(find.text(_linkLabel), findsNothing);
    expect(eventsNamed('brew_later_shown'), isEmpty);
  });

  testWidgets('pending reminder for this recipe → set-state label', (
    tester,
  ) async {
    final fakes = FakeCollaborators()
      ..pending = (
        recipeId: 'recipe-1',
        methodId: 'v60',
        fireAt: DateTime(2026, 11, 10, 8, 30),
      );
    await pumpLink(tester, fakes);

    expect(find.text('Reminder at 08:30 AM'), findsOneWidget);
    final shown = eventsNamed('brew_later_shown');
    expect(shown, hasLength(1));
    expect(shown.single['properties'], {
      'source': 'recipe_detail',
      'recipe_id': 'recipe-1',
      'state': 'set',
    });
  });

  testWidgets('pending reminder for another recipe → idle label', (
    tester,
  ) async {
    final fakes = FakeCollaborators()
      ..pending = (
        recipeId: 'other-recipe',
        methodId: 'v60',
        fireAt: DateTime(2026, 11, 10, 8, 30),
      );
    await pumpLink(tester, fakes);

    expect(find.text(_linkLabel), findsOneWidget);
    expect(find.textContaining('Reminder at'), findsNothing);
  });

  testWidgets('tap → sheet opens with heading, time row and confirm button', (
    tester,
  ) async {
    final fakes = FakeCollaborators();
    await pumpLink(tester, fakes);

    await openSheet(tester);

    expect(find.text(_sheetTitle), findsOneWidget);
    expect(find.text(_sheetBody), findsOneWidget);
    expect(find.text(_timeRowLabel), findsOneWidget);
    // Default time 09:15 with now = 07:30 → today at 09:15 AM.
    expect(find.text('Today at 09:15 AM'), findsOneWidget);
    expect(find.text(_confirmLabel), findsOneWidget);

    final tapped = eventsNamed('brew_later_tapped');
    expect(tapped, hasLength(1));
    expect(tapped.single['properties'], {
      'source': 'recipe_detail',
      'recipe_id': 'recipe-1',
      'state': 'idle',
    });
  });

  testWidgets(
    'confirm with permission already usable → setBrewLater once, sheet closes',
    (tester) async {
      final fakes = FakeCollaborators()..permissionUsable = true;
      await pumpLink(tester, fakes);
      await openSheet(tester);

      await tester.tap(find.text(_confirmLabel));
      await tester.pumpAndSettle();

      expect(fakes.setCalls, hasLength(1));
      final call = fakes.setCalls.single;
      expect(call['recipeId'], 'recipe-1');
      expect(call['methodId'], 'v60');
      expect(call['source'], 'recipe_detail');
      expect(call['locale'], 'en');
      expect(call['recipeName'], 'Test recipe');
      expect(call['fireAt'], DateTime(2026, 11, 10, 9, 15));
      expect(fakes.permissionChecks, 1);
      expect(fakes.permissionRequests, 0);

      // The sheet closed and the link reloaded into the set state.
      expect(find.text(_sheetTitle), findsNothing);
      expect(find.text('Reminder at 09:15 AM'), findsOneWidget);

      final scheduled = eventsNamed('brew_later_scheduled');
      expect(scheduled, hasLength(1));
      expect(scheduled.single['properties'], {
        'source': 'recipe_detail',
        'recipe_id': 'recipe-1',
        'hours_ahead': 2, // 105 minutes, rounded
        'permission': 'already_granted',
        'day': 'today',
        'time_changed': false,
      });
    },
  );

  testWidgets(
    'confirm with permission request denied → nothing scheduled, denied state',
    (tester) async {
      final fakes = FakeCollaborators()
        ..permissionUsable = false
        ..permissionRequestResult = false;
      await pumpLink(tester, fakes);
      await openSheet(tester);

      await tester.tap(find.text(_confirmLabel));
      await tester.pumpAndSettle();

      expect(fakes.setCalls, isEmpty);
      expect(find.text(_deniedMessage), findsOneWidget);
      expect(find.text(_openSettingsLabel), findsOneWidget);
      expect(find.text(_sheetTitle), findsOneWidget); // sheet stays open

      // The AB flag that stops the first-brew dialog from leading to an OS
      // prompt iOS will no longer show.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notif_perm_ab_shown'), isTrue);

      final shown = eventsNamed('notification_permission_shown');
      expect(shown, hasLength(1));
      expect(shown.single['properties'], {'source': 'brew_later'});
      final result = eventsNamed('notification_permission_result');
      expect(result, hasLength(1));
      expect(result.single['properties'], {
        'source': 'brew_later',
        'result': 'denied',
      });
      final denied = eventsNamed('brew_later_permission_denied');
      expect(denied, hasLength(1));
      expect(denied.single['properties'], {
        'source': 'recipe_detail',
        'recipe_id': 'recipe-1',
      });

      await tester.tap(find.text(_openSettingsLabel));
      await tester.pumpAndSettle();

      expect(find.text(_sheetTitle), findsNothing);
      final opened = eventsNamed('brew_later_settings_opened');
      expect(opened, hasLength(1));
      expect(opened.single['properties'], {
        'source': 'recipe_detail',
        'recipe_id': 'recipe-1',
      });
    },
  );

  testWidgets(
    'confirm with permission granted now → scheduled with granted_now',
    (tester) async {
      final fakes = FakeCollaborators()
        ..permissionUsable = false
        ..permissionRequestResult = true;
      await pumpLink(tester, fakes);
      await openSheet(tester);

      await tester.tap(find.text(_confirmLabel));
      await tester.pumpAndSettle();

      expect(fakes.permissionRequests, 1);
      expect(fakes.setCalls, hasLength(1));
      expect(find.text(_sheetTitle), findsNothing);

      final scheduled = eventsNamed('brew_later_scheduled');
      expect(scheduled, hasLength(1));
      expect(scheduled.single['properties'], {
        'source': 'recipe_detail',
        'recipe_id': 'recipe-1',
        'hours_ahead': 2,
        'permission': 'granted_now',
        'day': 'today',
        'time_changed': false,
      });
    },
  );

  testWidgets('default time earlier today schedules for tomorrow', (
    tester,
  ) async {
    final fakes = FakeCollaborators(now: DateTime(2026, 11, 10, 10))
      ..permissionUsable = true;
    await pumpLink(tester, fakes);
    await openSheet(tester);

    await tester.tap(find.text(_confirmLabel));
    await tester.pumpAndSettle();

    expect(fakes.setCalls.single['fireAt'], DateTime(2026, 11, 11, 9, 15));
    final scheduled = eventsNamed('brew_later_scheduled');
    expect(scheduled, hasLength(1));
    expect(scheduled.single['properties']['day'], 'tomorrow');
    expect(scheduled.single['properties']['time_changed'], isFalse);
  });

  for (final returnToDefault in [false, true]) {
    testWidgets(
      'picked time tracks change, return to default: $returnToDefault',
      (tester) async {
        final fakes = FakeCollaborators()..permissionUsable = true;
        await pumpLink(tester, fakes);
        await openSheet(tester);

        await tester.tap(find.text(_timeRowLabel));
        await tester.pumpAndSettle();
        final minutes = tester.widget<ListWheelScrollView>(
          find.byType(ListWheelScrollView).last,
        );
        (minutes.controller! as FixedExtentScrollController).jumpToItem(20);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Today at 09:20 AM'), findsOneWidget);

        if (returnToDefault) {
          await tester.tap(find.text(_timeRowLabel));
          await tester.pumpAndSettle();
          final minutes = tester.widget<ListWheelScrollView>(
            find.byType(ListWheelScrollView).last,
          );
          (minutes.controller! as FixedExtentScrollController).jumpToItem(15);
          await tester.pumpAndSettle();
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          expect(find.text('Today at 09:15 AM'), findsOneWidget);
        }

        await tester.tap(find.text(_confirmLabel));
        await tester.pumpAndSettle();

        final scheduled = eventsNamed('brew_later_scheduled');
        expect(scheduled, hasLength(1));
        expect(scheduled.single['properties']['day'], 'today');
        expect(
          scheduled.single['properties']['time_changed'],
          !returnToDefault,
        );
      },
    );
  }

  testWidgets('double tap on confirm fires one permission request', (
    tester,
  ) async {
    final fakes = FakeCollaborators()..permissionUsable = false;
    // Park the OS prompt mid-flight so the disabled confirm state is
    // observable (instant fakes would let the whole flow finish in
    // microtasks before any frame renders).
    final gate = Completer<bool>();
    fakes.permissionRequestGate = gate;
    await pumpLink(tester, fakes);
    await openSheet(tester);

    final confirmFinder =
        find.widgetWithText(AppElevatedButton, _confirmLabel);
    await tester.tap(find.text(_confirmLabel));
    await tester.pump();
    // The in-flight guard disables the underlying ElevatedButton, so a second
    // press cannot fire another permission request (the disabled button
    // swallows the tap — hence warnIfMissed: false).
    final innerButton = tester.widget<ElevatedButton>(
      find.descendant(of: confirmFinder, matching: find.byType(ElevatedButton)),
    );
    expect(innerButton.onPressed, isNull);
    await tester.tap(find.text(_confirmLabel), warnIfMissed: false);
    expect(fakes.permissionRequests, 1);

    // Let the parked request resolve; the flow completes normally.
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(fakes.setCalls, hasLength(1));
    expect(find.text(_sheetTitle), findsNothing);
  });

  testWidgets('set state sheet → Cancel reminder cancels with reason user', (
    tester,
  ) async {
    final fakes = FakeCollaborators()
      ..pending = (
        recipeId: 'recipe-1',
        methodId: 'v60',
        fireAt: DateTime(2026, 11, 10, 8, 30),
      );
    await pumpLink(tester, fakes);

    await tester.tap(find.text('Reminder at 08:30 AM'));
    await tester.pumpAndSettle();

    expect(find.text(_sheetTitle), findsOneWidget);
    expect(find.text('Today at 08:30 AM'), findsOneWidget);
    expect(find.text(_cancelLabel), findsOneWidget);
    final tapped = eventsNamed('brew_later_tapped');
    expect(tapped.single['properties']['state'], 'set');

    await tester.tap(find.text(_cancelLabel));
    await tester.pumpAndSettle();

    expect(fakes.cancelReasons, ['user']);
    expect(find.text(_cancelLabel), findsNothing); // sheet closed
    expect(find.text(_linkLabel), findsOneWidget); // link back to idle
  });
}
