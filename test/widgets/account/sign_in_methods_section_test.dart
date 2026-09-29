import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/account_identity_service.dart';
import 'package:coffee_timer/widgets/account/sign_in_methods_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _authUrl = 'https://example.test/auth/v1';
const _userId = '11111111-1111-1111-1111-111111111111';

void main() {
  testWidgets('shows email, linked Google, and linkable Apple on iOS', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      platform: TargetPlatform.iOS,
      email: 'email@example.com',
      identities: [
        _identityJson('email', email: 'email@example.com'),
        _identityJson('google', email: 'google@example.com'),
      ],
    );

    expect(_displayedEmail('email@example.com'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(_displayedEmail('google@example.com'), findsOneWidget);
    expect(find.text('Unlink'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
  });

  testWidgets('shows email and Google but not Apple on Android', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      platform: TargetPlatform.android,
      email: 'email@example.com',
      identities: [_identityJson('email', email: 'email@example.com')],
    );

    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets('does not duplicate email for a Google-only account on iOS', (
    tester,
  ) async {
    await _pumpSection(
      tester,
      platform: TargetPlatform.iOS,
      email: 'google-only@example.com',
      identities: [_identityJson('google', email: 'google-only@example.com')],
    );

    expect(find.byIcon(Icons.email_outlined), findsNothing);
    expect(find.text('Change'), findsNothing);
    expect(find.text('Google'), findsOneWidget);
    expect(_displayedEmail('google-only@example.com'), findsOneWidget);
    expect(find.text('Unlink'), findsNothing);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
  });

  testWidgets('keeps a linked Apple row visible on Android', (tester) async {
    await _pumpSection(
      tester,
      platform: TargetPlatform.android,
      email: 'apple-user@example.com',
      identities: [_identityJson('apple')],
    );

    expect(find.byIcon(Icons.email_outlined), findsNothing);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Linked'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
    expect(find.text('Unlink'), findsNothing);
  });

  testWidgets('Google overflow opens the unlink confirmation', (tester) async {
    await _pumpSection(
      tester,
      platform: TargetPlatform.iOS,
      email: 'email@example.com',
      identities: [
        _identityJson('email', email: 'email@example.com'),
        _identityJson('google', email: 'google@example.com'),
      ],
    );

    await tester.tap(find.text('Unlink'));
    await tester.pumpAndSettle();

    expect(find.text('Unlink Google?'), findsOneWidget);
    expect(
      find.text('You won’t be able to sign in with Google anymore.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required TargetPlatform platform,
  required String email,
  required List<Map<String, dynamic>> identities,
}) async {
  final user = _userJson(email: email, identities: identities);
  final auth = GoTrueClient(
    url: _authUrl,
    httpClient: MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/user')) {
        return _jsonResponse(200, user);
      }
      throw StateError(
        'Unexpected request: ${request.method} ${request.url.path}',
      );
    }),
    autoRefreshToken: false,
  );
  addTearDown(auth.dispose);
  await auth.recoverSession(jsonEncode(_sessionJson(user)));

  final service = AccountIdentityService(
    auth: auth,
    isWeb: false,
    platform: platform,
  );
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SignInMethodsSection(service: service)),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _sessionJson(Map<String, dynamic> user) {
  return {
    'access_token': 'test-access-token',
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': 4102444800,
    'user': user,
  };
}

Map<String, dynamic> _userJson({
  required String email,
  required List<Map<String, dynamic>> identities,
}) {
  return {
    'id': _userId,
    'aud': 'authenticated',
    'email': email,
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00.000Z',
    'identities': identities,
  };
}

Map<String, dynamic> _identityJson(String provider, {String? email}) {
  return {
    'identity_id': '$provider-identity',
    'id': '$provider-id',
    'user_id': _userId,
    'provider': provider,
    'identity_data': <String, dynamic>{'provider': provider, 'email': ?email},
    'created_at': '2026-01-01T00:00:00.000Z',
    'last_sign_in_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
  };
}

http.Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// The section inserts a zero-width space after the @ so a long address
/// wraps at a natural point; match the address as it is displayed.
Finder _displayedEmail(String email) =>
    find.text(email.replaceFirst('@', '@\u200B'));
