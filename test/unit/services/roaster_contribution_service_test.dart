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

/// A dummy loader for the target RPC when a test only exercises the
/// acknowledgement path (forTesting still requires [targetLoader]).
Never unusedTargetLoader(String roaster) => throw UnimplementedError();

Map<String, dynamic> ackRow() => {
  'contribution_id': 2376,
  'roaster_name': 'Fuglen',
  'slug': '2376',
  'roaster_logo_url': null,
  'roaster_logo_mirror_url': 'https://mirror.test/2376.png',
  'dominant_color_hex': '#A0522D',
  'resolved_at': '2026-09-01T10:00:00Z',
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

  test(
    'acknowledgement fetch returns null when there is no current user',
    () async {
      var loaderCalls = 0;
      final service = RoasterContributionService.forTesting(
        targetLoader: unusedTargetLoader,
        hasCurrentUser: () => false,
        acknowledgementLoader: () async {
          loaderCalls++;
          return [ackRow()];
        },
      );

      expect(await service.fetchPendingAcknowledgement(), isNull);
      expect(loaderCalls, 0);
    },
  );

  test('acknowledgement fetch returns null on an empty list', () async {
    var loaderCalls = 0;
    final service = RoasterContributionService.forTesting(
      targetLoader: unusedTargetLoader,
      hasCurrentUser: () => true,
      acknowledgementLoader: () async {
        loaderCalls++;
        return <Object?>[];
      },
    );

    expect(await service.fetchPendingAcknowledgement(), isNull);
    expect(loaderCalls, 1);
  });

  test('parses a full acknowledgement row, tolerating nulls', () async {
    final service = RoasterContributionService.forTesting(
      targetLoader: unusedTargetLoader,
      hasCurrentUser: () => true,
      acknowledgementLoader: () async => [ackRow()],
    );

    final ack = await service.fetchPendingAcknowledgement();

    expect(ack, isNotNull);
    expect(ack!.contributionId, 2376);
    expect(ack.roasterName, 'Fuglen');
    expect(ack.slug, '2376');
    expect(ack.logoUrl, isNull);
    expect(ack.logoMirrorUrl, 'https://mirror.test/2376.png');
    expect(ack.dominantColorHex, '#A0522D');
    expect(ack.resolvedAt, DateTime.utc(2026, 9, 1, 10));
  });

  test(
    'acknowledgement with missing or garbage resolved_at parses to null',
    () async {
      final service = RoasterContributionService.forTesting(
        targetLoader: unusedTargetLoader,
        hasCurrentUser: () => true,
        acknowledgementLoader: () async => [
          ackRow()..['resolved_at'] = 'not-a-timestamp',
        ],
      );

      final ack = await service.fetchPendingAcknowledgement();
      expect(ack, isNotNull);
      expect(ack!.resolvedAt, isNull);

      final missingService = RoasterContributionService.forTesting(
        targetLoader: unusedTargetLoader,
        hasCurrentUser: () => true,
        acknowledgementLoader: () async {
          final row = ackRow()..remove('resolved_at');
          return [row];
        },
      );

      final missing = await missingService.fetchPendingAcknowledgement();
      expect(missing, isNotNull);
      expect(missing!.resolvedAt, isNull);
    },
  );

  test(
    'acknowledgement fetch caches within the TTL and refetches after it',
    () async {
      var loaderCalls = 0;
      var now = DateTime.utc(2026, 9, 1, 10);
      final service = RoasterContributionService.forTesting(
        targetLoader: unusedTargetLoader,
        hasCurrentUser: () => true,
        now: () => now,
        acknowledgementLoader: () async {
          loaderCalls++;
          return [ackRow()];
        },
      );

      await service.fetchPendingAcknowledgement();
      await service.fetchPendingAcknowledgement();
      expect(loaderCalls, 1);

      now = now.add(const Duration(minutes: 11));
      await service.fetchPendingAcknowledgement();
      expect(loaderCalls, 2);
    },
  );

  test(
    'acknowledgement fetch returns null (no throw) when the loader throws',
    () async {
      final service = RoasterContributionService.forTesting(
        targetLoader: unusedTargetLoader,
        hasCurrentUser: () => true,
        acknowledgementLoader: () async => throw StateError('offline'),
      );

      expect(await service.fetchPendingAcknowledgement(), isNull);
    },
  );

  test('markAcknowledged invalidates the acknowledgement cache', () async {
    var loaderCalls = 0;
    final service = RoasterContributionService.forTesting(
      targetLoader: unusedTargetLoader,
      hasCurrentUser: () => true,
      acknowledgementLoader: () async {
        loaderCalls++;
        return [ackRow()];
      },
    );

    await service.fetchPendingAcknowledgement();
    await service.markAcknowledged(2376);
    await service.fetchPendingAcknowledgement();

    expect(loaderCalls, 2);
  });
}
