import 'package:coffee_timer/services/auth/pending_web_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final baseTime = DateTime.fromMillisecondsSinceEpoch(2000000000000);

  PendingWebSignIn pending({
    String? oldUserId = 'anonymous-user',
    Duration age = Duration.zero,
  }) {
    return PendingWebSignIn(
      oldUserId: oldUserId,
      oldAccessToken: 'anonymous-token',
      source: 'settings',
      method: 'google',
      createdAtMs: baseTime.subtract(age).millisecondsSinceEpoch,
    );
  }

  group('decidePendingWebSignIn', () {
    test('returns none without a pending record', () {
      expect(
        decidePendingWebSignIn(
          pending: null,
          currentUserId: 'signed-in-user',
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.none,
      );
    });

    test('returns expired just after the TTL', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(
            age: PendingWebSignIn.ttl + const Duration(milliseconds: 1),
          ),
          currentUserId: 'signed-in-user',
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.expired,
      );
    });

    test('does not expire just before the TTL', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(
            age: PendingWebSignIn.ttl - const Duration(milliseconds: 1),
          ),
          currentUserId: 'signed-in-user',
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.resume,
      );
    });

    test('returns resume for a different signed-in user', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(),
          currentUserId: 'signed-in-user',
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.resume,
      );
    });

    test('returns cancelled for an anonymous current user', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(),
          currentUserId: 'another-anonymous-user',
          currentUserIsAnonymous: true,
          now: baseTime,
        ),
        PendingWebSignInAction.cancelled,
      );
    });

    test('returns cancelled when the current id is the old id', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(),
          currentUserId: 'anonymous-user',
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.cancelled,
      );
    });

    test('returns cancelled without a current user', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(),
          currentUserId: null,
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.cancelled,
      );
    });

    test('returns resume without an old user id for a signed-in user', () {
      expect(
        decidePendingWebSignIn(
          pending: pending(oldUserId: null),
          currentUserId: 'signed-in-user',
          currentUserIsAnonymous: false,
          now: baseTime,
        ),
        PendingWebSignInAction.resume,
      );
    });
  });

  group('storage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('round-trips and clears a pending sign-in', () async {
      final value = pending();

      await value.save();
      final restored = await PendingWebSignIn.load();

      expect(restored?.oldUserId, value.oldUserId);
      expect(restored?.oldAccessToken, value.oldAccessToken);
      expect(restored?.source, value.source);
      expect(restored?.method, value.method);
      expect(restored?.createdAtMs, value.createdAtMs);

      await PendingWebSignIn.clear();
      expect(await PendingWebSignIn.load(), isNull);
    });

    test('treats malformed JSON as absent', () async {
      SharedPreferences.setMockInitialValues({
        PendingWebSignIn.storageKey: '{not valid JSON',
      });

      expect(await PendingWebSignIn.load(), isNull);
    });
  });
}
