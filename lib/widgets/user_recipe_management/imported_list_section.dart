import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';

class ImportedListSection extends StatelessWidget {
  final String title;
  final String emptyHint;
  final List<RecipeModel> recipes;
  final Widget Function(BuildContext, RecipeModel) itemBuilder;
  final bool isEditable;

  const ImportedListSection({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.recipes,
    required this.itemBuilder,
    this.isEditable = false,
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
              identifier: 'userRecipesEmptyImported',
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
