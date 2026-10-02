import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/settings_analytics.dart';
import 'package:coffee_timer/widgets/account/account_entry_tile.dart';
import 'package:coffee_timer/widgets/account/account_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Taps the shared account entry tile and asserts the one
/// `account_entry_tapped` event per surface.
///
/// Producing a real signed-in session needs the Supabase stack, so
/// `AccountEntryTile`'s signed-in branch is exercised through its
/// [AccountIdentityTile] row pumped directly; the signed-in tap's analytics
/// emission (same call site, `signedIn: true`) stays covered on-device.
/// The anonymous tap opens the real sign-in sheet — with Supabase pointed at
/// the local test endpoint it renders its static buttons without network
/// calls, which doubles as a smoke test of the prompt wiring.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() async {
    resetAccountIdentitySessionName();
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
    AccountEntrySource source, {
    bool showChevron = false,
  }) async {
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
          body: AccountEntryTile(source: source, showChevron: showChevron),
        ),
      ),
    );
    await tester.pump();
  }

  /// Pumps the signed-in identity row directly — the widget the tile's
  /// signed-in branch renders, so its name/email/chevron behaviour is
  /// testable without a real session.
  Future<void> pumpIdentityRow(
    WidgetTester tester, {
    bool showChevron = false,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: AccountIdentityTile(
            userId: 'user-1',
            email: 'brewer@example.com',
            fetchDisplayName: (userId) async => 'Brewer',
            showChevron: showChevron,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
    // Build, then flush the cache-read/fetch microtasks.
    await tester.pump();
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

  testWidgets('sign-in row shows the chevron only with showChevron',
      (tester) async {
    await pumpTile(tester, AccountEntrySource.settings);
    expect(find.bySemanticsIdentifier('signIn'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await pumpTile(tester, AccountEntrySource.settings, showChevron: true);
    expect(find.bySemanticsIdentifier('signIn'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets(
      'signed-in identity row shows name and email under the account '
      'identifier and reports taps', (tester) async {
    var taps = 0;
    await pumpIdentityRow(tester, onTap: () => taps++);

    expect(find.bySemanticsIdentifier('account'), findsOneWidget);
    expect(find.text('Brewer'), findsOneWidget);
    expect(find.text('brewer@example.com'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.tap(find.bySemanticsIdentifier('account'));
    expect(taps, 1);
  });

  testWidgets('signed-in identity row shows the chevron only with showChevron',
      (tester) async {
    await pumpIdentityRow(tester);
    expect(find.bySemanticsIdentifier('account'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await pumpIdentityRow(tester, showChevron: true);
    expect(find.bySemanticsIdentifier('account'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
