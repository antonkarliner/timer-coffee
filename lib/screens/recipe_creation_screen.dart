import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import '../models/brewing_method_model.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/database_provider.dart'; // Import DatabaseProvider
import '../database/database.dart';
import '../app_router.gr.dart'; // Import generated routes
import 'package:intl/intl.dart'; // Added for locale
import '../widgets/recipe_creation/recipe_details_form.dart';
import '../widgets/recipe_creation/recipe_steps_form.dart';
import '../services/recipe_expression_service.dart';
import '../services/recipe_save_service.dart';
import '../services/recipe_navigation_service.dart';
import '../widgets/unsaved_changes_dialog.dart';
import '../utils/app_logger.dart'; // Import AppLogger
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';

@RoutePage()
class RecipeCreationScreen extends StatefulWidget {
  final RecipeModel? recipe;
  final String? brewingMethodId;
  final bool redirectToNewDetailOnSave;

  const RecipeCreationScreen({
    Key? key,
    this.recipe,
    this.brewingMethodId,
    this.redirectToNewDetailOnSave = false,
  }) : super(key: key);

  @override
  State<RecipeCreationScreen> createState() => _RecipeCreationScreenState();
}

class _RecipeCreationScreenState extends State<RecipeCreationScreen>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _uuid = Uuid();
  late TextEditingController _recipeNameController;
  late TextEditingController _shortDescriptionController;

  // Recipe details
  String? _selectedBrewingMethodId;
  double _coffeeAmount = 15.0;
  double _waterAmount = 250.0;
  double? _waterTemp = 93.0;
  String _grindSize = 'Medium';
  int _brewMinutes = 3;
  int _brewSeconds = 0;

  // Recipe steps
  // Initialize _steps in initState to access context for l10n
  List<BrewStepModel> _steps = [];

  bool _isFirstPageValid = false;
  bool _isSecondPageValid = false;
  int _currentPage = 0;
  List<BrewingMethodModel> _brewingMethods = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false; // Added saving flag

  // Form change detection
  bool _hasUnsavedChanges = false;

  // Initial values for change detection (used when editing)
  String? _initialRecipeName;
  String? _initialShortDescription;
  String? _initialBrewingMethodId;
  double _initialCoffeeAmount = 15.0;
  double _initialWaterAmount = 250.0;
  double? _initialWaterTemp = 93.0;
  String _initialGrindSize = 'Medium';
  int _initialBrewMinutes = 3;
  int _initialBrewSeconds = 0;
  List<BrewStepModel> _initialSteps = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _recipeNameController = TextEditingController(text: '');
    _shortDescriptionController = TextEditingController(text: '');

    // Initialize _steps with default values first
    _steps = [
      // Preparation step (always present)
      BrewStepModel(
        id: _uuid.v4(),
        order: 1,
        description:
            '', // Will be updated with localized string in _initializeLocalizedData
        time: const Duration(seconds: 0),
      ),
      // First brew step
      BrewStepModel(
        id: _uuid.v4(),
        order: 2,
        description: '',
        time: const Duration(seconds: 30),
      ),
    ];

    // Initialize with existing recipe data if editing
    if (widget.recipe != null) {
      _selectedBrewingMethodId = widget.recipe!.brewingMethodId;
      _coffeeAmount = widget.recipe!.coffeeAmount;
      _waterAmount = widget.recipe!.waterAmount;
      _waterTemp = widget.recipe!.waterTemp;
      _grindSize = widget.recipe!.grindSize;
      _brewMinutes = widget.recipe!.brewTime.inMinutes;
      _brewSeconds = widget.recipe!.brewTime.inSeconds % 60;

      _recipeNameController.text = widget.recipe!.name;
      _shortDescriptionController.text = widget.recipe!.shortDescription;

      // Store initial values for change detection
      _initialRecipeName = widget.recipe!.name;
      _initialShortDescription = widget.recipe!.shortDescription;
      _initialBrewingMethodId = widget.recipe!.brewingMethodId;
      _initialCoffeeAmount = widget.recipe!.coffeeAmount;
      _initialWaterAmount = widget.recipe!.waterAmount;
      _initialWaterTemp = widget.recipe!.waterTemp;
      _initialGrindSize = widget.recipe!.grindSize;
      _initialBrewMinutes = widget.recipe!.brewTime.inMinutes;
      _initialBrewSeconds = widget.recipe!.brewTime.inSeconds % 60;

      // Initialize steps - convert expressions back to numeric values for editing
      if (widget.recipe!.steps.isNotEmpty) {
        _steps.clear();

        // Convert expressions back to numeric values for better editing experience
        List<BrewStepModel> convertedSteps = widget.recipe!.steps.map((step) {
          return BrewStepModel(
            id: step.id,
            order: step.order,
            description:
                RecipeExpressionService.convertExpressionsToNumericValues(
                    step.description, _coffeeAmount, _waterAmount),
            time: step.time,
            timePlaceholder: step.timePlaceholder,
          );
        }).toList();

        _steps.addAll(convertedSteps);

        // Store initial steps for change detection
        _initialSteps = List.from(convertedSteps);
      }
    } else {
      // For new recipes, store default values
      _initialRecipeName = '';
      _initialShortDescription = '';
      _initialBrewingMethodId = null;
      _initialCoffeeAmount = 15.0;
      _initialWaterAmount = 250.0;
      _initialWaterTemp = 93.0;
      _initialGrindSize = 'Medium';
      _initialBrewMinutes = 3;
      _initialBrewSeconds = 0;
      _initialSteps = List.from(_steps);
    }

    // Add listeners to text controllers
    _recipeNameController.addListener(_trackChanges);
    _shortDescriptionController.addListener(_trackChanges);

    _loadBrewingMethods();

    // Validate pages if editing
    if (widget.recipe != null) {
      _validateFirstPage();
      _validateSecondPage();
    }

    // Add post-frame callback to initialize localization-dependent data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeLocalizedData();
      }
    });
  }

  void _initializeLocalizedData() {
    final l10n = AppLocalizations.of(context)!;

    // Update the preparation step with localized description
    // Update the preparation step with localized description only if empty (for new recipes)
    if (_steps.isNotEmpty && _steps[0].description.isEmpty) {
      setState(() {
        _steps[0] = BrewStepModel(
          id: _steps[0].id,
          order: _steps[0].order,
          description: l10n.defaultPreparationStepDescription,
          time: _steps[0].time,
          timePlaceholder: _steps[0].timePlaceholder,
        );
      });
    }
  }

  Future<void> _loadBrewingMethods() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final methods = await database.brewingMethodsDao.getAllBrewingMethods();

    setState(() {
      _brewingMethods = methods;
      _isLoading = false;

      // If editing, use the recipe's brewing method as before.
      if (widget.recipe != null) {
        // Check if the pre-selected ID (from widget.recipe) is valid among loaded methods
        bool preselectedIdIsValid = _selectedBrewingMethodId != null &&
            methods.any((m) => m.brewingMethodId == _selectedBrewingMethodId);

        if (!preselectedIdIsValid && methods.isNotEmpty) {
          _selectedBrewingMethodId = methods.first.brewingMethodId;
        } else if (methods.isEmpty) {
          _selectedBrewingMethodId = null;
        }
      } else if (widget.brewingMethodId != null) {
        // If creating and brewingMethodId is provided, use it if valid
        final found =
            methods.any((m) => m.brewingMethodId == widget.brewingMethodId);
        if (found) {
          _selectedBrewingMethodId = widget.brewingMethodId;
        } else if (methods.isNotEmpty) {
          _selectedBrewingMethodId = methods.first.brewingMethodId;
        } else {
          _selectedBrewingMethodId = null;
        }
      } else {
        // If creating and no brewingMethodId, fallback to first available
        if (methods.isNotEmpty) {
          _selectedBrewingMethodId = methods.first.brewingMethodId;
        } else {
          _selectedBrewingMethodId = null;
        }
      }
    });
    _validateFirstPage();
  }

  void _validateFirstPage() {
    setState(() {
      _isFirstPageValid = _recipeNameController.text.isNotEmpty &&
          _shortDescriptionController.text.isNotEmpty &&
          _selectedBrewingMethodId != null &&
          _coffeeAmount > 0 &&
          _waterAmount > 0 &&
          _grindSize.isNotEmpty;
    });
  }

  void _validateSecondPage() {
    // Check if all steps have descriptions
    bool allStepsValid = _steps.every((step) => step.description.isNotEmpty);
    setState(() {
      _isSecondPageValid = allStepsValid;
    });
  }

  // Form change detection methods
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  void _trackChanges() {
    if (mounted) {
      setState(() {
        _hasUnsavedChanges = _checkForUnsavedChanges();
      });
    }
  }

  bool _checkForUnsavedChanges() {
    // For new recipes, check if any field has a non-default value
    if (widget.recipe == null) {
      return _recipeNameController.text.isNotEmpty ||
          _shortDescriptionController.text.isNotEmpty ||
          _selectedBrewingMethodId != _initialBrewingMethodId ||
          _coffeeAmount != _initialCoffeeAmount ||
          _waterAmount != _initialWaterAmount ||
          _waterTemp != _initialWaterTemp ||
          _grindSize != _initialGrindSize ||
          _brewMinutes != _initialBrewMinutes ||
          _brewSeconds != _initialBrewSeconds ||
          !_stepsEqual(_steps, _initialSteps);
    }

    // For existing recipes, compare with initial values
    return _recipeNameController.text != _initialRecipeName ||
        _shortDescriptionController.text != _initialShortDescription ||
        _selectedBrewingMethodId != _initialBrewingMethodId ||
        _coffeeAmount != _initialCoffeeAmount ||
        _waterAmount != _initialWaterAmount ||
        _waterTemp != _initialWaterTemp ||
        _grindSize != _initialGrindSize ||
        _brewMinutes != _initialBrewMinutes ||
        _brewSeconds != _initialBrewSeconds ||
        !_stepsEqual(_steps, _initialSteps);
  }

  bool _stepsEqual(List<BrewStepModel> steps1, List<BrewStepModel> steps2) {
    if (steps1.length != steps2.length) return false;

    for (int i = 0; i < steps1.length; i++) {
      if (steps1[i].description != steps2[i].description ||
          steps1[i].time != steps2[i].time) {
        return false;
      }
    }
    return true;
  }

  /// Check if the current recipe belongs to the signed-in user
  bool _isUserOwnedRecipe() {
    if (widget.recipe == null) return false;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;

    // Check if the recipe's vendorId matches the current user's ID pattern
    final userVendorId = 'usr-${currentUser.id}';
    return widget.recipe!.vendorId == userVendorId;
  }

  /// Show confirmation dialog before duplicating recipe
  Future<bool?> _showDuplicateConfirmationDialog() async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: Text(l10n.recipeDuplicateConfirmTitle),
        content: Text(l10n.recipeDuplicateConfirmMessage),
        actions: <Widget>[
          AppTextButton(
            label: l10n.dialogCancel,
            onPressed: () => Navigator.of(context).pop(false),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
          SizedBox(
            height: 56,
            child: AppElevatedButton(
              label: l10n.dialogDuplicate,
              onPressed: () => Navigator.of(context).pop(true),
              isFullWidth: false,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle duplicate recipe functionality
  Future<void> _duplicateRecipe() async {
    if (widget.recipe == null || !_isUserOwnedRecipe()) return;

    final confirmed = await _showDuplicateConfirmationDialog();

    if (confirmed != true) return; // User cancelled

    try {
      await RecipeNavigationService.navigateToCopyRecipe(
        context: context,
        recipeToCopy: widget.recipe!,
      );
    } catch (e) {
      AppLogger.error("Error duplicating recipe", errorObject: e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recipeCopyError(e.toString()))),
        );
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (!_isFirstPageValid || !_isSecondPageValid || _isSaving) {
      return;
    }
    // Update the order based on list index to reflect UI order
    for (int i = 0; i < _steps.length; i++) {
      _steps[i] = _steps[i].copyWith(order: i + 1);
    }

    setState(() => _isSaving = true);

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;

    final totalBrewTime = Duration(
      minutes: _brewMinutes,
      seconds: _brewSeconds,
    );

    // Process steps to convert numeric values to expressions before saving
    final processedSteps = RecipeExpressionService.processStepsForSaving(
        _steps, _coffeeAmount, _waterAmount, l10n);

    try {
      final bool isUpdate = widget.recipe != null;
      final String recipeId = isUpdate
          ? widget.recipe!.id!
          : 'usr-${currentUser?.id ?? 'anonymous'}-${DateTime.now().millisecondsSinceEpoch}';

      final recipeData = RecipeModel(
        id: recipeId,
        name: _recipeNameController.text,
        brewingMethodId: _selectedBrewingMethodId!,
        coffeeAmount: _coffeeAmount,
        waterAmount: _waterAmount,
        waterTemp: _waterTemp,
        grindSize: _grindSize,
        brewTime: totalBrewTime,
        shortDescription: _shortDescriptionController.text,
        steps: processedSteps,
        vendorId: isUpdate
            ? widget.recipe!.vendorId
            : 'usr-${currentUser?.id ?? 'anonymous'}',
        importId: isUpdate ? widget.recipe!.importId : null,
        isImported: isUpdate ? widget.recipe!.isImported : false,
      );

      await RecipeSaveService.save(
        recipeData,
        context,
        isUpdate: isUpdate,
        redirectToNewDetailOnSave: widget.redirectToNewDetailOnSave,
      );

      // Reset unsaved changes flag after successful save
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      AppLogger.error("Error in _saveRecipe", errorObject: e);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(l10n.recipeCreationScreenSaveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recipeNameController.removeListener(_trackChanges);
    _shortDescriptionController.removeListener(_trackChanges);
    _recipeNameController.dispose();
    _shortDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_hasUnsavedChanges) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => const UnsavedChangesDialog(),
          );

          if (shouldDiscard == true) {
            if (context.mounted) {
              context.router.pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_currentPage == 0 ? Icons.edit : Icons.format_list_numbered),
              const SizedBox(width: 8),
              Text(_currentPage == 0
                  ? (widget.recipe != null
                      ? l10n.recipeCreationScreenEditRecipeTitle
                      : l10n.recipeCreationScreenCreateRecipeTitle)
                  : l10n.recipeCreationScreenRecipeStepsTitle),
            ],
          ),
          leading: _currentPage == 1
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.keyboard_hide),
              onPressed: () {
                FocusScope.of(context).unfocus();
              },
            ),
            if (widget.recipe != null && _isUserOwnedRecipe())
              IconButton(
                icon: const Icon(Icons.content_copy),
                tooltip: l10n.tooltipDuplicateRecipe,
                onPressed: _duplicateRecipe,
              ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      RecipeDetailsForm(
                        recipeNameController: _recipeNameController,
                        shortDescriptionController: _shortDescriptionController,
                        brewingMethods: _brewingMethods,
                        selectedBrewingMethodId: _selectedBrewingMethodId,
                        coffeeAmount: _coffeeAmount,
                        waterAmount: _waterAmount,
                        waterTemp: _waterTemp,
                        grindSize: _grindSize,
                        brewMinutes: _brewMinutes,
                        brewSeconds: _brewSeconds,
                        onNameChanged: (value) {
                          _validateFirstPage();
                          _trackChanges();
                        },
                        onShortDescriptionChanged: (value) {
                          _validateFirstPage();
                          _trackChanges();
                        },
                        onBrewingMethodChanged: (value) {
                          setState(() {
                            _selectedBrewingMethodId = value;
                          });
                          _validateFirstPage();
                          _trackChanges();
                        },
                        onCoffeeAmountChanged: (value) {
                          setState(() {
                            _coffeeAmount = value;
                          });
                          _validateFirstPage();
                          _trackChanges();
                        },
                        onWaterAmountChanged: (value) {
                          setState(() {
                            _waterAmount = value;
                          });
                          _validateFirstPage();
                          _trackChanges();
                        },
                        onWaterTempChanged: (value) {
                          setState(() {
                            _waterTemp = value;
                          });
                          _trackChanges();
                        },
                        onGrindSizeChanged: (value) {
                          setState(() {
                            _grindSize = value;
                          });
                          _validateFirstPage();
                          _trackChanges();
                        },
                        onBrewMinutesChanged: (value) {
                          setState(() {
                            _brewMinutes = value;
                          });
                          _trackChanges();
                        },
                        onBrewSecondsChanged: (value) {
                          setState(() {
                            _brewSeconds = value;
                          });
                          _trackChanges();
                        },
                        onContinue: _isFirstPageValid
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                      RecipeStepsForm(
                        initialSteps: _steps,
                        scrollController: _scrollController,
                        onStepsChanged: (steps) {
                          setState(() {
                            _steps = steps;
                          });
                          _validateSecondPage();
                          _trackChanges();
                        },
                        isSaving: _isSaving,
                        onSave: (_isSecondPageValid && !_isSaving)
                            ? _saveRecipe
                            : null,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
