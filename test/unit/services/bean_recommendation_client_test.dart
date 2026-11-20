import 'dart:convert';

import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('updated client uses the durable recommendation opt-out contract',
      () async {
    final requests = <http.Request>[];
    final supabase = SupabaseClient(
      'https://recommendations.example',
      'public-fixture-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/get_my_recommendation_opt_out')) {
          return http.Response(
            'true',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response('', 204, request: request);
      }),
    );
    addTearDown(supabase.dispose);
    final client = SupabaseBeanRecommendationClient(supabase);

    await client.deleteMine();
    expect(await client.fetchOptOut(), isTrue);
    await client.setOptOut(false);

    expect(requests.map((request) => request.url.pathSegments.last), [
      'opt_out_and_delete_my_recommendations',
      'get_my_recommendation_opt_out',
      'set_my_recommendation_opt_out',
    ]);
    expect(jsonDecode(requests.last.body), {'p_opted_out': false});
  });
}
