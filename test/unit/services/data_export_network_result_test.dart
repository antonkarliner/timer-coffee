import 'package:coffee_timer/services/data_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_database.dart';

/// Pins that a network failure talking to the `export-user-data` edge
/// function maps to [DataExportNetworkError] — the variant
/// `data_export_section.dart` reports as `data_export_failed` with
/// `reason: networkError` through its exhaustive switch (the event side is
/// covered in `test/unit/widgets/data_export_section_analytics_test.dart`).
///
/// This file deliberately contains no `testWidgets`: initializing the test
/// binding installs a process-wide fake `HttpOverrides.global` that answers
/// every request with an empty 400 (which the service would map to
/// `expiredOrNoRequest` — asserting the fake, not our code). In a
/// plain-zone-only isolate there is no fake, so this drives a real socket
/// against a dead port and gets a connection refusal, which http surfaces
/// as a plain exception — exactly what `requestCode` maps to
/// [DataExportNetworkError]. (Mixing `HttpOverrides.runZoned` into a file
/// that also ran `testWidgets` stack-overflows inside `HttpOverrides.current`
/// — a flutter_test/Dart-SDK zone-scope bug — hence the separate file.)
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // Port 59999 has no listener: connection refused is immediate, offline,
    // and deterministic — standing in for a dead edge-function host.
    await Supabase.initialize(
      url: 'http://localhost:59999',
      anonKey: 'test-anon-key',
    );
  });

  test('a connection failure maps to DataExportNetworkError', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final service = DataExportService(database: database);

    final result = await service.requestCode('user@example.com');

    expect(result, isA<DataExportNetworkError>());
  });
}
