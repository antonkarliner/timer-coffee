import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated/schema.dart/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('migration from v39 to v40 applies cleanly', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(39);
    final db = AppDatabase(schema.newConnection());

    await verifier.migrateAndValidate(db, 40);

    await db.close();
    schema.close();
  });
}
