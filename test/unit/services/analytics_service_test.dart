import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/analytics_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
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
      expect(recipeProperties['recipe_id'], 'recipe-123');
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

    test('buffers beta_feature_toggled under general category', () {
      service.track(
        'beta_feature_toggled',
        properties: {'feature': 'manual_step_control', 'enabled': true},
      );
      expect(service.bufferLength, 1);
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
