part of 'database.dart';

@DriftAccessor(tables: [Steps])
class StepsDao extends DatabaseAccessor<AppDatabase> with _$StepsDaoMixin {
  final AppDatabase db;

  StepsDao(this.db) : super(db);

  Future<List<BrewStepModel>> getLocalizedBrewStepsForRecipe(
      String recipeId, String locale) async {
    late final Selectable<Step> query;

    if (recipeId.startsWith('usr-')) {
      // For user recipes, ignore the locale and fetch steps based only on recipeId
      query = select(db.steps)
        ..where((tbl) => tbl.recipeId.equals(recipeId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.stepOrder, mode: OrderingMode.asc)
        ]);
    } else {
      // For standard recipes, fetch based on recipeId and locale
      query = select(db.steps)
        ..where(
            (tbl) => tbl.recipeId.equals(recipeId) & tbl.locale.equals(locale))
        ..orderBy([
          (t) => OrderingTerm(expression: t.stepOrder, mode: OrderingMode.asc)
        ]);
    }

    final steps = await query.get();
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

  Future<void> deleteStep(int stepOrder, String recipeId, String locale) async {
    await (delete(steps)
          ..where((t) =>
              t.stepOrder.equals(stepOrder) &
              t.recipeId.equals(recipeId) &
              t.locale.equals(locale)))
        .go();
  }

  Future<void> deleteStepsForRecipe(String recipeId) async {
    await (delete(steps)..where((t) => t.recipeId.equals(recipeId))).go();
  }

  Future<List<Step>> getStepsForRecipe(String recipeId) async {
    final query = select(db.steps)
      ..where((tbl) => tbl.recipeId.equals(recipeId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.stepOrder, mode: OrderingMode.asc)
      ]);
    return query.get();
  }
}
