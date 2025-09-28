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
      }
    }

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
    } catch (e) {
      print("Error in _saveRecipe: $e");
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
    _recipeNameController.dispose();
    _shortDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
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
        ],
      ),
      body: _isLoading
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
                    },
                    onShortDescriptionChanged: (value) {
                      _validateFirstPage();
                    },
                    onBrewingMethodChanged: (value) {
                      setState(() {
                        _selectedBrewingMethodId = value;
                      });
                      _validateFirstPage();
                    },
                    onCoffeeAmountChanged: (value) {
                      setState(() {
                        _coffeeAmount = value;
                      });
                      _validateFirstPage();
                    },
                    onWaterAmountChanged: (value) {
                      setState(() {
                        _waterAmount = value;
                      });
                      _validateFirstPage();
                    },
                    onWaterTempChanged: (value) {
                      setState(() {
                        _waterTemp = value;
                      });
                    },
                    onGrindSizeChanged: (value) {
                      setState(() {
                        _grindSize = value;
                      });
                      _validateFirstPage();
                    },
                    onBrewMinutesChanged: (value) {
                      setState(() {
                        _brewMinutes = value;
                      });
                    },
                    onBrewSecondsChanged: (value) {
                      setState(() {
                        _brewSeconds = value;
                      });
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
                    },
                    isSaving: _isSaving,
                    onSave:
                        (_isSecondPageValid && !_isSaving) ? _saveRecipe : null,
                  ),
                ],
              ),
            ),
    );
  }
}
