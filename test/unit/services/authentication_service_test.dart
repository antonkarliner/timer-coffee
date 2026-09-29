import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 9, 29, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(AnalyticsService.resetForTesting);

  List<Map<String, dynamic>> eventsNamed(String name) {
    return AnalyticsService.instance.bufferedEventsForTesting
        .where((event) => event['event_name'] == name)
        .toList();
  }

  PostSignInSteps steps({
    Future<void> Function(String, String)? updateRecipeIds,
    Future<void> Function(String, String)? migrate,
    Future<void> Function()? syncData,
    Future<void> Function()? registerFcmToken,
    Future<void> Function()? reconcileMilestones,
  }) {
    return PostSignInSteps(
      updateRecipeIds: updateRecipeIds ?? (_, _) async {},
      migrate: migrate ?? (_, _) async {},
      syncData: syncData ?? () async {},
      registerFcmToken: registerFcmToken ?? () async {},
      reconcileMilestones: reconcileMilestones ?? () async {},
    );
  }

  test('runs migration and post-sign-in steps in order', () async {
    final order = <String>[];

    await AuthenticationService.runPostSignIn(
      steps: steps(
        updateRecipeIds: (oldUserId, newUserId) async {
          expect((oldUserId, newUserId), ('anonymous', 'registered'));
          order.add('recipe_ids');
        },
        migrate: (oldUserId, newUserId) async {
          expect((oldUserId, newUserId), ('anonymous', 'registered'));
          order.add('migration');
        },
        syncData: () async {
          expect(eventsNamed('sign_in_completed'), hasLength(1));
          order
            ..add('completed_event')
            ..add('data_sync');
        },
        registerFcmToken: () async => order.add('fcm'),
        reconcileMilestones: () async => order.add('milestones'),
      ),
      oldUserId: 'anonymous',
      newUserId: 'registered',
      source: 'hub',
      method: 'email',
      userCreatedAt: now.subtract(const Duration(minutes: 1)),
      now: now,
    );

    expect(order, [
      'recipe_ids',
      'migration',
      'completed_event',
      'data_sync',
      'fcm',
      'milestones',
    ]);
  });

  for (final oldUserId in <String?>[null, 'registered']) {
    test('does not migrate when old user id is $oldUserId', () async {
      var updateCalled = false;
      var migrationCalled = false;

      await AuthenticationService.runPostSignIn(
        steps: steps(
          updateRecipeIds: (_, _) async => updateCalled = true,
          migrate: (_, _) async => migrationCalled = true,
        ),
        oldUserId: oldUserId,
        newUserId: 'registered',
        source: 'unknown',
        method: 'google',
        userCreatedAt: now.subtract(const Duration(days: 1)),
        now: now,
      );

      expect(updateCalled, isFalse);
      expect(migrationCalled, isFalse);
      expect(
        eventsNamed('sign_in_completed').single['properties'],
        containsPair('migrated', false),
      );
    });
  }

  test('migration failure is tracked and data sync still runs', () async {
    var dataSynced = false;

    await AuthenticationService.runPostSignIn(
      steps: steps(
        migrate: (_, _) async => throw StateError('migration failed'),
        syncData: () async => dataSynced = true,
      ),
      oldUserId: 'anonymous',
      newUserId: 'registered',
      source: 'hub',
      method: 'apple',
      userCreatedAt: now,
      now: now,
    );

    expect(dataSynced, isTrue);
    expect(eventsNamed('sign_in_sync_failed').single['properties'], {
      'source': 'hub',
      'step': 'migration',
    });
    expect(
      eventsNamed('sign_in_completed').single['properties'],
      containsPair('migrated', false),
    );
  });

  test('recipe-rename failure is tracked and migration still runs', () async {
    var migrationCalled = false;

    await AuthenticationService.runPostSignIn(
      steps: steps(
        updateRecipeIds: (_, _) async => throw StateError('rename failed'),
        migrate: (_, _) async => migrationCalled = true,
      ),
      oldUserId: 'anonymous',
      newUserId: 'registered',
      source: 'hub',
      method: 'email',
      userCreatedAt: now,
      now: now,
    );

    expect(migrationCalled, isTrue);
    expect(eventsNamed('sign_in_sync_failed').single['properties'], {
      'source': 'hub',
      'step': 'recipe_ids',
    });
    expect(
      eventsNamed('sign_in_completed').single['properties'],
      containsPair('migrated', true),
    );
  });

  test('data-sync failure is tracked and does not throw', () async {
    var fcmRegistered = false;
    var milestonesReconciled = false;

    await AuthenticationService.runPostSignIn(
      steps: steps(
        syncData: () async => throw StateError('sync failed'),
        registerFcmToken: () async => fcmRegistered = true,
        reconcileMilestones: () async => milestonesReconciled = true,
      ),
      oldUserId: null,
      newUserId: 'registered',
      source: 'recipe_share',
      method: 'google',
      userCreatedAt: now,
      now: now,
    );

    expect(fcmRegistered, isTrue);
    expect(milestonesReconciled, isTrue);
    expect(eventsNamed('sign_in_sync_failed').single['properties'], {
      'source': 'recipe_share',
      'step': 'data_sync',
    });
  });

  test('FCM failure does not emit a sync-failed event', () async {
    var milestonesReconciled = false;

    await AuthenticationService.runPostSignIn(
      steps: steps(
        registerFcmToken: () async => throw StateError('FCM failed'),
        reconcileMilestones: () async => milestonesReconciled = true,
      ),
      oldUserId: null,
      newUserId: 'registered',
      source: 'hub',
      method: 'email',
      userCreatedAt: now,
      now: now,
    );

    expect(milestonesReconciled, isTrue);
    expect(eventsNamed('sign_in_sync_failed'), isEmpty);
  });

  test('completed event has only non-sensitive required properties', () async {
    await AuthenticationService.runPostSignIn(
      steps: steps(),
      oldUserId: null,
      newUserId: 'registered',
      source: 'hub',
      method: 'email',
      userCreatedAt: now.subtract(const Duration(minutes: 4)),
      now: now,
    );

    final properties =
        eventsNamed('sign_in_completed').single['properties']
            as Map<String, dynamic>;
    expect(properties, {
      'source': 'hub',
      'method': 'email',
      'is_new_account': true,
      'migrated': false,
    });
    expect(
      properties.values.whereType<String>(),
      everyElement(isNot(matches(RegExp(r'\S+@\S+\.\S+')))),
    );
  });
}
