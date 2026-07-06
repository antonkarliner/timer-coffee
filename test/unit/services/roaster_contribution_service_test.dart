import 'dart:async';

import 'package:coffee_timer/services/roaster_contribution_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> pendingTarget() => {
  'matched_roaster_id': null,
  'cluster_id': 'cluster-1',
  'cluster_status': 'pending',
  'normalized_name': 'pending roaster',
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('caches successful target lookups by normalized roaster name', () async {
    var callCount = 0;
    final service = RoasterContributionService.forTesting(
      hasCurrentUser: () => true,
      targetLoader: (roaster) async {
        callCount++;
        return pendingTarget();
      },
    );

    final first = await service.checkEligibility('  Pending   Roaster  ');
    final second = await service.checkEligibility('pending roaster');

    expect(first.eligible, isTrue);
    expect(second.eligible, isTrue);
    expect(callCount, 1);
  });

  test('deduplicates concurrent target lookups', () async {
    var callCount = 0;
    final response = Completer<Object?>();
    final service = RoasterContributionService.forTesting(
      hasCurrentUser: () => true,
      targetLoader: (roaster) {
        callCount++;
        return response.future;
      },
    );

    final first = service.checkEligibility('Pending Roaster');
    final second = service.checkEligibility(' pending   roaster ');
    expect(callCount, 1);

    response.complete(pendingTarget());

    expect((await first).eligible, isTrue);
    expect((await second).eligible, isTrue);
    expect(callCount, 1);
  });

  test('rechecks local resolved state when using a cached target', () async {
    var callCount = 0;
    final service = RoasterContributionService.forTesting(
      hasCurrentUser: () => true,
      targetLoader: (roaster) async {
        callCount++;
        return pendingTarget();
      },
    );

    expect(
      (await service.checkEligibility('Pending Roaster')).eligible,
      isTrue,
    );
    await service.dismiss('cluster-1');

    expect(
      (await service.checkEligibility('Pending Roaster')).eligible,
      isFalse,
    );
    expect(callCount, 1);
  });

  test(
    'retries failed target lookups instead of caching the failure',
    () async {
      var callCount = 0;
      final service = RoasterContributionService.forTesting(
        hasCurrentUser: () => true,
        targetLoader: (roaster) async {
          callCount++;
          throw StateError('offline');
        },
      );

      expect(
        (await service.checkEligibility('Pending Roaster')).eligible,
        isFalse,
      );
      expect(
        (await service.checkEligibility('Pending Roaster')).eligible,
        isFalse,
      );
      expect(callCount, 2);
    },
  );

  test('refreshes a target after the cache TTL expires', () async {
    var callCount = 0;
    var now = DateTime.utc(2026, 7, 4, 10);
    final service = RoasterContributionService.forTesting(
      hasCurrentUser: () => true,
      now: () => now,
      targetLoader: (roaster) async {
        callCount++;
        return pendingTarget();
      },
    );

    await service.checkEligibility('Pending Roaster');
    now = now.add(const Duration(minutes: 9));
    await service.checkEligibility('Pending Roaster');
    expect(callCount, 1);

    now = now.add(const Duration(minutes: 2));
    await service.checkEligibility('Pending Roaster');
    expect(callCount, 2);
  });
}
