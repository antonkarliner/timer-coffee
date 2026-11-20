import 'dart:async';

import 'package:coffee_timer/providers/fcm_provider.dart';
import 'package:coffee_timer/services/fcm_service.dart';
import 'package:coffee_timer/services/notification_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Messaging extends Fake implements FcmService {
  @override
  final onNotificationTapped = BehaviorSubject<String?>();
  final refresh = StreamController<String>.broadcast();
  @override
  Stream<String> get tokenRefreshes => refresh.stream;
  bool permission = true;
  bool offline = false;
  bool deletionFails = false;
  String sdkToken = 'this-device';
  String? collisionOwner;
  String? tokenAfterInvalidation;
  final operations = <String>[];

  @override
  Future<void> initialize() async {}
  @override
  Future<bool> checkPermissionStatus() async => permission;
  @override
  Future<String?> getToken() async => sdkToken;
  @override
  Future<void> storeToken({
    required String userId,
    required String token,
  }) async {
    operations.add('register $userId $token');
    if (userId == collisionOwner && token == 'this-device') {
      throw const PostgrestException(
        message: 'Row owned by prior account',
        code: '42501',
      );
    }
  }

  @override
  Future<void> deleteTokenForUser({
    required String userId,
    required String token,
  }) async {
    operations.add('detach $userId $token');
    if (deletionFails) throw StateError('Row unavailable');
  }

  @override
  Future<void> markTokenInactive({
    required String userId,
    required String token,
  }) async {
    operations.add('deactivate $token');
  }

  @override
  Future<void> deleteToken() async {
    operations.add('invalidate');
    if (offline) throw StateError('Offline');
    sdkToken = tokenAfterInvalidation ?? sdkToken;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Messaging messaging;
  late FcmProvider provider;
  String? owner;
  Future<void> start({required bool enabled}) async {
    SharedPreferences.setMockInitialValues({KEY_MASTER_ENABLED: enabled});
    owner = 'account-a';
    messaging = _Messaging();
    provider = FcmProvider.forTesting(messaging, () => owner);
    await provider.initialize();
    addTearDown(() async {
      provider.dispose();
      await messaging.refresh.close();
      await messaging.onNotificationTapped.close();
    });
  }

  test('18: visiting the hub or refreshing a token respects opt-out', () async {
    await start(enabled: false);
    await provider.ensureActiveToken();
    messaging.refresh.add('this-device');
    await Future<void>.delayed(Duration.zero);
    expect(messaging.operations, isEmpty);
  });

  test(
    '53: registration and opt-out address only the SDK installation',
    () async {
      await start(enabled: true);
      await provider.disableNotifications(userId: owner);
      expect(messaging.operations, [
        'register account-a this-device',
        'deactivate this-device',
      ]);
    },
  );

  test(
    '39 and 52: failed detachment is retried before registration under another account',
    () async {
      await start(enabled: true);
      messaging.deletionFails = true;
      messaging.offline = true;
      await provider.signOutAfterDetaching(() async {
        await provider.ensureActiveToken();
        owner = 'account-b';
      });
      await provider.ensureActiveToken();
      expect(
        messaging.operations,
        isNot(contains('register account-b this-device')),
      );
      messaging.offline = false;
      await provider.ensureActiveToken();
      expect(messaging.operations, contains('detach account-a this-device'));
      expect(messaging.operations.last, 'register account-b this-device');
    },
  );
  test(
    'a token owned by the previous account is replaced instead of transferred',
    () async {
      await start(enabled: true);
      owner = 'account-b';
      expect(provider.currentToken, isNull);
      messaging.collisionOwner = 'account-b';
      messaging.tokenAfterInvalidation = 'rotated-device';

      await provider.ensureActiveToken();

      expect(messaging.operations, [
        'register account-a this-device',
        'register account-b this-device',
        'invalidate',
        'register account-b rotated-device',
      ]);
      expect(provider.currentToken, 'rotated-device');
    },
  );

  test(
    'SDK rotation updates this installation and inactivates only its prior token',
    () async {
      await start(enabled: true);
      messaging.sdkToken = 'new-device';
      messaging.refresh.add('new-device');
      await Future<void>.delayed(Duration.zero);
      await provider.ensureActiveToken();

      expect(messaging.operations, [
        'register account-a this-device',
        'register account-a new-device',
        'deactivate this-device',
      ]);
    },
  );
}
