import 'dart:convert';

import 'package:coffee_timer/screens/account_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final objectRemains in [true, false]) {
    test(
      'profile removal confirms origin absence before unlinking ($objectRemains)',
      () async {
        final methods = <String>[];
        final client = SupabaseClient(
          'https://test.invalid',
          'public-test-key',
          httpClient: MockClient((request) async {
            methods.add(request.method);
            if (request.method == 'DELETE') {
              expect(jsonDecode(request.body)['prefixes'], ['owner']);
              return http.Response('[]', 200);
            }
            if (request.method == 'HEAD') {
              expect(
                request.url.path,
                endsWith('/user-profile-pictures/owner'),
              );
              return http.Response('', objectRemains ? 200 : 404);
            }
            expect(request.url.queryParameters['user_id'], 'eq.owner');
            expect(jsonDecode(request.body), {'profile_picture_url': null});
            return http.Response(
              '{"user_id":"owner"}',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        if (objectRemains) {
          await expectLater(
            removeAccountPicture(client, 'owner'),
            throwsStateError,
          );
          expect(methods, ['DELETE', 'HEAD']);
        } else {
          await removeAccountPicture(client, 'owner');
          expect(methods, ['DELETE', 'HEAD', 'PATCH']);
        }
      },
    );
  }
}
