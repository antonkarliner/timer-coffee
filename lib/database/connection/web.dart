import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Obtains a database connection for running drift on the web.
Future<DatabaseConnection> connect() async {
  final db = await WasmDatabase.open(
    databaseName: 'db.sqlite',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  if (db.missingFeatures.isNotEmpty) {
    debugPrint('Using ${db.chosenImplementation} due to unsupported '
        'browser features: ${db.missingFeatures}');
  }

  return DatabaseConnection(db.resolvedExecutor);
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  // Schema validation logic here
  // Note: Schema validation is not supported on the web at this time
}
