import 'dart:async';
import 'dart:convert';

import 'package:coffee_timer/app_router.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FeatureFlagsSource extends SupabaseFeatureFlagsDataSource {
  _FeatureFlagsSource(super.client);

  Map<String, bool> nextFlags = {};

  @override
  Future<Map<String, bool>> fetchFlags({
    required String platform,
    required int buildNumber,
  }) async => nextFlags;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('flush', () {
    late AnalyticsService service;

    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      service = await AnalyticsService.initialize(prefs);
    });

    test('serializes sends and flushes events tracked during a send', () async {
      final firstSend = Completer<void>();
      final batches = <List<Map<String, dynamic>>>[];
      AnalyticsService.sendOverride = (events) async {
        batches.add(events);
        if (batches.length == 1) await firstSend.future;
      };

      service.track('app_opened');
      final firstFlush = service.flushNow();
      service.track('screen_viewed');
      final nextFlush = service.flushNow();

      expect(batches, hasLength(1));
      expect(batches.single.single['event_name'], 'app_opened');
      firstSend.complete();
      await Future.wait([firstFlush, nextFlush]);

      expect(batches, hasLength(2));
      expect(batches[1].single['event_name'], 'screen_viewed');
      expect(service.bufferLength, 0);
    });

    test('flushNow waits until the follow-up send completes', () async {
      final firstSend = Completer<void>();
      final secondSend = Completer<void>();
      final secondStarted = Completer<void>();
      var sends = 0;
      AnalyticsService.sendOverride = (_) {
        sends++;
        if (sends == 1) return firstSend.future;
        secondStarted.complete();
        return secondSend.future;
      };

      service.track('app_opened');
      final firstFlush = service.flushNow();
      service.track('screen_viewed');
      var completed = false;
      final waitingFlush = service.flushNow().then((_) => completed = true);

      firstSend.complete();
      await secondStarted.future;
      // Give an incorrectly completed flush future a chance to notify callers.
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(service.bufferLength, 1);

      secondSend.complete();
      await waitingFlush;
      await firstFlush;
      expect(completed, isTrue);
      expect(service.bufferLength, 0);
    });

    test('failure keeps events buffered without an immediate follow-up', () async {
      final firstSend = Completer<void>();
      var sends = 0;
      AnalyticsService.sendOverride = (_) {
        sends++;
        return firstSend.future;
      };

      service.track('app_opened');
      final firstFlush = service.flushNow();
      service.track('screen_viewed');
      final waitingFlush = service.flushNow();
      firstSend.completeError(StateError('offline'));
      await Future.wait([firstFlush, waitingFlush]);

      expect(sends, 1);
      expect(service.bufferLength, 2);

      // A later explicit flush can retry after the failed drain has ended.
      AnalyticsService.sendOverride = (_) async {
        sends++;
      };
      await service.flushNow();
      expect(sends, 2);
      expect(service.bufferLength, 0);
    });

    test('purges revoked events and preserves unrelated events in flight', () async {
      final firstSend = Completer<void>();
      final batches = <List<Map<String, dynamic>>>[];
      AnalyticsService.sendOverride = (events) async {
        batches.add(events);
        if (batches.length == 1) await firstSend.future;
      };

      service.track('app_opened');
      service.track('beans_added');
      final firstFlush = service.flushNow();
      service.track('screen_viewed');
      service.track('review_added');
      await service.setBeansEnabled(false);
      await service.setBeansEnabled(true);
      final nextFlush = service.flushNow();
      firstSend.complete();
      await Future.wait([firstFlush, nextFlush]);

      expect(batches.map((batch) => batch.map((e) => e['event_name'])), [
        ['app_opened', 'beans_added'],
        ['screen_viewed'],
      ]);
      expect(service.bufferLength, 0);
    });

    test('filters categories before retrying a failed upload', () async {
      service.track('app_opened');
      service.track('beans_added');
      AnalyticsService.sendOverride = (_) async => throw StateError('offline');
      await service.flushNow();

      await service.setGeneralEnabled(false);
      AnalyticsService.sendOverride = (events) async {
        expect(events.single['event_name'], 'beans_added');
      };
      await service.flushNow();
      expect(service.bufferLength, 0);
    });
  });

  test('canonical kill switch applies to cached and newly refreshed flags', () async {
    SharedPreferences.setMockInitialValues({
      'feature_flags_v1': '{"analytics_enabled":false}',
    });
    final prefs = await SharedPreferences.getInstance();
    final client = SupabaseClient('http://localhost:54321', 'public-api-key');
    final remote = _FeatureFlagsSource(client);
    final flags = FeatureFlagsRepository(
      remote: remote,
      local: LocalFeatureFlagsStore(prefs),
      platform: 'ios',
      buildNumber: 1,
    );
    addTearDown(client.dispose);
    addTearDown(flags.dispose);
    final service = await AnalyticsService.initialize(prefs, featureFlags: flags);
    final sent = <Map<String, dynamic>>[];
    AnalyticsService.sendOverride = (events) async => sent.addAll(events);
    service.track('app_opened');
    await service.flushNow();
    expect(sent, isEmpty);

    remote.nextFlags = {FeatureFlagKeys.analyticsEnabled: true};
    await flags.refresh();
    service.track('app_opened');
    expect(service.bufferLength, 1);
    remote.nextFlags = {FeatureFlagKeys.analyticsEnabled: false};
    await flags.refresh();
    service.track('screen_viewed');
    await service.flushNow();
    expect(sent, isEmpty);
    expect(service.bufferLength, 0);
    expect(service.canTrackBeans, isFalse);
  });

  test('outbound batch has only public request credentials and safe properties', () async {
    final prefs = await SharedPreferences.getInstance();
    await Supabase.initialize(
      url: 'https://account.example',
      anonKey: 'public-api-key',
      httpClient: MockClient((_) async => throw StateError('unexpected account request')),
    );
    addTearDown(Supabase.instance.dispose);
    const account = '9a70f08d-282e-4e47-95ba-72c365097733';
    const bean = 'd44fd27b-ae7b-4fca-9813-99cc786921e0';
    final expiry = DateTime.now().add(const Duration(hours: 1));
    final claims = base64Url.encode(utf8.encode(jsonEncode({
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
      'sub': account,
      'role': 'authenticated',
    }))).replaceAll('=', '');
    final token = 'header.$claims.signature';
    await Supabase.instance.client.auth.recoverSession(jsonEncode({
      'access_token': token,
      'expires_in': 3600,
      'refresh_token': 'offline-test-refresh',
      'token_type': 'bearer',
      'user': {
        'id': account,
        'aud': 'authenticated',
        'app_metadata': {'provider': 'email'},
        'user_metadata': <String, dynamic>{},
        'created_at': DateTime.now().toIso8601String(),
      },
    }));
    expect(Supabase.instance.client.auth.currentSession?.accessToken, token);

    final service = await AnalyticsService.initialize(
      prefs,
      ingestionBaseUrl: 'https://telemetry.example',
      publicApiKey: 'public-api-key',
      catalogRecipeIds: const ['1101'],
    );
    final requests = <http.Request>[];
    AnalyticsService.httpClientFactory = () => MockClient((request) async {
      requests.add(request);
      return http.Response('', 202);
    });
    for (final (event, recipeId) in [
      ('brew_started', 'usr-$account-1730000000000'),
      ('diary_brew_again_tapped', 'usr-$account-1730000000001'),
      ('recipe_shared', account),
      ('recipe_shared', '9999'),
      ('brew_started', '1101'),
    ]) {
      service.track(event, properties: {'recipe_id': recipeId});
    }
    for (final event in [
      'review_added', 'review_edited', 'review_deleted', 'review_nudge_card_shown',
      'review_added_after_notification',
    ]) {
      service.track(event, properties: {'bean_uuid': bean, 'review_id': account});
    }
    final reviews = service.bufferedEventsForTesting.where((event) =>
        event['category'] == 'beans');
    expect(reviews, hasLength(5));
    expect(reviews.every((event) => !event.containsKey('properties')), isTrue);
    await service.setBeansEnabled(false);
    for (final event in [
      'notification_scheduled', 'notification_presumed_delivered',
      'notification_cancelled', 'notification_tapped',
    ]) {
      service.track(event, properties: {
        'notification_type': 'bean_freshness',
        'trigger': 'rest',
        'bean_uuid': bean,
        'unexpected_field': {'bean_id': bean},
      });
    }
    final accountPath = '/user/$account';
    final accountRoute = AppRouter().buildPageRoutesStack(accountPath)?.last;
    expect(accountRoute?.routeName, AccountRoute.name);
    service.track('onboarding_completed', properties: {
      'completion_type': 'deep_link_skipped',
      'path': accountPath,
      'screen_name': accountRoute?.routeName,
    });
    await service.flushNow();

    final request = requests.single;
    expect(request.url.path, '/functions/v1/ingest-analytics');
    expect(request.headers['apikey'], 'public-api-key');
    expect(request.headers['authorization'], isNull);
    expect(request.body, isNot(contains(account)));
    expect(request.body, isNot(contains(bean)));
    final rows = (jsonDecode(request.body) as Map)['events'] as List;
    expect(rows.take(5).map((event) => event['properties']['recipe_id']), [
      'custom-recipe', 'custom-recipe', 'custom-recipe', 'custom-recipe', '1101',
    ]);
    expect(rows.where((event) => event['event_name'].startsWith('notification_'))
      .map((event) => event['properties']), everyElement({
        'notification_type': 'bean_freshness', 'trigger': 'rest',
      }));
    expect(rows.last['properties'], {
      'completion_type': 'deep_link_skipped',
      'screen_name': AccountRoute.name,
    });
  });

  test('2025 recap events obey general analytics and use the normal queue', () async {
    final service = await AnalyticsService.initialize(
      await SharedPreferences.getInstance(),
    );
    const eventNames = ['year_story_opened', 'year_story_last_slide_viewed'];
    final sent = <Map<String, dynamic>>[];
    AnalyticsService.sendOverride = (events) async => sent.addAll(events);
    await service.setGeneralEnabled(false);
    for (final event in eventNames) {
      service.track(event, properties: {'year': 2025});
    }
    await service.flushNow();
    expect(sent, isEmpty);
    await service.setGeneralEnabled(true);
    for (final event in eventNames) {
      service.track(event, properties: {'year': 2025});
    }
    await service.flushNow();
    expect(sent.map((event) => event['event_name']), eventNames);
    expect(sent.map((event) => event['category']), everyElement('general'));
  });

  group('initialization', () {
    test('creates singleton instance', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);
      expect(service, isNotNull);
      expect(AnalyticsService.instance, same(service));
    });

    test('generates and persists installId', () async {
      final prefs = await SharedPreferences.getInstance();
      await AnalyticsService.initialize(prefs);

      final installId = AnalyticsService.instance.installId;
      expect(installId, isNotEmpty);

      // Verify it persists
      expect(prefs.getString('analytics_install_id'), installId);
    });

    test('installId persists across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      await AnalyticsService.initialize(prefs);
      final firstInstallId = AnalyticsService.instance.installId;

      // Reset and reinitialize
      AnalyticsService.resetForTesting();
      await AnalyticsService.initialize(prefs);
      final secondInstallId = AnalyticsService.instance.installId;

      expect(secondInstallId, equals(firstInstallId));
    });

    test('maybeInstance is null before init, non-null after', () async {
      expect(AnalyticsService.maybeInstance, isNull);
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);
      expect(AnalyticsService.maybeInstance, same(service));
    });

    test('all categories enabled by default', () async {
      final prefs = await SharedPreferences.getInstance();
      await AnalyticsService.initialize(prefs);

      expect(AnalyticsService.instance.brewsEnabled, isTrue);
      expect(AnalyticsService.instance.beansEnabled, isTrue);
      expect(AnalyticsService.instance.generalEnabled, isTrue);
    });
  });

  group('track()', () {
    late AnalyticsService service;

    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      service = await AnalyticsService.initialize(prefs);
    });

    test('adds event to buffer', () {
      service.track('brew_started', properties: {'recipe_id': 'test-123'});
      expect(service.bufferLength, 1);
    });

    test('adds multiple events', () {
      service.track('brew_started');
      service.track('brew_completed');
      expect(service.bufferLength, 2);
    });

    test('ignores unknown event names', () {
      service.track('unknown_event_that_does_not_exist');
      expect(service.bufferLength, 0);
    });

    test('is no-op when category disabled (brews)', () async {
      await service.setBrewsEnabled(false);
      service.track('brew_started');
      service.track('brew_completed');
      service.track('brew_abandoned');
      expect(service.bufferLength, 0);
    });

    test('registers brew diary events (brews category)', () {
      service.track(
        'manual_brew_logged',
        properties: {
          'brewing_method_id': 'v60',
          'has_bean': true,
          'has_grind': false,
          'has_temp': true,
          'has_rating': false,
          'has_notes': false,
          'has_tags': true,
        },
      );
      service.track(
        'diary_entry_opened',
        properties: {'source': 'card', 'entry_source': 'timer'},
      );
      service.track(
        'diary_entry_edited',
        properties: {'field': 'rating', 'entry_source': 'manual'},
      );
      service.track('diary_entry_deleted', properties: {
        'entry_source': 'manual',
      });
      service.track(
        'diary_bookmark_toggled',
        properties: {'bookmarked': true, 'source': 'card'},
      );
      service.track(
        'diary_brew_again_tapped',
        properties: {'source': 'sheet', 'recipe_id': 'recipe-1'},
      );
      service.track(
        'diary_search_used',
        properties: {'query_length': 5, 'result_count': 2},
      );
      service.track(
        'diary_filters_changed',
        properties: {'source': 'chip', 'result_count': 4},
      );
      service.track('diary_axis_changed', properties: {'axis': 'by_bean'});
      service.track('diary_compare_opened', properties: {'series_length': 3});
      service.track(
        'diary_month_strip_used',
        properties: {'action': 'expand'},
      );
      service.track(
        'diary_extraction_opened',
        properties: {'mode': 'calculate'},
      );

      final events = service.bufferedEventsForTesting;
      expect(events.map((event) => event['event_name']).toList(), [
        'manual_brew_logged',
        'diary_entry_opened',
        'diary_entry_edited',
        'diary_entry_deleted',
        'diary_bookmark_toggled',
        'diary_brew_again_tapped',
        'diary_search_used',
        'diary_filters_changed',
        'diary_axis_changed',
        'diary_compare_opened',
        'diary_month_strip_used',
        'diary_extraction_opened',
      ]);
      expect(events.every((event) => event['category'] == 'brews'), isTrue);
    });

    test('is no-op when category disabled (brews) for diary events', () async {
      await service.setBrewsEnabled(false);
      service.track('manual_brew_logged');
      service.track('diary_entry_opened');
      service.track('diary_entry_edited');
      service.track('diary_entry_deleted');
      service.track('diary_bookmark_toggled');
      service.track('diary_brew_again_tapped');
      service.track('diary_search_used');
      service.track('diary_filters_changed');
      service.track('diary_axis_changed');
      service.track('diary_compare_opened');
      service.track('diary_month_strip_used');
      service.track('diary_extraction_opened');
      expect(service.bufferLength, 0);
    });

    test(
      'registers brew completion integrity events (brews category, plan 042)',
      () {
        service.track(
          'brew_finished',
          properties: {
            'recipe_id': 'recipe-1',
            'total_steps': 3,
            'completion_path': 'timer',
          },
        );
        service.track(
          'last_step_reached',
          properties: {
            'recipe_id': 'recipe-1',
            'total_steps': 3,
            'step_duration_seconds': 30,
          },
        );
        service.track(
          'last_step_skipped',
          properties: {
            'recipe_id': 'recipe-1',
            'total_steps': 3,
            'seconds_into_step': 5,
            'seconds_remaining': 25,
          },
        );

        final events = service.bufferedEventsForTesting;
        expect(events.map((event) => event['event_name']).toList(), [
          'brew_finished',
          'last_step_reached',
          'last_step_skipped',
        ]);
        expect(events.every((event) => event['category'] == 'brews'), isTrue);

        final finishedProperties =
            events.first['properties'] as Map<String, dynamic>;
        expect(finishedProperties['completion_path'], 'timer');

        final skippedProperties =
            events.last['properties'] as Map<String, dynamic>;
        expect(skippedProperties['seconds_remaining'], 25);
      },
    );

    test(
      'is no-op when category disabled (brews) for plan 042 completion events',
      () async {
        await service.setBrewsEnabled(false);
        service.track('brew_finished');
        service.track('last_step_reached');
        service.track('last_step_skipped');
        expect(service.bufferLength, 0);
      },
    );

    test(
      'is no-op when global kill switch is on (plan 042 completion events)',
      () {
        service.setGlobalKillSwitch(true);
        service.track('brew_finished');
        service.track('last_step_reached');
        service.track('last_step_skipped');
        expect(service.bufferLength, 0);
      },
    );

    test('is no-op when category disabled (beans)', () async {
      await service.setBeansEnabled(false);
      service.track('beans_added');
      service.track('beans_scan_used');
      service.track('beans_attached');
      service.track('review_form_opened');
      service.track('review_added');
      service.track('review_added_after_notification');
      service.track('review_edited');
      service.track('review_deleted');
      service.track('review_translated');
      service.track('reviews_translated_batch');
      expect(service.bufferLength, 0);
    });

    test('registers new bean review events (beans category)', () {
      service.track('review_form_opened', properties: {'mode': 'create'});
      service.track('review_edited', properties: {'rating': 4});
      service.track('review_deleted');
      service.track('review_translated', properties: {'status': 'translated'});
      service.track(
        'reviews_translated_batch',
        properties: {'requested_count': 3, 'succeeded_count': 2},
      );
      // All five are known beans events, so all should buffer.
      expect(service.bufferLength, 5);
    });

    test('is no-op when category disabled (general)', () async {
      await service.setGeneralEnabled(false);
      service.track('app_opened');
      service.track('screen_viewed');
      service.track('donation_screen_viewed');
      service.track('notification_scheduled');
      service.track('notification_tapped');
      service.track('beta_feature_toggled');
      service.track('collection_card_tapped');
      service.track('collection_detail_viewed');
      service.track('collection_recipe_tapped');
      service.track('collection_shared');
      service.track('collections_section_toggled');
      service.track('collections_visibility_changed');
      expect(service.bufferLength, 0);
    });

    test('registers collection funnel events (general category)', () {
      service.track(
        'collection_card_tapped',
        properties: {
          'collection_id': 'summer-iced',
          'source': 'home_carousel',
          'card_index': 0,
          'collection_count': 3,
        },
      );
      service.track(
        'collection_detail_viewed',
        properties: {
          'collection_id': 'summer-iced',
          'locale': 'en',
          'recipe_count': 4,
        },
      );
      service.track(
        'collection_recipe_tapped',
        properties: {
          'collection_id': 'summer-iced',
          'recipe_id': 'recipe-123',
          'brewing_method_id': 'v60',
          'locale': 'en',
          'recipe_index': 1,
          'recipe_count': 4,
        },
      );
      service.track(
        'collection_shared',
        properties: {
          'collection_id': 'summer-iced',
          'source': 'collection_detail',
        },
      );
      service.track(
        'collections_section_toggled',
        properties: {'collapsed': true, 'collection_count': 3},
      );
      service.track(
        'collections_visibility_changed',
        properties: {'visible': false, 'source': 'settings_home_screen'},
      );

      final events = service.bufferedEventsForTesting;
      expect(events.map((event) => event['event_name']).toList(), [
        'collection_card_tapped',
        'collection_detail_viewed',
        'collection_recipe_tapped',
        'collection_shared',
        'collections_section_toggled',
        'collections_visibility_changed',
      ]);
      expect(events.every((event) => event['category'] == 'general'), isTrue);

      final cardProperties = events.first['properties'] as Map<String, dynamic>;
      expect(cardProperties['collection_id'], 'summer-iced');
      expect(cardProperties['source'], 'home_carousel');
      expect(cardProperties['card_index'], 0);
      expect(cardProperties['collection_count'], 3);

      final recipeProperties = events[2]['properties'] as Map<String, dynamic>;
      expect(recipeProperties['recipe_id'], 'custom-recipe');
      expect(recipeProperties['brewing_method_id'], 'v60');
      expect(recipeProperties['recipe_index'], 1);
    });

    test('registers roaster profile events (general category)', () {
      service.track(
        'roaster_profile_viewed',
        properties: {
          'roaster_slug': 'acme-coffee',
          'roaster_name': 'Acme Coffee',
          'roaster_id': 'roaster-1',
          'verified': true,
        },
      );
      service.track(
        'roaster_link_tapped',
        properties: {
          'link_type': 'website',
          'roaster_slug': 'acme-coffee',
          'roaster_name': 'Acme Coffee',
          'roaster_id': 'roaster-1',
        },
      );

      final events = service.bufferedEventsForTesting;
      expect(events.map((event) => event['event_name']).toList(), [
        'roaster_profile_viewed',
        'roaster_link_tapped',
      ]);
      expect(events.every((event) => event['category'] == 'general'), isTrue);

      final tapProperties = events[1]['properties'] as Map<String, dynamic>;
      expect(tapProperties['link_type'], 'website');
      expect(tapProperties['roaster_slug'], 'acme-coffee');
    });

    test('registers moment events (general category)', () {
      service.track(
        'moment_shown',
        properties: {
          'moment_id': 'in_sync',
          'in_sync_count': 5,
          'country_count': 3,
        },
      );
      service.track(
        'moment_interacted',
        properties: {'moment_id': 'anniversary', 'action': 'open_diary'},
      );
      service.track('moment_discovered', properties: {'moment_id': 'coffee_day'});

      final events = service.bufferedEventsForTesting;
      expect(events.map((event) => event['event_name']).toList(), [
        'moment_shown',
        'moment_interacted',
        'moment_discovered',
      ]);
      expect(events.every((event) => event['category'] == 'general'), isTrue);

      final shownProperties = events.first['properties'] as Map<String, dynamic>;
      expect(shownProperties['moment_id'], 'in_sync');
      expect(shownProperties['in_sync_count'], 5);
      expect(shownProperties['country_count'], 3);
    });

    test('is no-op for moment events when general category disabled', () async {
      await service.setGeneralEnabled(false);
      service.track('moment_shown', properties: {'moment_id': 'in_sync'});
      service.track('moment_interacted',
          properties: {'moment_id': 'coffee_day', 'action': 'dismiss'});
      service.track('moment_discovered', properties: {'moment_id': 'in_sync'});
      expect(service.bufferLength, 0);
    });

    test('registers notification_setting_toggled (general category)', () {
      service.track(
        'notification_setting_toggled',
        properties: {
          'setting': 'master',
          'enabled': true,
          'source': 'user',
        },
      );

      final events = service.bufferedEventsForTesting;
      expect(events.map((event) => event['event_name']).toList(),
          ['notification_setting_toggled']);
      expect(events.every((event) => event['category'] == 'general'), isTrue);

      final properties = events.first['properties'] as Map<String, dynamic>;
      expect(properties['setting'], 'master');
      expect(properties['enabled'], isTrue);
      expect(properties['source'], 'user');
    });

    test(
        'is no-op for notification_setting_toggled when general category disabled',
        () async {
      await service.setGeneralEnabled(false);
      service.track(
        'notification_setting_toggled',
        properties: {
          'setting': 'master',
          'enabled': true,
          'source': 'user',
        },
      );
      expect(service.bufferLength, 0);
    });

    test('buffers beta_feature_toggled under general category', () {
      service.track(
        'beta_feature_toggled',
        properties: {'feature': 'manual_step_control', 'enabled': true},
      );
      expect(service.bufferLength, 1);
    });

    test(
      'registers deletion and undo events with privacy-safe payloads (plan 056)',
      () {
        service.track('bean_deleted', properties: {
          'brew_count': 3,
          'has_linked_brews': true,
          'has_stock_remaining': false,
        });
        service.track('user_recipe_deleted', properties: {
          'brew_count': 0,
          'is_public': false,
        });
        service.track('delete_undo_tapped', properties: {'entity': 'bean'});

        final events = service.bufferedEventsForTesting;
        expect(events.map((event) => event['event_name']).toList(), [
          'bean_deleted',
          'user_recipe_deleted',
          'delete_undo_tapped',
        ]);
        expect(events[0]['category'], 'beans');
        expect(events[1]['category'], 'general');
        expect(events[2]['category'], 'general');

        // Privacy rule: booleans, counts, and enums only — never a name,
        // note, or other free text. The one allowed string is the fixed
        // `entity` enum of delete_undo_tapped.
        const allowedEnumValues = {'diary', 'bean', 'recipe'};
        for (final event in events) {
          final properties = event['properties'] as Map<Object?, Object?>;
          for (final value in properties.values) {
            if (value is String) {
              expect(allowedEnumValues, contains(value));
            } else {
              expect(value, anyOf(isA<bool>(), isA<int>()));
            }
          }
        }
        expect(
          (events[2]['properties'] as Map)['entity'],
          anyOf('diary', 'bean', 'recipe'),
        );
      },
    );

    test('is no-op when category disabled for deletion events', () async {
      await service.setBeansEnabled(false);
      await service.setGeneralEnabled(false);
      service.track('bean_deleted', properties: {
        'brew_count': 1,
        'has_linked_brews': true,
        'has_stock_remaining': true,
      });
      service.track('user_recipe_deleted', properties: {'brew_count': 2});
      service.track('delete_undo_tapped', properties: {'entity': 'diary'});
      expect(service.bufferLength, 0);
    });

    test('respects categories independently', () async {
      await service.setBrewsEnabled(false);
      // Beans and general should still work
      service.track('beans_added');
      service.track('app_opened');
      expect(service.bufferLength, 2);
    });

    test('is no-op when global kill switch is on', () {
      service.setGlobalKillSwitch(true);
      service.track('brew_started');
      service.track('beans_added');
      service.track('app_opened');
      expect(service.bufferLength, 0);
    });

    test('resumes when global kill switch is turned off', () {
      service.setGlobalKillSwitch(true);
      service.track('brew_started');
      expect(service.bufferLength, 0);

      service.setGlobalKillSwitch(false);
      service.track('brew_started');
      expect(service.bufferLength, 1);
    });

    test('buffer caps at 500 events', () {
      for (int i = 0; i < 510; i++) {
        service.track('app_opened');
      }
      expect(service.bufferLength, 500);
    });
  });

  group('category toggles', () {
    test('setBrewsEnabled persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      await service.setBrewsEnabled(false);
      expect(prefs.getBool('analytics_brews_enabled'), isFalse);

      await service.setBrewsEnabled(true);
      expect(prefs.getBool('analytics_brews_enabled'), isTrue);
    });

    test('setBeansEnabled persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      await service.setBeansEnabled(false);
      expect(prefs.getBool('analytics_beans_enabled'), isFalse);
    });

    test('setGeneralEnabled persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      await service.setGeneralEnabled(false);
      expect(prefs.getBool('analytics_general_enabled'), isFalse);
    });

    test('notifies listeners on category change', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      bool notified = false;
      service.addListener(() => notified = true);

      await service.setBrewsEnabled(false);
      expect(notified, isTrue);
    });

    test('persisted preferences survive reinitialization', () async {
      final prefs = await SharedPreferences.getInstance();
      var service = await AnalyticsService.initialize(prefs);
      await service.setBrewsEnabled(false);
      await service.setBeansEnabled(false);

      AnalyticsService.resetForTesting();
      service = await AnalyticsService.initialize(prefs);

      expect(service.brewsEnabled, isFalse);
      expect(service.beansEnabled, isFalse);
      expect(service.generalEnabled, isTrue); // default
    });
  });
}
