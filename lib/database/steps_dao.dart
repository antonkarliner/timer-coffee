part of 'database.dart';

@DriftAccessor(tables: [Steps])
class StepsDao extends DatabaseAccessor<AppDatabase> with _$StepsDaoMixin {
  final AppDatabase db;

  StepsDao(this.db) : super(db);

  Future<List<BrewStepModel>> getLocalizedBrewStepsForRecipe(
      String recipeId, String locale) async {
    final steps = await (select(db.steps)
          ..where((tbl) =>
              tbl.recipeId.equals(recipeId) & tbl.locale.equals(locale))
          ..orderBy([
            (t) => OrderingTerm(expression: t.stepOrder, mode: OrderingMode.asc)
          ])) // Added orderBy clause here
        .get();
    return steps.map((step) => _fromEntity(step)).toList();
  }

  BrewStepModel _fromEntity(Step step) {
    int? seconds = int.tryParse(step.time);
    Duration timeDuration =
        seconds != null ? Duration(seconds: seconds) : Duration.zero;
    String? timePlaceholder;
    if (step.time.contains('<')) {
      timePlaceholder = step.time;
      timeDuration = Duration.zero;
    }

    return BrewStepModel(
      order: step.stepOrder,
      description: step.description,
      time: timeDuration,
      timePlaceholder: timePlaceholder,
    );
  }

  Future<void> insertOrUpdateStep(StepsCompanion step) async {
    await into(steps).insertOnConflictUpdate(step);
  }

  // Optional: Add a method to convert BrewStepModel back to a Step entity if needed for database operations
}
