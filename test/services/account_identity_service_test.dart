import 'dart:convert';

import 'package:coffee_timer/services/account_identity_service.dart';
import 'package:coffee_timer/services/auth/native_auth_credentials.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _authUrl = 'https://example.test/auth/v1';
const _userId = '11111111-1111-1111-1111-111111111111';

void main() {
  group('email eligibility', () {
    test('confirmed Google-only account can change email', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        _unexpected,
        user: _userJson(
          identities: [_identityJson('google', email: 'google@example.com')],
        ),
      );

      expect(_service(auth).canChangeEmail, isTrue);
    });

    test('account without email confirmation cannot change email', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        _unexpected,
        user: _userJson(
          emailConfirmed: false,
          identities: [_identityJson('google', email: 'google@example.com')],
        ),
      );

      expect(_service(auth).canChangeEmail, isFalse);
    });
  });

  group('email changes', () {
    test('secure flow accepts the first code and completes the second', () async {
      var verificationCount = 0;
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, (request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/verify')) {
          verificationCount++;
          if (verificationCount == 1) {
            return _jsonResponse(200, {
              'msg':
                  'Confirmation link accepted. Please proceed to confirm link sent to the other email',
              'code': '200',
            });
          }
          return _jsonResponse(200, _sessionJson());
        }
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          return _jsonResponse(200, _userJson(email: 'new@example.com'));
        }
        return _unexpected(request);
      });
      final service = _service(auth);

      expect(
        await service.confirmEmailChangeCode(
          email: ' old@example.com ',
          code: ' 12 34 56 ',
        ),
        EmailCodeResult.accepted,
      );
      expect(
        await service.confirmEmailChangeCode(
          email: 'new@example.com',
          code: '654321',
        ),
        EmailCodeResult.completed,
      );

      final verifyBodies = requests
          .where((request) => request.path.endsWith('/verify'))
          .map((request) => jsonDecode(request.body) as Map<String, dynamic>)
          .toList();
      expect(verifyBodies.first['email'], 'old@example.com');
      expect(verifyBodies.first['token'], '123456');
      expect(verifyBodies.first['type'], 'email_change');
      expect(
        requests.where(
          (request) =>
              request.method == 'GET' && request.path.endsWith('/user'),
        ),
        hasLength(1),
      );
    });

    test('wrong code is invalid or expired', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        (request) async =>
            _authError(403, 'otp_expired', 'Token has expired or is invalid'),
      );

      expect(
        await _service(
          auth,
        ).confirmEmailChangeCode(email: 'old@example.com', code: 'wrong'),
        EmailCodeResult.invalidOrExpired,
      );
    });

    test('empty confirmation code makes no request', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, _unexpected);

      expect(
        await _service(
          auth,
        ).confirmEmailChangeCode(email: 'old@example.com', code: ' \n\t '),
        EmailCodeResult.invalidOrExpired,
      );
      expect(requests, isEmpty);
    });

    test('request succeeds and sends the sanitized email', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, (request) async {
        if (request.method == 'PUT' && request.url.path.endsWith('/user')) {
          return _jsonResponse(200, _userJson(email: 'new@example.com'));
        }
        return _unexpected(request);
      });

      expect(
        await _service(auth).requestEmailChange(' new@example.com '),
        EmailChangeRequest.sent,
      );
      final request = requests.single;
      expect(request.method, 'PUT');
      expect(jsonDecode(request.body)['email'], 'new@example.com');
      expect(request.uri.queryParameters['redirect_to'], 'timercoffee://');
    });

    test('request maps email_exists', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        (request) async =>
            _authError(422, 'email_exists', 'Email already exists'),
      );

      expect(
        await _service(auth).requestEmailChange('new@example.com'),
        EmailChangeRequest.emailTaken,
      );
    });

    test('request maps rate limiting', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        (request) async => _authError(
          429,
          'over_email_send_rate_limit',
          'Email rate limit exceeded',
        ),
      );

      expect(
        await _service(auth).requestEmailChange('new@example.com'),
        EmailChangeRequest.rateLimited,
      );
    });

    test('same and invalid emails make no request', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, _unexpected);
      final service = _service(auth);

      expect(
        await service.requestEmailChange(' OLD@EXAMPLE.COM '),
        EmailChangeRequest.sameAsCurrent,
      );
      expect(
        await service.requestEmailChange('not-an-email'),
        EmailChangeRequest.invalidEmail,
      );
      expect(requests, isEmpty);
    });

    test('resend uses the email_change type', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, (request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/resend')) {
          return _jsonResponse(200, <String, dynamic>{});
        }
        return _unexpected(request);
      });

      expect(
        await _service(auth).resendEmailChange(' new@example.com '),
        EmailChangeRequest.sent,
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['email'], 'new@example.com');
      expect(body['type'], 'email_change');
    });
  });

  group('linking', () {
    test(
      'Google links with ID tokens and forces the account chooser',
      () async {
        final requests = <_RecordedRequest>[];
        final credentials = _FakeCredentials(
          googleTokens: const GoogleIdTokens(
            idToken: 'google-id-token',
            accessToken: 'google-access-token',
          ),
        );
        final auth = await _seededAuth(requests, (request) async {
          if (request.method == 'POST' && request.url.path.endsWith('/token')) {
            return _jsonResponse(200, _sessionJson());
          }
          return _unexpected(request);
        });

        expect(
          await _service(auth, credentials: credentials).linkGoogle(),
          LinkOutcome.linked,
        );
        expect(credentials.googleForceAccountChooser, isTrue);
        final linkRequest = requests.firstWhere((request) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return body['provider'] == 'google';
        });
        final body = jsonDecode(linkRequest.body) as Map<String, dynamic>;
        expect(body['provider'], 'google');
        expect(body['link_identity'], isTrue);
      },
    );

    test('Google maps identity_already_exists', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        (request) async => _authError(
          422,
          'identity_already_exists',
          'Identity already linked to another user',
        ),
      );

      expect(
        await _service(
          auth,
          credentials: _FakeCredentials(
            googleTokens: const GoogleIdTokens(
              idToken: 'google-id-token',
              accessToken: 'google-access-token',
            ),
          ),
        ).linkGoogle(),
        LinkOutcome.alreadyUsedByAnotherAccount,
      );
    });

    test('Google maps manual_linking_disabled', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(
        requests,
        (request) async => _authError(
          404,
          'manual_linking_disabled',
          'Manual linking is disabled',
        ),
      );

      expect(
        await _service(
          auth,
          credentials: _FakeCredentials(
            googleTokens: const GoogleIdTokens(
              idToken: 'google-id-token',
              accessToken: 'google-access-token',
            ),
          ),
        ).linkGoogle(),
        LinkOutcome.linkingDisabled,
      );
    });

    test('Google cancellation makes no request', () async {
      final requests = <_RecordedRequest>[];
      final credentials = _FakeCredentials();
      final auth = await _seededAuth(requests, _unexpected);

      expect(
        await _service(auth, credentials: credentials).linkGoogle(),
        LinkOutcome.cancelled,
      );
      expect(credentials.googleForceAccountChooser, isTrue);
      expect(requests, isEmpty);
    });

    test('Apple is unsupported on Android without a request', () async {
      final requests = <_RecordedRequest>[];
      final credentials = _FakeCredentials(
        appleTokens: const AppleIdTokens(
          idToken: 'apple-id-token',
          rawNonce: 'apple-raw-nonce',
        ),
      );
      final auth = await _seededAuth(requests, _unexpected);

      expect(
        await _service(
          auth,
          credentials: credentials,
          platform: TargetPlatform.android,
        ).linkApple(),
        LinkOutcome.unsupportedPlatform,
      );
      expect(credentials.appleCalled, isFalse);
      expect(requests, isEmpty);
    });
  });

  group('unlinking', () {
    test('predicts the account email selected after unlink', () {
      final email = _identity('email', email: 'g@example.com');
      final googleOlder = _identity(
        'google',
        email: 'g@example.com',
        emailVerified: true,
        createdAt: '2026-01-01T00:00:00.000Z',
      );
      final appleNewer = _identity(
        'apple',
        email: 'a@example.com',
        emailVerified: true,
        createdAt: '2026-01-02T00:00:00.000Z',
      );

      expect(
        AccountIdentityService.accountEmailAfterUnlink(
          currentEmail: 'g@example.com',
          removing: googleOlder,
          all: [email, googleOlder],
        ),
        isNull,
      );
      expect(
        AccountIdentityService.accountEmailAfterUnlink(
          currentEmail: 'g@example.com',
          removing: googleOlder,
          all: [googleOlder, appleNewer],
        ),
        'a@example.com',
      );
      expect(
        AccountIdentityService.accountEmailAfterUnlink(
          currentEmail: 'g@example.com',
          removing: appleNewer,
          all: [googleOlder, appleNewer],
        ),
        isNull,
      );

      final googleNewer = _identity(
        'google',
        email: 'g@example.com',
        emailVerified: true,
        createdAt: '2026-01-02T00:00:00.000Z',
      );
      final appleOlder = _identity(
        'apple',
        email: 'a@example.com',
        emailVerified: true,
        createdAt: '2026-01-01T00:00:00.000Z',
      );
      expect(
        AccountIdentityService.accountEmailAfterUnlink(
          currentEmail: 'x@example.com',
          removing: googleNewer,
          all: [googleNewer, appleOlder],
        ),
        'a@example.com',
      );

      final removing = _identity('email');
      final unverifiedOlder = _identity(
        'apple',
        email: 'a@example.com',
        createdAt: '2026-01-01T00:00:00.000Z',
      );
      final verifiedNewer = _identity(
        'google',
        email: 'g@example.com',
        emailVerified: true,
        createdAt: '2026-01-02T00:00:00.000Z',
      );
      expect(
        AccountIdentityService.accountEmailAfterUnlink(
          currentEmail: 'x@example.com',
          removing: removing,
          all: [removing, unverifiedOlder, verifiedNewer],
        ),
        'g@example.com',
      );
      expect(
        AccountIdentityService.accountEmailAfterUnlink(
          currentEmail: 'G@EXAMPLE.COM',
          removing: appleNewer,
          all: [googleOlder, appleNewer],
        ),
        isNull,
      );
    });

    test('canUnlink protects email and the last identity', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, _unexpected);
      final service = _service(auth);
      final email = _identity('email');
      final google = _identity('google');

      expect(service.canUnlink(email, [email, google]), isFalse);
      expect(service.canUnlink(google, [google]), isFalse);
      expect(service.canUnlink(google, [email, google]), isTrue);
    });

    test('email identity is not allowed and is never deleted', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, (request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          return _jsonResponse(200, _userJson());
        }
        return _unexpected(request);
      });

      expect(
        await _service(auth).unlink(_identity('email')),
        UnlinkOutcome.notAllowed,
      );
      expect(requests.where((request) => request.method == 'DELETE'), isEmpty);
    });

    test('maps email conflict to notAllowed', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, (request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          return _jsonResponse(200, _userJson());
        }
        if (request.method == 'DELETE' &&
            request.url.path.endsWith('/user/identities/google-identity')) {
          return _authError(
            422,
            'email_conflict_identity_not_deletable',
            'Identity cannot be deleted because its email conflicts',
          );
        }
        return _unexpected(request);
      });

      expect(
        await _service(auth).unlink(_identity('google')),
        UnlinkOutcome.notAllowed,
      );
    });

    test('successful unlink refreshes the session', () async {
      final requests = <_RecordedRequest>[];
      final auth = await _seededAuth(requests, (request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          return _jsonResponse(200, _userJson());
        }
        if (request.method == 'DELETE' &&
            request.url.path.endsWith('/user/identities/google-identity')) {
          return _jsonResponse(200, <String, dynamic>{});
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith('/token') &&
            request.url.queryParameters['grant_type'] == 'refresh_token') {
          return _jsonResponse(200, _sessionJson());
        }
        return _unexpected(request);
      });

      expect(
        await _service(auth).unlink(_identity('google')),
        UnlinkOutcome.unlinked,
      );
      expect(
        requests.where((request) => request.method == 'DELETE'),
        hasLength(1),
      );
      expect(
        requests.where(
          (request) =>
              request.method == 'POST' &&
              request.path.endsWith('/token') &&
              request.uri.queryParameters['grant_type'] == 'refresh_token',
        ),
        hasLength(1),
      );
    });
  });

  test('PIN: gotrue still throws a plain AuthException on 200-without-session — '
      'if this fails, gotrue changed single-confirmation behaviour; re-check '
      'plan 073 trap (a)', () async {
    final requests = <_RecordedRequest>[];
    final auth = await _seededAuth(
      requests,
      (request) async => _jsonResponse(200, {
        'msg':
            'Confirmation link accepted. Please proceed to confirm link sent to the other email',
        'code': '200',
      }),
    );

    await expectLater(
      auth.verifyOTP(
        email: 'old@example.com',
        token: '123456',
        type: OtpType.emailChange,
      ),
      throwsA(
        isA<AuthException>()
            .having(
              (error) => error is AuthApiException,
              'is AuthApiException',
              isFalse,
            )
            .having(
              (error) => error.message,
              'message',
              AccountIdentityService.missingVerificationSessionMessage,
            ),
      ),
    );
  });
}

AccountIdentityService _service(
  GoTrueClient auth, {
  NativeAuthCredentials? credentials,
  TargetPlatform platform = TargetPlatform.iOS,
}) {
  return AccountIdentityService(
    auth: auth,
    credentials: credentials ?? _FakeCredentials(),
    isWeb: false,
    platform: platform,
  );
}

Future<GoTrueClient> _seededAuth(
  List<_RecordedRequest> requests,
  Future<http.Response> Function(http.Request request) handler, {
  Map<String, dynamic>? user,
}) async {
  final auth = GoTrueClient(
    url: _authUrl,
    httpClient: MockClient((request) async {
      requests.add(
        _RecordedRequest(
          request.method,
          request.url,
          request.body,
          request.headers,
        ),
      );
      return handler(request);
    }),
    autoRefreshToken: false,
  );
  await auth.recoverSession(jsonEncode(_sessionJson(user)));
  return auth;
}

Map<String, dynamic> _sessionJson([Map<String, dynamic>? user]) {
  return {
    'access_token': 'test-access-token',
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': 4102444800,
    'user': user ?? _userJson(),
  };
}

Map<String, dynamic> _userJson({
  String email = 'old@example.com',
  bool emailConfirmed = true,
  bool isAnonymous = false,
  List<Map<String, dynamic>>? identities,
}) {
  return {
    'id': _userId,
    'aud': 'authenticated',
    'email': email,
    'email_confirmed_at': emailConfirmed ? '2026-01-01T00:00:00.000Z' : null,
    'is_anonymous': isAnonymous,
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00.000Z',
    'identities':
        identities ?? [_identityJson('email'), _identityJson('google')],
  };
}

Map<String, dynamic> _identityJson(
  String provider, {
  String? email,
  bool emailVerified = false,
  String createdAt = '2026-01-01T00:00:00.000Z',
  String? identityId,
}) {
  return {
    'identity_id': identityId ?? '$provider-identity',
    'id': '$provider-id',
    'user_id': _userId,
    'provider': provider,
    'identity_data': <String, dynamic>{
      'provider': provider,
      'email': ?email,
      'email_verified': emailVerified,
    },
    'created_at': createdAt,
    'last_sign_in_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
  };
}

UserIdentity _identity(
  String provider, {
  String? email,
  bool emailVerified = false,
  String createdAt = '2026-01-01T00:00:00.000Z',
  String? identityId,
}) {
  return UserIdentity.fromMap(
    _identityJson(
      provider,
      email: email,
      emailVerified: emailVerified,
      createdAt: createdAt,
      identityId: identityId,
    ),
  );
}

http.Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

http.Response _authError(int statusCode, String errorCode, String message) {
  return _jsonResponse(statusCode, {
    'code': statusCode,
    'error_code': errorCode,
    'msg': message,
  });
}

Future<http.Response> _unexpected(http.Request request) {
  throw StateError('Unexpected request: ${request.method} ${request.url.path}');
}

class _RecordedRequest {
  const _RecordedRequest(this.method, this.uri, this.body, this.headers);

  final String method;
  final Uri uri;
  final String body;
  final Map<String, String> headers;

  String get path => uri.path;
}

class _FakeCredentials extends NativeAuthCredentials {
  _FakeCredentials({this.googleTokens, this.appleTokens});

  final GoogleIdTokens? googleTokens;
  final AppleIdTokens? appleTokens;
  bool? googleForceAccountChooser;
  bool appleCalled = false;

  @override
  Future<GoogleIdTokens?> google({bool forceAccountChooser = false}) async {
    googleForceAccountChooser = forceAccountChooser;
    return googleTokens;
  }

  @override
  Future<AppleIdTokens> apple() async {
    appleCalled = true;
    return appleTokens!;
  }
}
