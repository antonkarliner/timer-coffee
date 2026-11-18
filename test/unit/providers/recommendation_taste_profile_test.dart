import 'dart:async';

import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plan 086 Phase C: taste profile model, and the provider's load / optimistic
/// write / rollback / Never-filter behaviour. Hand-written fake, no Supabase.
class _FakeClient implements BeanRecommendationClient, TasteProfileClient {
  RecommendationResult? fetchResult;
  TasteProfile? profile;
  Object? profileError;
  Object? setError;
  Completer<void>? setGate;
  int profileFetchCount = 0;
  final List<(TasteDimension, String, TastePreference?)> setCalls = [];

  @override
  Future<RecommendationResult?> fetch({String? locale}) async => fetchResult;

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async => BeanRecommendationStatus.ok;

  @override
  Future<void> dismiss(String stockId) async {}

  @override
  Future<void> logReferredClick(String stockId, String surface) async {}

  @override
  Future<void> deleteMine() async {}

  @override
  Future<TasteProfile?> fetchTasteProfile() async {
    profileFetchCount++;
    if (profileError != null) throw profileError!;
    return profile;
  }

  @override
  Future<void> setTastePreference(
    TasteDimension dimension,
    String value,
    TastePreference? preference,
  ) async {
    setCalls.add((dimension, value, preference));
    final gate = setGate;
    if (gate != null) await gate.future;
    if (setError != null) throw setError!;
  }
}

Map<String, Object?> _profileJson({List<Object?> preferences = const []}) => {
  'origin': [
    {'value': 'KE', 'share': 0.2857},
    {'value': 'ET', 'share': 0.4286},
    {'value': 'co', 'share': 0.2857},
  ],
  'process': [
    {'value': 'washed', 'share': 0.5714},
    {'value': 'natural', 'share': '0.4286'},
  ],
  'roast': [
    {'value': 'light', 'share': 1},
  ],
  'flavor': [],
  'bean_count': 7,
  'brew_count': 12,
  'enough_history': true,
  'preferences': preferences,
};

BeanRecommendation _item(
  String id, {
  List<String> origins = const [],
  String? process,
  String? roast,
  List<String> flavors = const [],
}) => BeanRecommendation(
  stockId: id,
  beanName: 'Bean $id',
  roasterName: 'Roaster',
  originCountryCodes: origins,
  processFamily: process,
  roastLevel: roast,
  flavorFamilies: flavors,
);

void main() {
  group('TasteProfile.fromJson', () {
    test('parses distributions sorted by share, counts and preferences', () {
      final p = TasteProfile.fromJson(
        _profileJson(
          preferences: [
            {'dimension': 'origin', 'value': 'et', 'preference': 'never'},
            {'dimension': 'process', 'value': 'Natural', 'preference': 'less'},
          ],
        ),
      )!;
      expect(p.sharesFor(TasteDimension.origin).map((s) => s.value), [
        'ET',
        'KE',
        'CO',
      ]);
      expect(p.sharesFor(TasteDimension.process)[1].share, 0.4286);
      expect(p.sharesFor(TasteDimension.roast).single.share, 1.0);
      expect(p.sharesFor(TasteDimension.flavor), isEmpty);
      expect(p.beanCount, 7);
      expect(p.brewCount, 12);
      expect(p.enoughHistory, isTrue);
      expect(
        p.preferenceFor(TasteDimension.origin, 'et'),
        TastePreference.never,
      );
      expect(
        p.preferenceFor(TasteDimension.process, 'natural'),
        TastePreference.less,
      );
      expect(p.neverValues(TasteDimension.origin), {'ET'});
    });

    test('returns null for non-objects and skips malformed entries', () {
      expect(TasteProfile.fromJson(null), isNull);
      expect(TasteProfile.fromJson('nope'), isNull);
      final p = TasteProfile.fromJson({
        'origin': [
          'x',
          {'value': '', 'share': 0.5},
          {'value': 'BR'},
          {'value': 'BR', 'share': 0.5},
        ],
        'process': 'not a list',
        'bean_count': '3',
        'enough_history': 'yes',
        'preferences': [
          {'dimension': 'smell', 'value': 'x', 'preference': 'more'},
          {'dimension': 'roast', 'value': 'dark', 'preference': 'love'},
          {'dimension': 'roast', 'value': 'dark', 'preference': 'never'},
        ],
      })!;
      expect(p.sharesFor(TasteDimension.origin).single.value, 'BR');
      expect(p.sharesFor(TasteDimension.process), isEmpty);
      expect(p.beanCount, 0);
      expect(p.enoughHistory, isFalse);
      expect(p.preferences, hasLength(1));
    });

    test('withPreference sets, replaces and clears one entry', () {
      final base = TasteProfile.fromJson(_profileJson())!;
      final more = base.withPreference(
        TasteDimension.origin,
        'rw',
        TastePreference.more,
      );
      expect(
        more.preferenceFor(TasteDimension.origin, 'RW'),
        TastePreference.more,
      );
      final never = more.withPreference(
        TasteDimension.origin,
        'RW',
        TastePreference.never,
      );
      expect(never.preferences, hasLength(1));
      expect(
        never.preferenceFor(TasteDimension.origin, 'RW'),
        TastePreference.never,
      );
      final cleared = never.withPreference(TasteDimension.origin, 'RW', null);
      expect(cleared.preferences, isEmpty);
      expect(base.preferences, isEmpty, reason: 'original untouched');
    });
  });

  group('RecommendationProvider taste profile', () {
    late SharedPreferences prefs;
    late _FakeClient client;
    late RecommendationProvider provider;
    String? userId;
    var notifications = 0;

    Future<void> settle() async {
      for (var i = 0; i < 25; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      userId = 'user-1';
      notifications = 0;
      client = _FakeClient()..profile = TasteProfile.fromJson(_profileJson());
      provider = RecommendationProvider(
        client: client,
        currentUserId: () => userId,
        featureFlagEnabled: () => true,
        countryCodeLookup: (_) async => 'DE',
        prefs: prefs,
        debugMode: true,
      )..addListener(() => notifications++);
    });

    tearDown(() => provider.dispose());

    Future<void> loadPicks(List<BeanRecommendation> items) async {
      client.fetchResult = RecommendationResult(
        hasRecommendations: true,
        items: items,
      );
      await provider.ensureLoaded('en');
      await settle();
      expect(provider.state, RecommendationState.ready);
    }

    test(
      'uses the main client as taste client when it implements it',
      () async {
        await provider.loadTasteProfile();
        expect(provider.tasteProfileState, TasteProfileLoadState.ready);
        expect(provider.tasteProfile!.beanCount, 7);
        expect(client.profileFetchCount, 1);
      },
    );

    test('concurrent loads share one request', () async {
      await Future.wait([
        provider.loadTasteProfile(),
        provider.loadTasteProfile(),
      ]);
      expect(client.profileFetchCount, 1);
    });

    test('load error and null answer become error state', () async {
      client.profileError = Exception('offline');
      await provider.loadTasteProfile();
      expect(provider.tasteProfileState, TasteProfileLoadState.error);
      expect(provider.tasteProfile, isNull);

      client
        ..profileError = null
        ..profile = null;
      await provider.loadTasteProfile();
      expect(provider.tasteProfileState, TasteProfileLoadState.error);
    });

    test('no user means error without a request', () async {
      userId = null;
      await provider.loadTasteProfile();
      expect(provider.tasteProfileState, TasteProfileLoadState.error);
      expect(client.profileFetchCount, 0);
    });

    test('a different user does not see the previous profile', () async {
      await provider.loadTasteProfile();
      userId = 'user-2';
      expect(provider.tasteProfile, isNull);
      expect(provider.tasteProfileState, TasteProfileLoadState.idle);
    });

    test('write shows at once and normalises the value', () async {
      await provider.loadTasteProfile();
      client.setGate = Completer<void>();
      final write = provider.setTastePreference(
        TasteDimension.origin,
        ' rw ',
        TastePreference.more,
      );
      expect(
        provider.tasteProfile!.preferenceFor(TasteDimension.origin, 'RW'),
        TastePreference.more,
        reason: 'optimistic before the server answers',
      );
      client.setGate!.complete();
      expect(await write, TastePreferenceWriteResult.ok);
      expect(client.setCalls.single, (
        TasteDimension.origin,
        'RW',
        TastePreference.more,
      ));
    });

    test('setting the current value again makes no request', () async {
      client.profile = TasteProfile.fromJson(
        _profileJson(
          preferences: [
            {'dimension': 'roast', 'value': 'dark', 'preference': 'never'},
          ],
        ),
      );
      await provider.loadTasteProfile();
      final r = await provider.setTastePreference(
        TasteDimension.roast,
        'dark',
        TastePreference.never,
      );
      expect(r, TastePreferenceWriteResult.ok);
      expect(client.setCalls, isEmpty);
    });

    test('failure rolls back to the previous preference', () async {
      client.profile = TasteProfile.fromJson(
        _profileJson(
          preferences: [
            {'dimension': 'process', 'value': 'natural', 'preference': 'less'},
          ],
        ),
      );
      await provider.loadTasteProfile();
      client.setError = Exception('500');
      final r = await provider.setTastePreference(
        TasteDimension.process,
        'natural',
        TastePreference.never,
      );
      expect(r, TastePreferenceWriteResult.failed);
      expect(
        provider.tasteProfile!.preferenceFor(TasteDimension.process, 'natural'),
        TastePreference.less,
      );
    });

    test('a failed clear restores the cleared preference', () async {
      client.profile = TasteProfile.fromJson(
        _profileJson(
          preferences: [
            {'dimension': 'origin', 'value': 'ET', 'preference': 'more'},
          ],
        ),
      );
      await provider.loadTasteProfile();
      client.setError = Exception('offline');
      await provider.setTastePreference(TasteDimension.origin, 'ET', null);
      expect(
        provider.tasteProfile!.preferenceFor(TasteDimension.origin, 'ET'),
        TastePreference.more,
      );
    });

    test('the 60-row cap reports limitReached and rolls back', () async {
      await provider.loadTasteProfile();
      client.setError = const TastePreferenceLimitException();
      final r = await provider.setTastePreference(
        TasteDimension.flavor,
        'berry',
        TastePreference.more,
      );
      expect(r, TastePreferenceWriteResult.limitReached);
      expect(provider.tasteProfile!.preferences, isEmpty);
    });

    test('an older failed write does not undo a newer one', () async {
      await provider.loadTasteProfile();
      client.setGate = Completer<void>();
      client.setError = Exception('first fails');
      final first = provider.setTastePreference(
        TasteDimension.origin,
        'KE',
        TastePreference.more,
      );
      final second = provider.setTastePreference(
        TasteDimension.origin,
        'KE',
        TastePreference.never,
      );
      client.setGate!.complete();
      await first;
      await second;
      // Both failed: the display returns to what the server holds (nothing),
      // not to the first write's optimistic More.
      expect(
        provider.tasteProfile!.preferenceFor(TasteDimension.origin, 'KE'),
        isNull,
      );
    });

    test(
      'an older write failing after a newer success keeps the newer one',
      () async {
        await provider.loadTasteProfile();
        final gate1 = Completer<void>();
        client.setGate = gate1;
        client.setError = Exception('first fails');
        final first = provider.setTastePreference(
          TasteDimension.origin,
          'KE',
          TastePreference.more,
        );
        client
          ..setGate = null
          ..setError = null;
        expect(
          await provider.setTastePreference(
            TasteDimension.origin,
            'KE',
            TastePreference.never,
          ),
          TastePreferenceWriteResult.ok,
        );
        client.setError = Exception('first fails');
        gate1.complete();
        expect(await first, TastePreferenceWriteResult.failed);
        expect(
          provider.tasteProfile!.preferenceFor(TasteDimension.origin, 'KE'),
          TastePreference.never,
        );
      },
    );

    test('a write before the profile loaded fails without a request', () async {
      final r = await provider.setTastePreference(
        TasteDimension.origin,
        'KE',
        TastePreference.more,
      );
      expect(r, TastePreferenceWriteResult.failed);
      expect(client.setCalls, isEmpty);
    });

    test('a successful Never drops matching picks like the server', () async {
      await loadPicks([
        _item('et-only', origins: ['ET']),
        _item('blend', origins: ['ET', 'CO']),
        _item('natural', origins: ['CO'], process: 'natural'),
        _item('berry', origins: ['KE'], flavors: ['citrus', 'berry']),
        _item('keep', origins: ['KE'], process: 'washed', roast: 'light'),
      ]);
      await provider.loadTasteProfile();

      await provider.setTastePreference(
        TasteDimension.origin,
        'et',
        TastePreference.never,
      );
      expect(provider.items.map((i) => i.stockId), [
        'blend',
        'natural',
        'berry',
        'keep',
      ], reason: 'a blend with one allowed origin stays');

      await provider.setTastePreference(
        TasteDimension.process,
        'natural',
        TastePreference.never,
      );
      await provider.setTastePreference(
        TasteDimension.flavor,
        'berry',
        TastePreference.never,
      );
      expect(provider.items.map((i) => i.stockId), ['blend', 'keep']);
      expect(provider.state, RecommendationState.ready);
    });

    test(
      'Never on every pick hides the card; More and Less drop nothing',
      () async {
        await loadPicks([_item('a', roast: 'dark'), _item('b', roast: 'dark')]);
        await provider.loadTasteProfile();

        await provider.setTastePreference(
          TasteDimension.roast,
          'dark',
          TastePreference.less,
        );
        expect(provider.items, hasLength(2));

        await provider.setTastePreference(
          TasteDimension.roast,
          'dark',
          TastePreference.never,
        );
        expect(provider.items, isEmpty);
        expect(provider.state, RecommendationState.hidden);
      },
    );

    test('a failed Never keeps the picks', () async {
      await loadPicks([
        _item('a', origins: ['ET']),
      ]);
      await provider.loadTasteProfile();
      client.setError = Exception('offline');
      await provider.setTastePreference(
        TasteDimension.origin,
        'ET',
        TastePreference.never,
      );
      expect(provider.items, hasLength(1));
    });

    test('notifies on load and on each optimistic change', () async {
      await provider.loadTasteProfile();
      final before = notifications;
      await provider.setTastePreference(
        TasteDimension.origin,
        'CO',
        TastePreference.more,
      );
      expect(notifications, greaterThan(before));
    });
  });
}
