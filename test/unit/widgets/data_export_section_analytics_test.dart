import 'dart:convert';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/widgets/settings/data_export_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_database.dart';

/// Analytics coverage for the data-export funnel in [DataExportSection].
///
/// `DataExportService` is constructed inside `_startExportFlow`, so no fake
/// can be injected without restructuring the section (explicitly out of
/// scope). What IS reachable end-to-end without a backend:
///
/// - `data_export_started` (Supabase initialized, no session → signed_in
///   false);
/// - `data_export_failed` stage `request` with reason `invalidEmail`
///   (client-side validation — no network touched, so the test binding's
///   fake HTTP client never gets involved);
/// - cancelling a dialog emits nothing.
///
/// The remaining reasons and stages need a live `export-user-data` function
/// or a request success to reach the code dialog (`data_export_code_sent`,
/// `data_export_completed`, stage `confirm`). Two notes instead:
///
/// - Under `testWidgets` every HTTP call is answered by the binding's fake
///   client with status 400, which `_resultFromException` maps to
///   `expiredOrNoRequest` — asserting that here would test the fake, not
///   our code, so it is not done.
/// - The `networkError` reason is pinned in
///   `test/unit/services/data_export_network_result_test.dart`, a
///   plain-zone file (no `testWidgets` in the isolate, so no fake HTTP
///   client) that drives `requestCode` against a dead port. It feeds the
///   same `_trackExportFailed` call site this file exercises.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // Port 59999 has no listener. The widget tests never touch it (the test
    // binding's fake HTTP client intercepts everything); the plain-zone
    // networkError test below needs the connection to be refused.
    await Supabase.initialize(
      url: 'http://localhost:59999',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() async {
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> allEvents() =>
      AnalyticsService.instance.bufferedEventsForTesting;

  List<Map<String, dynamic>> eventsNamed(String name) =>
      allEvents().where((event) => event['event_name'] == name).toList();

  Future<void> pumpSection(WidgetTester tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<AnalyticsService>.value(
            value: AnalyticsService.instance,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: DataExportSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the tile emits data_export_started with signed_in '
      'false for an anonymous session', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();

    final started = eventsNamed('data_export_started');
    expect(started, hasLength(1));
    expect(started.single['properties'], {'signed_in': false});

    // Closing the email dialog without submitting emits nothing more.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(eventsNamed('data_export_started'), hasLength(1));
    expect(eventsNamed('data_export_failed'), isEmpty);
  });

  testWidgets('an invalid email emits one request-stage failure and never '
      'the address itself', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();

    // The dialog's field is the only TextField on screen.
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    // Client-side validation failed: the error stays in the dialog. (The
    // InputDecorator renders the error text twice — error label and helper.)
    expect(find.text('Please enter a valid email address.'), findsWidgets);

    final failed = eventsNamed('data_export_failed');
    expect(failed, hasLength(1));
    expect(failed.single['properties'], {
      'stage': 'request',
      'reason': 'invalidEmail',
    });
    expect(jsonEncode(allEvents()), isNot(contains('not-an-email')));
  });
}
