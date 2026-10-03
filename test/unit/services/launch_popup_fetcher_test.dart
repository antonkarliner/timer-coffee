import 'dart:async';
import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/launch_popup_fetcher.dart';
import 'package:coffee_timer/services/region_service.dart';
import 'package:coffee_timer/widgets/campaign_support_block.dart';
import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Plan 076 §3: launch popups come from `get_launch_popup` (audience
/// targeting), falling back to the direct read — which RLS limits to
/// untargeted popups — whenever the RPC fails.

const _rpcPath = '/rest/v1/rpc/get_launch_popup';
const _tablePath = '/rest/v1/launch_popup';

/// A campaign popup row as the RPC returns it. The audience columns are
/// included as if `select` had not trimmed them, to show they are ignored.
Map<String, Object?> _targetedRow() => {
  'id': 501,
  'content': 'Für unsere Leser in Deutschland.',
  'locale': 'de',
  'created_at': '2026-10-01T08:00:00+00:00',
  'platform': 'all',
  'hook_type': 'coffee_day',
  'goal_amount_usd': null,
  'progress_amount_usd': null,
  'campaign_ends_at': '2100-01-01T00:00:00+00:00',
  'title': 'Tag des Kaffees',
  'audience_filter': {
    'countries': ['DE'],
  },
  'visible_from': '2026-10-01T06:00:00+00:00',
};

Map<String, Object?> _untargetedRow() => {
  'id': 500,
  'content': 'Für alle.',
  'locale': 'de',
  'created_at': '2026-09-01T08:00:00+00:00',
  'platform': 'all',
  'hook_type': 'coffee_day',
  'goal_amount_usd': null,
  'progress_amount_usd': null,
  'campaign_ends_at': '2100-01-01T00:00:00+00:00',
  'title': 'Tag des Kaffees',
};

class _Backend {
  _Backend({this.rpc, this.table});

  /// Response for each endpoint; a [Future] lets a test delay it.
  final FutureOr<http.Response> Function()? rpc;
  final FutureOr<http.Response> Function()? table;
  final List<http.Request> requests = [];

  late final SupabaseClient client = SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    httpClient: MockClient((request) async {
      requests.add(request);
      final handler = switch (request.url.path) {
        _rpcPath => rpc,
        _tablePath => table,
        _ => null,
      };
      final response = handler == null
          ? http.Response('unexpected', 404)
          : await handler();
      // postgrest reads the originating request off the response.
      return http.Response.bytes(
        response.bodyBytes,
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  Iterable<http.Request> hitsOn(String path) =>
      requests.where((r) => r.url.path == path);
}

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('LaunchPopupFetcher', () {
    test('asks the RPC with the viewer locale, platform and geo', () async {
      final backend = _Backend(rpc: () => _json([_targetedRow()]));

      final row = await LaunchPopupFetcher(backend.client).fetch(
        locale: 'de',
        platform: 'ios',
        geo: const GeoLocation(country: 'DE', region: 'EU'),
      );

      expect(row?['id'], 501);
      final call = backend.hitsOn(_rpcPath).single;
      expect(call.method, 'POST');
      expect(jsonDecode(call.body), {
        'p_locale': 'de',
        'p_platform': 'ios',
        'p_country': 'DE',
        'p_region': 'EU',
      });
      expect(
        call.url.queryParameters['select'],
        LaunchPopupFetcher.columns.replaceAll(' ', ''),
      );
      expect(backend.hitsOn(_tablePath), isEmpty);
    });

    test('unknown geo is sent as null, not guessed', () async {
      final backend = _Backend(rpc: () => _json([]));

      await LaunchPopupFetcher(
        backend.client,
      ).fetch(locale: 'en', platform: 'android');

      final body = jsonDecode(backend.hitsOn(_rpcPath).single.body) as Map;
      expect(body['p_country'], isNull);
      expect(body['p_region'], isNull);
    });

    test('an empty RPC result is "no popup", with no fallback read', () async {
      final backend = _Backend(
        rpc: () => _json([]),
        table: () => _json([_untargetedRow()]),
      );

      final row = await LaunchPopupFetcher(
        backend.client,
      ).fetch(locale: 'de', platform: 'ios');

      expect(row, isNull);
      expect(backend.hitsOn(_tablePath), isEmpty);
    });

    test('a failing RPC falls back to the direct read', () async {
      final backend = _Backend(
        // What PostgREST answers before the migration reaches a database.
        rpc: () => _json({
          'code': 'PGRST202',
          'message': 'Could not find the function public.get_launch_popup',
        }, 404),
        table: () => _json([_untargetedRow()]),
      );

      final row = await LaunchPopupFetcher(
        backend.client,
      ).fetch(locale: 'de', platform: 'ios');

      expect(row?['id'], 500);
      final read = backend.hitsOn(_tablePath).single;
      expect(read.method, 'GET');
      expect(read.url.queryParameters['locale'], 'eq.de');
      expect(
        read.url.queryParameters['or'],
        '(platform.eq.ios,platform.eq.all)',
      );
      expect(read.url.queryParameters['order'], startsWith('created_at.desc'));
    });

    test('a slow RPC falls back within the same overall budget', () async {
      final backend = _Backend(
        rpc: () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return _json([_targetedRow()]);
        },
        table: () => _json([_untargetedRow()]),
      );

      final row = await LaunchPopupFetcher(
        backend.client,
        budget: const Duration(milliseconds: 600),
        rpcTimeout: const Duration(milliseconds: 100),
      ).fetch(locale: 'de', platform: 'ios');

      expect(row?['id'], 500);
    });

    test('throws only when the fallback fails too', () async {
      final backend = _Backend(
        rpc: () => _json({'message': 'boom'}, 500),
        table: () => _json({'message': 'boom'}, 500),
      );

      expect(
        LaunchPopupFetcher(backend.client).fetch(locale: 'de', platform: 'ios'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('a targeted popup renders like an untargeted one', () {
    setUp(() async {
      LaunchPopupWidget.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'launch_popup_first_session_done': true,
      });
      AnalyticsService.resetForTesting();
      await AnalyticsService.initialize(await SharedPreferences.getInstance());
    });

    tearDown(AnalyticsService.resetForTesting);

    Future<({String? title, bool campaignBlock, bool body})> render(
      WidgetTester tester,
      Map<String, Object?> row,
    ) async {
      final popup = LaunchPopupModel.fromMap(Map<String, dynamic>.from(row));
      LaunchPopupWidget.resetForTesting();
      // Drop the previous app (and its open dialog) before the next render.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: Scaffold(
            body: LaunchPopupWidget(
              key: UniqueKey(),
              fetchPopupOverride: (context, locale) async => popup,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      return (
        title: (dialog.title as Text?)?.data,
        campaignBlock: find.byType(CampaignSupportBlock).evaluate().isNotEmpty,
        body: find
            .textContaining(row['content'] as String, findRichText: true)
            .evaluate()
            .isNotEmpty,
      );
    }

    testWidgets('title, body and campaign block', (tester) async {
      final untargeted = await render(tester, _untargetedRow());
      final targeted = await render(tester, _targetedRow());

      expect(untargeted.title, 'Tag des Kaffees');
      expect(untargeted.campaignBlock, isTrue);
      expect(untargeted.body, isTrue);
      expect(targeted, untargeted);
    });
  });
}
