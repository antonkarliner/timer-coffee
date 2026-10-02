import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/account/account_identity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coverage for the signed-in identity row: the cache helpers (trust rules)
/// and the widget itself, with the Supabase fetch injected so no backend
/// runs.
///
/// A real signed-in session can't be produced in a widget test, so the row
/// is pumped directly — `AccountEntryTile` only chooses between this row and
/// the sign-in prompt.
void main() {
  setUpAll(() async {
    // Must precede Supabase.initialize: its auth storage reads
    // SharedPreferences, which needs a mock store under the test binding.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  // The resolved name outlives a widget for the rest of the session.
  setUp(resetAccountIdentitySessionName);

  /// Resets the mock store to [values] and returns the fresh instance. The
  /// widget resolves its own `SharedPreferences.getInstance()` lazily, so
  /// seeding must happen before pumping.
  Future<SharedPreferences> freshPrefs([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('display-name cache helpers', () {
    test('readTrustedDisplayName returns the cached name for the same user',
        () async {
      final prefs = await freshPrefs({
        'user_display_name': 'Brewer',
        'user_display_name_user_id': 'user-1',
      });
      expect(readTrustedDisplayName(prefs, 'user-1'), 'Brewer');
    });

    test('readTrustedDisplayName misses when the id key is absent', () async {
      final prefs = await freshPrefs({'user_display_name': 'Brewer'});
      expect(readTrustedDisplayName(prefs, 'user-1'), isNull);
    });

    test('readTrustedDisplayName misses when the id key names another user',
        () async {
      final prefs = await freshPrefs({
        'user_display_name': 'Someone Else',
        'user_display_name_user_id': 'user-2',
      });
      expect(readTrustedDisplayName(prefs, 'user-1'), isNull);
    });

    test('writeDisplayNameCache stores the name and the owning user id',
        () async {
      final prefs = await freshPrefs();
      await writeDisplayNameCache(prefs, 'user-1', 'Brewer');
      expect(prefs.getString('user_display_name'), 'Brewer');
      expect(prefs.getString('user_display_name_user_id'), 'user-1');
    });
  });

  group('AccountIdentityTile', () {
    Future<void> pumpIdentity(
      WidgetTester tester, {
      String userId = 'user-1',
      String? email = 'brewer@example.com',
      Future<String?> Function(String userId)? fetch,
      bool showChevron = false,
      ValueListenable<int>? refreshSignal,
      VoidCallback? onTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AccountIdentityTile(
              userId: userId,
              email: email,
              fetchDisplayName: fetch ?? (userId) async => null,
              showChevron: showChevron,
              refreshSignal: refreshSignal,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      );
      // Build, then flush the cache-read microtasks.
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the cached name before the fetch resolves',
        (tester) async {
      await freshPrefs({
        'user_display_name': 'Cached Name',
        'user_display_name_user_id': 'user-1',
      });
      final fetch = Completer<String?>();
      await pumpIdentity(tester, fetch: (userId) => fetch.future);

      expect(find.text('Cached Name'), findsOneWidget);
      expect(find.text('Account'), findsNothing);

      fetch.complete('Server Name');
      await tester.pump();
      await tester.pump();
      expect(find.text('Server Name'), findsOneWidget);
    });

    testWidgets('a remount draws the session name on its first frame',
        (tester) async {
      await freshPrefs();
      await pumpIdentity(tester, fetch: (userId) async => 'Server Name');
      expect(find.text('Server Name'), findsOneWidget);

      // Leave and come back, as a second Settings visit does. Only the
      // first frame is pumped: the prefs read is still in flight.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: AccountIdentityTile(
              userId: 'user-1',
              fetchDisplayName: (userId) => Completer<String?>().future,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Server Name'), findsOneWidget);
      expect(find.text('Account'), findsNothing);
    });

    testWidgets('never shows the session name of another user', (tester) async {
      await freshPrefs();
      await pumpIdentity(tester, fetch: (userId) async => 'Server Name');
      expect(find.text('Server Name'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpIdentity(
        tester,
        userId: 'user-2',
        fetch: (userId) => Completer<String?>().future,
      );

      expect(find.text('Server Name'), findsNothing);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('shows Account, then the fetched name, when nothing is cached',
        (tester) async {
      await freshPrefs();
      final fetch = Completer<String?>();
      await pumpIdentity(tester, fetch: (userId) => fetch.future);

      expect(find.text('Account'), findsOneWidget);

      fetch.complete('Server Name');
      await tester.pump();
      await tester.pump();
      expect(find.text('Server Name'), findsOneWidget);
      expect(find.text('Account'), findsNothing);
    });

    testWidgets('never shows a cached name owned by another user',
        (tester) async {
      await freshPrefs({
        'user_display_name': 'Someone Else',
        'user_display_name_user_id': 'user-2',
      });
      final fetch = Completer<String?>();
      await pumpIdentity(tester, fetch: (userId) => fetch.future);

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Someone Else'), findsNothing);

      fetch.complete('Real Name');
      await tester.pump();
      await tester.pump();
      expect(find.text('Real Name'), findsOneWidget);
      expect(find.text('Someone Else'), findsNothing);
    });

    testWidgets('a successful fetch writes both cache keys', (tester) async {
      final prefs = await freshPrefs();
      await pumpIdentity(tester, fetch: (userId) async => 'Server Name');

      expect(prefs.getString('user_display_name'), 'Server Name');
      expect(prefs.getString('user_display_name_user_id'), 'user-1');
    });

    testWidgets('a failed fetch keeps the current title and does not throw',
        (tester) async {
      await freshPrefs();
      await pumpIdentity(
        tester,
        fetch: (userId) async => throw Exception('offline'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('an empty user id never triggers a fetch', (tester) async {
      await freshPrefs();
      var fetchCalls = 0;
      await pumpIdentity(
        tester,
        userId: '',
        fetch: (userId) async {
          fetchCalls++;
          return null;
        },
      );

      expect(fetchCalls, 0);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('shows the email as the subtitle', (tester) async {
      await freshPrefs();
      await pumpIdentity(tester);

      expect(find.text('brewer@example.com'), findsOneWidget);
    });

    testWidgets('no email means no subtitle', (tester) async {
      await freshPrefs();
      await pumpIdentity(tester, email: null);

      expect(find.text('brewer@example.com'), findsNothing);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });

    testWidgets(
        'a cache change followed by the refresh signal shows the new name',
        (tester) async {
      final prefs = await freshPrefs({
        'user_display_name': 'Old Name',
        'user_display_name_user_id': 'user-1',
      });
      final signal = ValueNotifier<int>(0);
      addTearDown(signal.dispose);
      // Held open so the assertions below prove the cached name alone.
      final fetch = Completer<String?>();
      await pumpIdentity(
        tester,
        refreshSignal: signal,
        fetch: (userId) => fetch.future,
      );

      expect(find.text('Old Name'), findsOneWidget);

      // The account screen's rename path writes the name without the id key;
      // the id this widget wrote earlier stays valid for the same user.
      await prefs.setString('user_display_name', 'New Name');
      signal.value++;
      await tester.pump();
      await tester.pump();

      expect(find.text('New Name'), findsOneWidget);
      expect(find.text('Old Name'), findsNothing);

      fetch.complete('New Name'); // The server agrees after the rename.
      await tester.pump();
      await tester.pump();
      expect(find.text('New Name'), findsOneWidget);
    });
  });
}
