import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:uuid/uuid.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../models/brewing_method_model.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../database/database.dart';
import '../utils/icon_utils.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../app_router.gr.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../widgets/roaster_logo.dart';
import '../services/roaster_logo_service.dart';
import '../widgets/unsaved_changes_dialog.dart';
import '../widgets/fields/date_field.dart';
import '../widgets/fields/time_field.dart';

@RoutePage()
class ManualBrewEntryScreen extends StatefulWidget {
  const ManualBrewEntryScreen({Key? key}) : super(key: key);

  @override
  State<ManualBrewEntryScreen> createState() => _ManualBrewEntryScreenState();
}

class _ManualBrewEntryScreenState extends State<ManualBrewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Form controllers
  final TextEditingController _coffeeController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _grindSizeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  List<BrewingMethodModel> _brewingMethods = [];
  String? _selectedBrewingMethodId;
  List<RecipeModel> _recipesForMethod = [];
  RecipeModel? _selectedRecipe;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Bean selection
  String? _selectedBeanUuid;
  String? _selectedBeanName;
  String? _selectedBeanRoasterLogoUrl;
  String? _selectedBeanMirrorLogoUrl;

  bool _isLoading = true;
  bool _isSaving = false;

  // Validation errors (manual since InputDecorator doesn't use Form validators)
  String? _brewingMethodError;
  String? _recipeError;

  bool get _hasUnsavedChanges =>
      _selectedBrewingMethodId != null ||
      _selectedRecipe != null ||
      _coffeeController.text.isNotEmpty ||
      _waterController.text.isNotEmpty ||
      _grindSizeController.text.isNotEmpty ||
      _notesController.text.isNotEmpty ||
      _selectedBeanUuid != null;

  @override
  void initState() {
    super.initState();
    _loadBrewingMethods();
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    _waterController.dispose();
    _grindSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBrewingMethods() async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final methods = await db.brewingMethodsDao.getAllBrewingMethods();
    setState(() {
      _brewingMethods = methods;
      _isLoading = false;
    });
  }

  Future<void> _loadRecipesForMethod(String brewingMethodId) async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final recipes =
        await recipeProvider.fetchRecipesForBrewingMethod(brewingMethodId);
    setState(() {
      _recipesForMethod = recipes;
      _selectedRecipe = null;
    });
  }

  void _onRecipeSelected(RecipeModel recipe) {
    setState(() {
      _selectedRecipe = recipe;
      _coffeeController.text =
          (recipe.customCoffeeAmount ?? recipe.coffeeAmount).toString();
      _waterController.text =
          (recipe.customWaterAmount ?? recipe.waterAmount).toString();
      _grindSizeController.text = recipe.customGrindSize ?? recipe.grindSize;
    });
  }

  void _onDateChanged(String? isoString) {
    if (isoString != null) {
      setState(() => _selectedDate = DateTime.parse(isoString));
    }
  }

  void _onTimeChanged(TimeOfDay? time) {
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _openAddBeansPopup() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AddCoffeeBeansWidget(
          onSelect: (String selectedBeanUuid) async {
            final coffeeBeansProvider =
                Provider.of<CoffeeBeansProvider>(context, listen: false);
            final bean =
                await coffeeBeansProvider.fetchCoffeeBeansByUuid(selectedBeanUuid);
            setState(() {
              _selectedBeanUuid = selectedBeanUuid;
              _selectedBeanName = bean?.name;
              _selectedBeanRoasterLogoUrl = null;
              _selectedBeanMirrorLogoUrl = null;
            });
            Navigator.of(dialogContext).pop();
            // Fetch roaster logo in background, guard against stale result
            if (bean != null && bean.roaster.isNotEmpty) {
              final capturedUuid = selectedBeanUuid;
              final logoResult = await const RoasterLogoService()
                  .fetchRoasterLogos(context, bean.roaster);
              if (logoResult.isSuccess &&
                  mounted &&
                  _selectedBeanUuid == capturedUuid) {
                setState(() {
                  _selectedBeanRoasterLogoUrl = logoResult.originalUrl;
                  _selectedBeanMirrorLogoUrl = logoResult.mirrorUrl;
                });
              }
            }
          },
        );
      },
    );
  }

  void _showBrewingMethodDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            loc.selectBrewingMethod,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _brewingMethods.length,
              itemBuilder: (context, index) {
                final method = _brewingMethods[index];
                final isSelected =
                    method.brewingMethodId == _selectedBrewingMethodId;
                return ListTile(
                  leading: getIconByBrewingMethod(method.brewingMethodId),
                  title: Text(
                    method.brewingMethod,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _selectedBrewingMethodId = method.brewingMethodId;
                      _brewingMethodError = null;
                    });
                    _loadRecipesForMethod(method.brewingMethodId);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showRecipeDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            loc.selectRecipe,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Icon(Icons.add,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(
                    loc.createRecipe,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    final result = await context.router.push(
                      RecipeCreationRoute(
                        brewingMethodId: _selectedBrewingMethodId,
                        popWithResultOnSave: true,
                      ),
                    );
                    // If a recipe was created and returned, select it
                    if (result is RecipeModel && mounted) {
                      // Refresh the recipe provider cache so the new
                      // recipe appears in fetchRecipesForBrewingMethod
                      final recipeProvider = Provider.of<RecipeProvider>(
                          context,
                          listen: false);
                      await recipeProvider.fetchAllRecipes();

                      // Ensure brewing method matches
                      if (_selectedBrewingMethodId !=
                          result.brewingMethodId) {
                        setState(() {
                          _selectedBrewingMethodId =
                              result.brewingMethodId;
                        });
                      }
                      await _loadRecipesForMethod(
                          result.brewingMethodId);

                      // Find the recipe in the loaded list and select it
                      final match = _recipesForMethod
                          .where((r) => r.id == result.id)
                          .firstOrNull;
                      if (match != null) {
                        _onRecipeSelected(match);
                        setState(() => _recipeError = null);
                      } else {
                        // Fallback: use returned data directly
                        _onRecipeSelected(result);
                        setState(() => _recipeError = null);
                      }
                    } else if (_selectedBrewingMethodId != null) {
                      // User cancelled recipe creation; just reload
                      await _loadRecipesForMethod(
                          _selectedBrewingMethodId!);
                    }
                  },
                ),
                const Divider(),
                ..._recipesForMethod.map((recipe) {
                  final isSelected = _selectedRecipe?.id == recipe.id;
                  return ListTile(
                    title: Text(
                      recipe.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _onRecipeSelected(recipe);
                      setState(() => _recipeError = null);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveEntry() async {
    // Validate selectors manually
    final loc = AppLocalizations.of(context)!;
    bool hasErrors = false;
    if (_selectedBrewingMethodId == null) {
      setState(() => _brewingMethodError = loc.brewingMethodRequired);
      hasErrors = true;
    }
    if (_selectedRecipe == null) {
      setState(() => _recipeError = loc.recipeRequired);
      hasErrors = true;
    }
    if (!_formKey.currentState!.validate() || hasErrors) return;

    setState(() => _isSaving = true);

    try {
      final coffeeAmount =
          double.tryParse(_coffeeController.text.replaceAll(',', '.')) ?? 0;
      final waterAmount =
          double.tryParse(_waterController.text.replaceAll(',', '.')) ?? 0;
      final grindSize = _grindSizeController.text.trim().isEmpty
          ? null
          : _grindSizeController.text.trim();

      // Combine date and time
      final createdAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toUtc();

      final statUuid = _uuid.v7();

      await Provider.of<UserStatProvider>(context, listen: false).insertUserStat(
        recipeId: _selectedRecipe!.id,
        coffeeAmount: coffeeAmount,
        waterAmount: waterAmount,
        sweetnessSliderPosition: 1,
        strengthSliderPosition: 1,
        brewingMethodId: _selectedRecipe!.brewingMethodId,
        statUuid: statUuid,
        coffeeBeansUuid: _selectedBeanUuid,
        grindSize: grindSize,
        createdAt: createdAt,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Update bean weight if beans selected
      if (_selectedBeanUuid != null && coffeeAmount > 0) {
        final coffeeBeansProvider =
            Provider.of<CoffeeBeansProvider>(context, listen: false);
        await coffeeBeansProvider.updateBeanWeightAfterBrew(
          _selectedBeanUuid!,
          coffeeAmount,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.brewEntrySaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        if (_hasUnsavedChanges) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (_) => const UnsavedChangesDialog(),
          );

          if (shouldDiscard == true && mounted) {
            context.router.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline),
              const SizedBox(width: 8),
              Text(loc.addBrewEntry),
            ],
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brewing Method selector
                      InkWell(
                        onTap: () => _showBrewingMethodDialog(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: loc.selectBrewingMethod,
                            border: const OutlineInputBorder(),
                            suffixIcon:
                                const Icon(Icons.keyboard_arrow_down),
                            errorText: _brewingMethodError,
                          ),
                          child: _selectedBrewingMethodId != null
                              ? Row(
                                  children: [
                                    getIconByBrewingMethod(
                                        _selectedBrewingMethodId!),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _brewingMethods
                                            .firstWhere((m) =>
                                                m.brewingMethodId ==
                                                _selectedBrewingMethodId)
                                            .brewingMethod,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recipe selector
                      if (_selectedBrewingMethodId != null) ...[
                        InkWell(
                          onTap: () => _showRecipeDialog(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: loc.selectRecipe,
                              border: const OutlineInputBorder(),
                              suffixIcon:
                                  const Icon(Icons.keyboard_arrow_down),
                              errorText: _recipeError,
                            ),
                            child: _selectedRecipe != null
                                ? Text(
                                    _selectedRecipe!.name,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Coffee and Water amounts
                      if (_selectedRecipe != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _coffeeController,
                                decoration: InputDecoration(
                                  labelText: loc.coffeeamount,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return loc.coffeeamount;
                                  }
                                  if (double.tryParse(
                                          value.replaceAll(',', '.')) ==
                                      null) {
                                    return loc.coffeeamount;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _waterController,
                                decoration: InputDecoration(
                                  labelText: loc.wateramount,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return loc.wateramount;
                                  }
                                  if (double.tryParse(
                                          value.replaceAll(',', '.')) ==
                                      null) {
                                    return loc.wateramount;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Grind Size
                        TextFormField(
                          controller: _grindSizeController,
                          decoration: InputDecoration(
                            labelText: loc.grindsize,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date and Time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DateField(
                                label: loc.brewDate,
                                initialValue:
                                    _selectedDate.toIso8601String(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                showClearButton: false,
                                onChanged: _onDateChanged,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TimeField(
                                label: loc.brewTime,
                                initialValue: _selectedTime,
                                onChanged: _onTimeChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Beans selection
                        Container(
                          decoration: _selectedBeanName != null
                              ? BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: InkWell(
                            onTap: _openAddBeansPopup,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: loc.selectBeans,
                                border: const OutlineInputBorder(),
                              suffixIcon: _selectedBeanName != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _selectedBeanUuid = null;
                                          _selectedBeanName = null;
                                          _selectedBeanRoasterLogoUrl = null;
                                          _selectedBeanMirrorLogoUrl = null;
                                        });
                                      },
                                    )
                                  : const Icon(Icons.keyboard_arrow_down),
                            ),
                            child: _selectedBeanName != null
                                ? Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 14),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 48,
                                            maxHeight: 24,
                                          ),
                                          child: RoasterLogo(
                                            key: ValueKey(
                                                _selectedBeanUuid ?? ''),
                                            originalUrl:
                                                _selectedBeanRoasterLogoUrl,
                                            mirrorUrl:
                                                _selectedBeanMirrorLogoUrl,
                                            height: 24,
                                            borderRadius: 4,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _selectedBeanName!,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: loc.notes,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        AppElevatedButton(
                          label: loc.save,
                          onPressed: _isSaving ? null : _saveEntry,
                          isFullWidth: true,
                          height: AppButton.heightLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
