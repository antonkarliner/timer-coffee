import 'package:coffee_timer/database/account_database_scope.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/services/data_export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('a connection failure maps to DataExportNetworkError', () async {
    final scope = AccountDatabaseScope(
      userId: 'test-user',
      partitionId: 'user:test-user',
      supabaseUrl: 'https://example.test',
      supabaseKey: 'test-key',
      currentSession: () => Session(
        accessToken: 'test-token',
        tokenType: 'bearer',
        user: const User(
          id: 'test-user',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '',
        ),
      ),
      httpClient: MockClient((_) async => throw ClientException('Offline')),
    );
    final database = AppDatabase(NativeDatabase.memory(), accountScope: scope);
    addTearDown(scope.client.dispose);
    addTearDown(database.close);
    final service = DataExportService(database: database);

    expect(
      await service.requestCode('user@example.com'),
      isA<DataExportNetworkError>(),
    );
  });
}
