import 'dart:convert';

import 'package:coffee_timer/services/bean_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const owner = '9afb37f5-ffdd-431a-a6e1-ee3b7becc76f';
const bean = 'aefd587b-b7c6-4d1a-904f-a54871aa1b93';
const legacy = '$owner/$bean.jpg';
const current = '$owner/$bean--1e4d45ba-02d7-4548-86d6-48713f3962e0.jpg';

void main() {
  test('legacy photos supply a locator without retaining signed access', () {
    const url =
        'https://api.timer.coffee/storage/v1/object/sign/bean-photos/'
        '$legacy?token=old-signature';
    expect(
      BeanPhotoService.ownedObjectKey(url, ownerId: owner, beanId: bean),
      legacy,
    );
    expect(
      BeanPhotoService.ownedObjectKey(current, ownerId: owner, beanId: bean),
      current,
    );
    expect(
      BeanPhotoService.ownedObjectKey(url, ownerId: 'other', beanId: bean),
      isNull,
    );
    expect(
      BeanPhotoService.ownedObjectKey(url, ownerId: owner, beanId: 'other'),
      isNull,
    );
  });

  test('signing an owned object requests a five-minute display link', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://api.timer.coffee',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'signedURL': '/object/sign/bean-photos/$current?token=short',
          }),
          200,
        );
      }),
    );
    addTearDown(client.dispose);
    final user = User(
      id: owner,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '',
    );
    final service = BeanPhotoService(client, () => user);
    expect(await service.readUrl(current, bean), contains('token=short'));
    expect(requests.single.url.path, endsWith('/bean-photos/$current'));
    expect(jsonDecode(requests.single.body)['expiresIn'], 300);
    expect(await service.readUrl(current, 'different-bean'), isNull);
    expect(requests, hasLength(1));
  });
}
