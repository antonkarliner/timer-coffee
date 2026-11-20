import 'dart:async';
import 'dart:convert';

import 'package:coffee_timer/config/network_timeouts.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/roaster_contribution/contribution_ack_banner.dart';
import 'package:coffee_timer/widgets/roaster_profile/review_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brew_flow_async_context_test.mocks.dart';

const _alice = 'test-alice';
const _bob = 'test-bob';
const _beanUuid = 'test-bean';

class _FormReviewProvider extends BeanReviewProvider {
  @override
  Future<List<BeanReviewModel>> fetchUserReviews() async => const [];
}

String _accessToken(String owner) {
  final claims = jsonEncode({
    'sub': owner,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  });
  final payload = base64Url.encode(utf8.encode(claims)).replaceAll('=', '');
  return 'test.$payload.signature';
}

Future<void> _switchTo(String owner) async {
  await Supabase.instance.client.auth.recoverSession(
    jsonEncode({
      'access_token': _accessToken(owner),
      'refresh_token': 'fake-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': owner,
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
}

http.Response _jsonResponse(Object? payload, [int status = 200]) =>
    http.Response(
      jsonEncode(payload),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _review(String owner) => {
  'id': 'review-$owner',
  'user_id': owner,
  'roaster_name': 'Test Roaster',
  'bean_name': 'Test Bean',
  'rating': 4,
  'review_text': 'Review by $owner',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: home,
);

void main() {
  late Future<http.Response> Function(http.Request) respond;
  late Future<FunctionResponse> Function(String) moderate;
  final moderatedTexts = <String>[];
  final requests = <http.Request>[];
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.test',
      anonKey: 'fake-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await respond(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          request: request,
          headers: response.headers,
        );
      }),
    );
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  setUp(() async {
    await _switchTo(_alice);
    requests.clear();
    moderatedTexts.clear();
    moderate = (_) async => throw StateError('Unexpected moderation call');
    respond = (request) async =>
        throw StateError('Unexpected request ${request.url.path}');
  });

  tearDownAll(() async {
    AnalyticsService.resetForTesting();
    await Supabase.instance.dispose();
  });

  Future<void> openForm(WidgetTester tester, {required bool edit}) async {
    final database = MockAppDatabase();
    final brewingMethods = MockBrewingMethodsDao();
    when(database.brewingMethodsDao).thenReturn(brewingMethods);
    when(brewingMethods.getAllBrewingMethods()).thenAnswer((_) async => []);

    final beans = MockCoffeeBeansProvider();
    when(beans.fetchAllCoffeeBeans()).thenAnswer(
      (_) async => [
        CoffeeBeansModel(
          beansUuid: _beanUuid,
          roaster: 'Test Roaster',
          name: 'Test Bean',
          origin: 'Origin',
          versionVector: '{}',
        ),
      ],
    );
    final provider = _FormReviewProvider();
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
          ChangeNotifierProvider<BeanReviewProvider>.value(value: provider),
        ],
        child: _app(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showReviewForm(
                  context,
                  roasterName: 'Test Roaster',
                  initialRating: 4,
                  moderateReview: (text) {
                    moderatedTexts.add(text);
                    return moderate(text);
                  },
                  existingReview: edit
                      ? BeanReviewModel.fromJson(_review(_alice))
                      : null,
                ),
                child: const Text('Open review'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
  }

  Finder comment() => find.descendant(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is LabeledField && widget.label == l10n.reviewTextLabel,
    ),
    matching: find.byType(TextField),
  );

  Future<void> enterComment(WidgetTester tester, String text) async {
    await tester.ensureVisible(comment());
    await tester.enterText(comment(), text);
    await tester.pump();
    expect(tester.widget<TextField>(comment()).controller!.text, text);
  }

  Future<void> submit(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.widgetWithText(
      AppElevatedButton,
      l10n.submitReviewButton,
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(tester.widget<AppElevatedButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pump();
  }

  List<Map<String, dynamic>> requestBodies(String pathSuffix) => requests
      .where((r) => r.url.path.endsWith(pathSuffix) && r.method != 'GET')
      .map((r) => jsonDecode(r.body) as Map<String, dynamic>)
      .toList();

  for (final edit in [false, true]) {
    final mode = edit ? 'edit' : 'create';

    for (final failure in [
      'timeout',
      'empty verdict',
      'non-success response',
    ]) {
      testWidgets('review $mode preserves the draft on moderation $failure', (
        tester,
      ) async {
        moderate = (_) async => switch (failure) {
          'timeout' => Completer<FunctionResponse>().future,
          'empty verdict' => FunctionResponse(status: 200),
          _ => FunctionResponse(status: 503, data: {'safe': true}),
        };
        await openForm(tester, edit: edit);
        await enterComment(tester, 'Keep this draft.');
        await submit(tester);
        if (failure == 'timeout') {
          await tester.pump(NetworkTimeouts.smallSync);
        }
        await tester.pumpAndSettle();

        expect(moderatedTexts, ['Keep this draft.']);
        expect(requestBodies('/bean_reviews'), isEmpty);
        expect(
          tester.widget<TextField>(comment()).controller!.text,
          'Keep this draft.',
        );
        expect(find.text(l10n.moderationErrorFunction), findsOneWidget);
      });
    }

    testWidgets(
      'review $mode requires fresh moderation when the comment changes',
      (tester) async {
        final firstVerdict = Completer<FunctionResponse>();
        final approved = FunctionResponse(status: 200, data: {'safe': true});
        moderate = (_) async =>
            moderatedTexts.length == 1 ? firstVerdict.future : approved;
        // Capture the publication payload without scheduling any review nudge.
        respond = (_) async => _jsonResponse(null, 503);
        await openForm(tester, edit: edit);
        await enterComment(tester, 'First draft.');
        await submit(tester);
        expect(moderatedTexts, ['First draft.']);
        // Apply the edit before releasing the verdict. Native text input can
        // deliver a pending platform update on a later frame.
        tester.widget<TextField>(comment()).controller!.text = 'Changed draft.';
        firstVerdict.complete(approved);
        await tester.pumpAndSettle();

        expect(requestBodies('/bean_reviews'), isEmpty);
        expect(
          tester.widget<TextField>(comment()).controller!.text,
          'Changed draft.',
        );

        await submit(tester);
        await tester.pumpAndSettle();
        expect(moderatedTexts, ['First draft.', 'Changed draft.']);
        expect(
          requestBodies('/bean_reviews').single['review_text'],
          'Changed draft.',
        );
        final write = requests.singleWhere(
          (r) => r.url.path.endsWith('/bean_reviews'),
        );
        expect(write.method, edit ? 'PATCH' : 'POST');
      },
    );
  }

  testWidgets('review approval cannot publish after an account switch', (
    tester,
  ) async {
    final verdict = Completer<FunctionResponse>();
    moderate = (_) => verdict.future;
    await openForm(tester, edit: false);
    await enterComment(tester, 'Account A draft.');
    await submit(tester);
    expect(moderatedTexts, ['Account A draft.']);
    await _switchTo(_bob);
    verdict.complete(FunctionResponse(status: 200, data: {'safe': true}));
    await tester.pumpAndSettle();
    expect(requestBodies('/bean_reviews'), isEmpty);
  });

  test(
    'own-review cache switches accounts and drops a late prior-account result',
    () async {
      final provider = BeanReviewProvider();
      addTearDown(provider.dispose);
      final pending = Completer<http.Response>();
      final requesting = Completer<void>();
      respond = (request) async {
        final owner = request.url.queryParameters['user_id']!.substring(3);
        final bean = request.url.queryParameters['coffee_beans_uuid'];
        if (bean == 'eq.late-bean' && owner == _alice) {
          requesting.complete();
          return pending.future;
        }
        return _jsonResponse([_review(owner)]);
      };

      expect(
        (await provider.fetchUserReviewByBeanUuid(_beanUuid))?.userId,
        _alice,
      );
      expect(provider.isUserBeanReviewCached(_beanUuid), isTrue);
      final late = provider.fetchUserReviewByBeanUuid('late-bean');
      await requesting.future;

      await _switchTo(_bob);
      expect(provider.isUserBeanReviewCached(_beanUuid), isFalse);
      expect(
        (await provider.fetchUserReviewByBeanUuid(_beanUuid))?.userId,
        _bob,
      );
      pending.complete(_jsonResponse([_review(_alice)]));
      expect(await late, isNull);
      expect(provider.isUserBeanReviewCached('late-bean'), isFalse);
      expect(
        (await provider.fetchUserReviewByBeanUuid(_beanUuid))?.userId,
        _bob,
      );
      expect(requests, hasLength(3));
    },
  );

  testWidgets(
    'contribution acknowledgement remount drops the late prior-account banner',
    (tester) async {
      final firstReply = Completer<http.Response>();
      final aliceToken =
          Supabase.instance.client.auth.currentSession!.accessToken;

      Map<String, dynamic> acknowledgement(int id, String roaster) => {
        'contribution_id': id,
        'roaster_name': roaster,
        'slug': 'roaster-$id',
      };

      respond = (request) async {
        if (request.url.path.endsWith(
          '/get_my_contribution_acknowledgements',
        )) {
          if (request.headers['authorization'] == 'Bearer $aliceToken') {
            return firstReply.future;
          }
          return _jsonResponse([acknowledgement(2, 'B Roaster')]);
        }
        return _jsonResponse(true);
      };

      Widget home(String owner) =>
          Scaffold(body: RoasterContributionAckBanner(key: ValueKey(owner)));

      await tester.pumpWidget(_app(home(_alice)));
      await tester.pump();
      expect(requests, hasLength(1));
      await _switchTo(_bob);
      await tester.pumpWidget(_app(home(_bob)));
      await tester.pumpAndSettle();
      firstReply.complete(_jsonResponse([acknowledgement(1, 'A Roaster')]));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.roasterContributionAckTitle('A Roaster')),
        findsNothing,
      );
      expect(
        find.text(l10n.roasterContributionAckTitle('B Roaster')),
        findsOneWidget,
      );
      final markRequests = requests
          .where((r) => r.url.path.endsWith('/mark_contribution_acknowledged'))
          .toList();
      expect(markRequests, hasLength(1));
      expect(jsonDecode(markRequests.single.body)['p_contribution_id'], 2);
      expect(
        markRequests.single.headers['authorization'],
        'Bearer ${Supabase.instance.client.auth.currentSession!.accessToken}',
      );
    },
  );
}
