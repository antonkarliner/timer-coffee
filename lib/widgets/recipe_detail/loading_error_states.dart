import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Widget that displays a loading state with a basic app bar and circular progress indicator
class RecipeLoadingState extends StatelessWidget {
  const RecipeLoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Widget that displays an error state with a basic app bar and error message
class RecipeErrorState extends StatelessWidget {
  final String? errorMessage;

  const RecipeErrorState({
    Key? key,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = errorMessage ?? l10n.recipeLoadErrorGeneric;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Widget that displays when recipe is null after successful loading check
class RecipeNotFoundState extends StatelessWidget {
  const RecipeNotFoundState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Text(
          l10n.recipeLoadErrorGeneric,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
