import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/recipe_model.dart';

class CreatedListSection extends StatelessWidget {
  final String title;
  final String emptyHint;
  final List<RecipeModel> recipes;
  final ValueListenable<bool> editModeListenable;
  final Widget Function(BuildContext, RecipeModel) itemBuilder;

  const CreatedListSection({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.recipes,
    required this.editModeListenable,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (recipes.isEmpty)
            Semantics(
              identifier: 'userRecipesEmptyCreated',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  emptyHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
              ),
            )
          else
            ...List.generate(
              recipes.length,
              (index) => itemBuilder(context, recipes[index]),
            ),
        ],
      ),
    );
  }
}
