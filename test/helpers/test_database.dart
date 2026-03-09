import 'package:coffee_timer/database/database.dart';
import 'package:drift/native.dart';

/// Creates an in-memory Drift database for DAO tests.
/// FK constraints are disabled so tests can insert rows without seeding
/// all referenced tables.
AppDatabase openTestDatabase() {
  return AppDatabase(
    NativeDatabase.memory(),
    enableForeignKeyConstraints: false,
  );
}
