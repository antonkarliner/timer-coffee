import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:coffee_timer/widgets/account/account_entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Taps the shared account entry tile and asserts the one
/// `account_entry_tapped` event per surface.
///
/// Only the anonymous branch can be exercised here: producing a real
/// signed-in session needs the Supabase stack, so the avatar row's analytics
/// emission (same call site, `signedIn: true`) is covered on-device.
/// The tap also opens the real sign-in sheet — with Supabase pointed at the
/// local test endpoint it renders its static buttons without network calls,
/// which doubles as a smoke test of the prompt wiring.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> entryEvents() => AnalyticsService
      .instance.bufferedEventsForTesting
      .where((event) => event['event_name'] == 'account_entry_tapped')
      .toList();

  Future<void> pumpTile(
    WidgetTester tester,
    AccountEntrySource source,
  ) async {
    // Tall surface: the sign-in bottom sheet's fixed-height content must fit
    // or the test fails on a RenderFlex overflow that is not the tile's
    // doing.
    tester.view.physicalSize = const Size(375, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: AccountEntryTile(source: source),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
      'anonymous tap from settings reports one anonymous settings event and '
      'opens the sign-in sheet', (tester) async {
    await pumpTile(tester, AccountEntrySource.settings);
    expect(find.bySemanticsIdentifier('signIn'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('signIn'));
    await tester.pumpAndSettle();

    expect(entryEvents(), hasLength(1));
    expect(entryEvents().single['properties'], {
      'source': 'settings',
      'state': 'anonymous',
    });
    // Sheet-only copy: the tile subtitle carries the same title text.
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('anonymous tap from the hub reports the hub source',
      (tester) async {
    await pumpTile(tester, AccountEntrySource.hub);
    expect(find.bySemanticsIdentifier('signIn'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('signIn'));
    await tester.pumpAndSettle();

    expect(entryEvents(), hasLength(1));
    expect(entryEvents().single['properties'], {
      'source': 'hub',
      'state': 'anonymous',
    });
  });
}
