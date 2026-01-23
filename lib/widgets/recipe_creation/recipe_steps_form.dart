import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import '../../models/brew_step_model.dart';

class RecipeStepsForm extends StatefulWidget {
  final List<BrewStepModel> initialSteps;
  final ScrollController scrollController;
  final ValueChanged<List<BrewStepModel>> onStepsChanged;
  final bool isSaving;
  final VoidCallback? onSave;

  const RecipeStepsForm({
    super.key,
    required this.initialSteps,
    required this.scrollController,
    required this.onStepsChanged,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<RecipeStepsForm> createState() => _RecipeStepsFormState();
}

class _RecipeStepsFormState extends State<RecipeStepsForm> {
  late List<BrewStepModel> _steps;
  late final Uuid _uuid;

  @override
  void initState() {
    super.initState();
    _uuid = const Uuid();
    _steps = List<BrewStepModel>.from(widget.initialSteps);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepsChanged(_steps);
    });
  }

  void _addStep() {
    setState(() {
      _steps.add(
        BrewStepModel(
          id: _uuid.v4(),
          order: _steps.length + 1,
          description: '',
          time: const Duration(seconds: 30),
        ),
      );
    });
    widget.onStepsChanged(_steps);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeStep(int index) {
    if (index > 0) {
      setState(() {
        _steps.removeAt(index);
        for (int i = 0; i < _steps.length; i++) {
          _steps[i] = _steps[i].copyWith(order: i + 1);
        }
      });
      widget.onStepsChanged(_steps);
    }
  }

  void _updateStepDescription(int index, String description) {
    setState(() {
      _steps[index] = _steps[index].copyWith(description: description);
    });
    widget.onStepsChanged(_steps);
  }

  void _updateStepTime(int index, Duration time) {
    setState(() {
      _steps[index] = _steps[index].copyWith(time: time);
    });
    widget.onStepsChanged(_steps);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == 0) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex == 0) {
      newIndex = 1;
    }
    setState(() {
      final BrewStepModel item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = _steps[i].copyWith(order: i + 1);
      }
    });
    widget.onStepsChanged(_steps);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollController: widget.scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _steps.length,
              onReorder: _onReorder,
              itemBuilder: (BuildContext context, int index) {
                final step = _steps[index];
                final isPreparationStep = index == 0;
                return StepCard(
                  key: ValueKey(step.id),
                  step: step,
                  isPreparationStep: isPreparationStep,
                  l10n: l10n,
                  displayIndex: index.toString(),
                  onDescriptionChanged: (value) =>
                      _updateStepDescription(index, value),
                  onTimeChanged: isPreparationStep
                      ? null
                      : (value) => _updateStepTime(index, value),
                  onDelete: index > 0 ? () => _removeStep(index) : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppElevatedButton(
                    label: l10n.recipeCreationScreenAddStepButton,
                    onPressed: _addStep,
                    icon: Icons.add,
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppElevatedButton(
                    label: l10n.recipeCreationScreenSaveRecipeButton,
                    onPressed: widget.onSave,
                    isLoading: widget.isSaving,
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class StepCard extends StatelessWidget {
  final BrewStepModel step;
  final bool isPreparationStep;
  final AppLocalizations l10n;
  final String displayIndex;
  final Function(String) onDescriptionChanged;
  final Function(Duration)? onTimeChanged;
  final VoidCallback? onDelete;

  const StepCard({
    Key? key,
    required this.step,
    required this.isPreparationStep,
    required this.l10n,
    required this.displayIndex,
    required this.onDescriptionChanged,
    this.onTimeChanged,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!isPreparationStep) ...[
                  const Icon(Icons.drag_handle),
                  const SizedBox(width: 8),
                ],
                isPreparationStep
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          l10n.recipeCreationScreenPreparationStepTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Text(
                        l10n.recipeCreationScreenBrewStepTitle(displayIndex),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                const Spacer(),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: step.description,
              decoration: InputDecoration(
                labelText: l10n.recipeCreationScreenStepDescriptionLabel,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => onDescriptionChanged(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.recipeCreationScreenStepDescriptionValidator;
                }
                return null;
              },
            ),
            if (!isPreparationStep) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l10n.recipeCreationScreenStepTimeLabel),
                  Expanded(
                    child: TextFormField(
                      initialValue: step.time.inSeconds.toString(),
                      decoration: InputDecoration(
                        labelText: l10n.recipeCreationScreenSecondsLabel,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        final seconds = int.tryParse(value) ?? 0;
                        onTimeChanged?.call(Duration(seconds: seconds));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
