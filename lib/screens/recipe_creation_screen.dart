import 'dart:async'; // Added for TimeoutException
import 'dart:io'; // Added for SocketException
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import '../models/brewing_method_model.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/database_provider.dart'; // Import DatabaseProvider
import '../database/database.dart';
import '../app_router.gr.dart'; // Import generated routes
import 'package:intl/intl.dart'; // Added for locale

@RoutePage()
class RecipeCreationScreen extends StatefulWidget {
  final RecipeModel? recipe;

  const RecipeCreationScreen({Key? key, this.recipe}) : super(key: key);

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
  String _recipeName = '';
  String _shortDescription = '';
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

    // Initialize _steps with default values first
    _steps = [
      // Preparation step (always present)
      BrewStepModel(
        order: 1,
        description:
            '', // Will be updated with localized string in _initializeLocalizedData
        time: const Duration(seconds: 0),
      ),
      // First brew step
      BrewStepModel(
        order: 2,
        description: '',
        time: const Duration(seconds: 30),
      ),
    ];

    // Initialize with existing recipe data if editing
    if (widget.recipe != null) {
      _recipeName = widget.recipe!.name;
      _shortDescription = widget.recipe!.shortDescription;
      _selectedBrewingMethodId = widget.recipe!.brewingMethodId;
      _coffeeAmount = widget.recipe!.coffeeAmount;
      _waterAmount = widget.recipe!.waterAmount;
      _waterTemp = widget.recipe!.waterTemp;
      _grindSize = widget.recipe!.grindSize;
      _brewMinutes = widget.recipe!.brewTime.inMinutes;
      _brewSeconds = widget.recipe!.brewTime.inSeconds % 60;

      // Initialize steps - convert expressions back to numeric values for editing
      if (widget.recipe!.steps.isNotEmpty) {
        _steps.clear();

        // Convert expressions back to numeric values for better editing experience
        List<BrewStepModel> convertedSteps = widget.recipe!.steps.map((step) {
          return BrewStepModel(
            order: step.order,
            description: _convertExpressionsToNumericValues(step.description),
            time: step.time,
            timePlaceholder: step.timePlaceholder,
          );
        }).toList();

        _steps.addAll(convertedSteps);
      }
    }

    _recipeNameController = TextEditingController(text: _recipeName);
    _shortDescriptionController =
        TextEditingController(text: _shortDescription);
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
    if (_steps.isNotEmpty) {
      setState(() {
        _steps[0] = BrewStepModel(
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

      // Check if the pre-selected ID (from widget.recipe) is valid among loaded methods
      bool preselectedIdIsValid = _selectedBrewingMethodId != null &&
          methods.any((m) => m.brewingMethodId == _selectedBrewingMethodId);

      // If the pre-selected ID is not valid OR if no ID was pre-selected,
      // default to the first available method.
      if (!preselectedIdIsValid && methods.isNotEmpty) {
        _selectedBrewingMethodId = methods.first.brewingMethodId;
      } else if (methods.isEmpty) {
        // Handle case where no brewing methods are loaded at all
        _selectedBrewingMethodId = null;
      }
      // Otherwise, keep the valid pre-selected ID.
    });
    // Re-validate the first page as the brewing method might have changed/been set.
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

  void _addStep() {
    setState(() {
      _steps.add(
        BrewStepModel(
          order: _steps.length + 1,
          description: '',
          time: const Duration(seconds: 30),
        ),
      );
      _validateSecondPage();

      // Scroll to the new card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _removeStep(int index) {
    if (index > 0) {
      // Don't remove preparation step
      setState(() {
        _steps.removeAt(index);

        // Update order of remaining steps
        for (int i = 0; i < _steps.length; i++) {
          _steps[i] = BrewStepModel(
            order: i + 1,
            description: _steps[i].description,
            time: _steps[i].time,
          );
        }
      });
      _validateSecondPage();
    }
  }

  void _updateStepDescription(int index, String description) {
    setState(() {
      _steps[index] = BrewStepModel(
        order: _steps[index].order,
        description: description,
        time: _steps[index].time,
      );
    });
    _validateSecondPage();
  }

  void _updateStepTime(int index, Duration time) {
    setState(() {
      _steps[index] = BrewStepModel(
        order: _steps[index].order,
        description: _steps[index].description,
        time: time,
      );
    });
  }

  // Determines the cleanest multiplier for a numeric value
  Map<String, dynamic> _getCleanestMultiplier(double value) {
    double coffeeMult = value / _coffeeAmount;
    double waterMult = value / _waterAmount;

    double coffeeCleanScore = _calculateCleanScore(coffeeMult);
    double waterCleanScore = _calculateCleanScore(waterMult);

    if (coffeeCleanScore > waterCleanScore) {
      return {
        'multiplier': coffeeMult,
        'type': 'coffee',
        'formatted': _formatMultiplier(coffeeMult)
      };
    } else {
      return {
        'multiplier': waterMult,
        'type': 'water',
        'formatted': _formatMultiplier(waterMult)
      };
    }
  }

  // Calculates how "clean" a multiplier is (higher score = cleaner)
  double _calculateCleanScore(double number) {
    // Check if it's a whole number or very close to one
    if ((number - number.round()).abs() < 0.01) {
      return 100 - (number - number.round()).abs() * 100;
    }

    // Check if it's a simple fraction
    List<double> simpleRatios = [
      0.25,
      0.33,
      0.5,
      0.67,
      0.75,
      1.25,
      1.33,
      1.5,
      1.67,
      1.75,
      2.5,
      3.5
    ];
    for (double ratio in simpleRatios) {
      if ((ratio - number).abs() < 0.01) {
        return 90 - (ratio - number).abs() * 100;
      }
    }

    // Otherwise, score based on decimal places
    int decimalPlaces = number.toString().split('.').length > 1
        ? number.toString().split('.')[1].length
        : 0;
    return 80 - (decimalPlaces * 10);
  }

  // Formats the multiplier to be readable
  String _formatMultiplier(double multiplier) {
    // Format the multiplier to be readable, with minimal decimal places
    if ((multiplier - multiplier.round()).abs() < 0.01) {
      return multiplier.round().toString();
    }

    // Otherwise return with minimal decimal places
    return multiplier.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  // Converts expressions back to numeric values for editing
  String _convertExpressionsToNumericValues(String description) {
    // Match expressions like (2 x <final_coffee_amount>) or (0.5 x <final_water_amount>)
    final RegExp expressionRegex = RegExp(
        r'\((\d+(?:\.\d+)?)\s*x\s*<final_(?:coffee|water)_amount>\)(\w*)');

    return description.replaceAllMapped(expressionRegex, (match) {
      // Extract the multiplier and unit (if any)
      String multiplierStr = match.group(1)!;
      String unit = match.group(2) ?? '';

      double multiplier = double.tryParse(multiplierStr) ?? 0;

      // Calculate the actual value based on the type
      String placeholder = match.group(0)!;
      double value;

      if (placeholder.contains('<final_coffee_amount>')) {
        value = multiplier * _coffeeAmount;
      } else {
        value = multiplier * _waterAmount;
      }

      // Format the value with appropriate precision
      String formattedValue;
      if (value == value.roundToDouble()) {
        formattedValue = value.round().toString();
      } else {
        formattedValue =
            value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      }

      // Return the numeric value with the unit
      return '$formattedValue$unit';
    });
  }

  // Converts numeric values in step descriptions to expressions
  String _convertNumericValuesToExpressions(String description) {
    // Patterns to explicitly exclude from conversion
    final RegExp excludeRegex = RegExp(
        r'\b\d+\s*(?:-|to)\s*\d+\s*times\b|\b\d+\s*times\b|\b\d+\s*(?:seconds?|minutes?|mins?)\b');

    // First check if the description contains any exclude patterns
    if (excludeRegex.hasMatch(description)) {
      // Process the description in parts to avoid converting excluded patterns
      List<String> parts = [];
      int lastEnd = 0;

      for (var match in excludeRegex.allMatches(description)) {
        // Add the part before the excluded pattern (processed)
        if (match.start > lastEnd) {
          parts.add(
              _processTextPart(description.substring(lastEnd, match.start)));
        }

        // Add the excluded pattern unchanged
        parts.add(description.substring(match.start, match.end));
        lastEnd = match.end;
      }

      // Add any remaining text (processed)
      if (lastEnd < description.length) {
        parts.add(_processTextPart(description.substring(lastEnd)));
      }

      return parts.join('');
    } else {
      // No excluded patterns, process normally
      return _processTextPart(description);
    }
  }

  // Process a part of text to convert measurements to expressions
  String _processTextPart(String text) {
    final l10n = AppLocalizations.of(context)!; // Get localizations

    // Build the regex dynamically using localized units
    final String unitsPattern = [
      l10n.unitGramsShort,
      l10n.unitMillilitersShort,
      l10n.unitGramsLong,
      l10n.unitMillilitersLong,
    ].map((unit) => RegExp.escape(unit)).join('|');

    // Match numbers that are likely measurements:
    // 1. Numbers followed by localized units
    // 2. Numbers above threshold (10) that are likely measurements
    final RegExp measurementWithUnitsRegex =
        RegExp(r'\b(\d+(?:\.\d+)?)\s*(' + unitsPattern + r')\b');

    final RegExp largeNumberRegex = RegExp(r'\b(\d{2,}(?:\.\d+)?)\b');

    // First handle numbers with units to preserve the units
    String processedText =
        text.replaceAllMapped(measurementWithUnitsRegex, (match) {
      String numStr = match.group(1)!;
      String unit = match.group(2)!;

      double value = double.tryParse(numStr) ?? 0;

      // Skip very small values or zero
      if (value < 0.1) return match.group(0)!;

      // Get the cleanest multiplier
      final multiplierInfo = _getCleanestMultiplier(value);

      // Create the expression with preserved unit
      final String placeholder = multiplierInfo['type'] == 'coffee'
          ? '<final_coffee_amount>'
          : '<final_water_amount>';

      return '(${multiplierInfo['formatted']} x $placeholder)$unit';
    });

    // Then handle large numbers without units
    return processedText.replaceAllMapped(largeNumberRegex, (match) {
      String numStr = match.group(1)!;
      double value = double.tryParse(numStr) ?? 0;

      // Skip very small values or zero
      if (value < 0.1) return match.group(0)!;

      // Skip numbers below threshold (10)
      if (value < 10) {
        return match.group(0)!;
      }

      // Get the cleanest multiplier
      final multiplierInfo = _getCleanestMultiplier(value);

      // Create the expression
      final String placeholder = multiplierInfo['type'] == 'coffee'
          ? '<final_coffee_amount>'
          : '<final_water_amount>';

      return '(${multiplierInfo['formatted']} x $placeholder)';
    });
  }

  // Process steps to convert numeric values to expressions
  List<BrewStepModel> _processStepsForSaving(List<BrewStepModel> steps) {
    return steps.map((step) {
      // Convert numeric values in the description to expressions
      String processedDescription =
          _convertNumericValuesToExpressions(step.description);

      // Return a new step with the processed description
      return BrewStepModel(
        order: step.order,
        description: processedDescription,
        time: step.time,
        timePlaceholder: step.timePlaceholder,
      );
    }).toList();
  }

  Future<void> _saveRecipe() async {
    if (!_isFirstPageValid || !_isSecondPageValid || _isSaving) {
      return; // Prevent double saves or saving invalid data
    }

    setState(() => _isSaving = true); // Set saving flag

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final currentUser = Supabase.instance.client.auth.currentUser;

    final totalBrewTime = Duration(
      minutes: _brewMinutes,
      seconds: _brewSeconds,
    );

    // Process steps to convert numeric values to expressions before saving
    final processedSteps = _processStepsForSaving(_steps);

    try {
      // --- Determine if updating or creating ---
      final bool isUpdating =
          widget.recipe != null && widget.recipe!.id != null;
      final String recipeId = isUpdating
          ? widget.recipe!.id!
          : 'usr-${currentUser?.id ?? 'anonymous'}-${DateTime.now().millisecondsSinceEpoch}'; // Generate new ID if creating

      // --- Prepare RecipeModel data ---
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
        vendorId: isUpdating
            ? widget.recipe!.vendorId
            : 'usr-${currentUser?.id ?? 'anonymous'}', // Set vendor ID for new recipes
        importId: isUpdating ? widget.recipe!.importId : null,
        isImported: isUpdating ? widget.recipe!.isImported : false,
        // isFavorite and other preference fields are handled separately
      );

      // --- Moderation Check (Only for UPDATING public user recipes) ---
      bool requiresModeration = false;
      bool moderationPassed = true; // Assume pass unless check runs and fails
      bool supabaseCheckFailed = false; // Flag for timeout/offline
      String moderationFailureReason =
          "Content flagged for review."; // Default reason

      if (isUpdating &&
          recipeId.startsWith('usr-') &&
          currentUser != null &&
          !currentUser.isAnonymous) {
        print("Checking if recipe $recipeId is public...");
        try {
          final response = await Supabase.instance.client
              .from('user_recipes')
              .select('ispublic')
              .eq('id', recipeId)
              .maybeSingle()
              .timeout(const Duration(seconds: 2)); // Short timeout

          if (response != null && response['ispublic'] == true) {
            print("Recipe $recipeId is public. Moderation check required.");
            requiresModeration = true;

            // Prepare text for moderation
            String combinedText = "";
            combinedText += "${recipeData.name}\n";
            combinedText += "${recipeData.shortDescription}\n";
            combinedText += "${recipeData.grindSize}\n";
            for (var step in recipeData.steps) {
              combinedText += "${step.description}\n";
            }
            combinedText = combinedText.trim();

            if (combinedText.isEmpty) {
              print("Warning: No text content found for moderation.");
              moderationPassed = true; // No text, passes automatically
            } else {
              print(
                  "Calling content moderation for recipe $recipeId update...");
              try {
                final moderationResponse =
                    await Supabase.instance.client.functions.invoke(
                  'content-moderation-gemini',
                  body: {'text': combinedText},
                ).timeout(const Duration(
                        seconds: 5)); // Longer timeout for function

                if (moderationResponse.status != 200 ||
                    moderationResponse.data == null) {
                  print(
                      "Moderation Error (Function Call): Recipe $recipeId. Status: ${moderationResponse.status}");
                  moderationPassed = false;
                  // Don't show error yet, just save locally
                } else {
                  final moderationResult =
                      moderationResponse.data as Map<String, dynamic>;
                  if (moderationResult['safe'] != true) {
                    moderationFailureReason = moderationResult['reason'] ??
                        "Content flagged for review."; // Capture the reason
                    print(
                        "Moderation Failed (Content Flagged): Recipe $recipeId. Reason: $moderationFailureReason");
                    moderationPassed = false;
                    // Show informational dialog AFTER local save
                  } else {
                    print("Moderation Passed: Recipe $recipeId");
                    moderationPassed = true;
                  }
                }
              } on TimeoutException {
                print("Moderation check timed out for recipe $recipeId.");
                supabaseCheckFailed = true;
                moderationPassed =
                    false; // Treat timeout as needing deferred check
              } catch (e) {
                print("Moderation check failed with error: $e");
                supabaseCheckFailed = true;
                moderationPassed =
                    false; // Treat error as needing deferred check
              }
            }
          } else {
            print(
                "Recipe $recipeId is not public or not found. No moderation needed.");
            moderationPassed = true;
          }
        } on TimeoutException {
          print("Checking public status timed out for recipe $recipeId.");
          supabaseCheckFailed = true;
          moderationPassed = false; // Assume moderation needed later
          requiresModeration = true; // Assume it might have been public
        } catch (e) {
          print("Error checking public status for recipe $recipeId: $e");
          supabaseCheckFailed = true;
          moderationPassed = false; // Assume moderation needed later
          requiresModeration = true; // Assume it might have been public
        }
      }

      // --- Save Locally (Always happens first) ---
      print("Saving recipe locally: $recipeId");
      if (isUpdating) {
        await userRecipeProvider.updateUserRecipe(recipeData);
      } else {
        await userRecipeProvider.createUserRecipe(recipeData);
      }
      print("Local save complete for recipe: $recipeId");

      // --- Clear Moderation Flag if Applicable ---
      // If moderation was required and passed, clear the local flag.
      if (requiresModeration && moderationPassed && !supabaseCheckFailed) {
        print("Clearing needs_moderation_review flag for $recipeId");
        // Use the dedicated method from DatabaseProvider
        await dbProvider.clearNeedsModerationReview(recipeId);
      }

      // --- Show Informational Dialog ONLY if Moderation Failed Immediately ---
      if (requiresModeration && !moderationPassed && !supabaseCheckFailed) {
        // Use the captured reason
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.saveLocallyModerationFailedTitle),
              content: Text(l10n.saveLocallyModerationFailedBody(
                  moderationFailureReason)), // Use the captured reason here
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.ok))
              ],
            ),
          );
        }
      }
      // --- Show Timeout/Offline Snackbar ---
      else if (supabaseCheckFailed) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(l10n.saveLocallyCheckLater)));
        }
      }

      // --- Sync to Supabase immediately if user is not anonymous ---
      if (currentUser != null && !currentUser.isAnonymous) {
        print("Syncing recipe to Supabase immediately: $recipeId");
        try {
          // Use the public wrapper method with a timeout to improve UX
          await dbProvider
              .syncUserRecipes(currentUser.id)
              .timeout(const Duration(seconds: 2), onTimeout: () {
            print("Immediate sync timed out, will sync on next app start");
            return;
          });

          print("Immediate sync completed for recipe: $recipeId");
        } catch (e) {
          print("Error during immediate sync: $e");
          // Don't show error to user, it will sync on next app start
        }
      }

      // --- Post-Save Navigation and Feedback ---
      if (mounted) {
        print("Navigating after save for recipe: $recipeId");
        if (isUpdating) {
          // If updating, just pop back to the previous screen (detail or list)
          if (context.router.canPop()) {
            context.router.pop();
          } else {
            // Fallback if somehow we can't pop while updating (shouldn't happen often)
            context.router.replace(RecipeDetailRoute(
                brewingMethodId: recipeData.brewingMethodId,
                recipeId: recipeData.id!));
          }
        } else {
          // If creating, always replace the current screen with the new recipe's detail screen
          context.router.replace(RecipeDetailRoute(
              brewingMethodId: recipeData.brewingMethodId,
              recipeId: recipeData.id!));
        }

        // Show generic success message (covers both create and update)
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(isUpdating
                  ? l10n.recipeCreationScreenUpdateSuccess
                  : l10n.recipeCreationScreenSaveSuccess)),
        );

        // Refresh provider state to reflect local changes
        await recipeProvider.fetchAllRecipes();
      }
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
        setState(() => _isSaving = false); // Reset saving flag
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
          // Wrap title in a Row
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentPage == 0
                ? Icons.edit
                : Icons.format_list_numbered), // Add icon based on page
            const SizedBox(width: 8), // Add spacing
            Text(_currentPage == 0 // Keep original text logic
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
                  _buildFirstPage(),
                  _buildSecondPage(),
                ],
              ),
            ),
    );
  }

  Widget _buildFirstPage() {
    final l10n = AppLocalizations.of(context)!; // Define l10n here
    return SingleChildScrollView(
      key: const PageStorageKey('recipeCreationFirstPage'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _recipeNameController,
            decoration: InputDecoration(
              labelText: l10n.recipeCreationScreenRecipeNameLabel,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _recipeName = value;
              });
              _validateFirstPage();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.recipeCreationScreenRecipeNameValidator;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _shortDescriptionController,
            decoration: InputDecoration(
              labelText: l10n.recipeCreationScreenShortDescriptionLabel,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _shortDescription = value;
              });
              _validateFirstPage();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.recipeCreationScreenShortDescriptionValidator;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l10n.recipeCreationScreenBrewingMethodLabel,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            value: _selectedBrewingMethodId,
            items: _brewingMethods.map((method) {
              return DropdownMenuItem<String>(
                value: method.brewingMethodId,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    method.brewingMethod,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBrewingMethodId = value;
              });
              _validateFirstPage();
            },
            validator: (value) {
              if (value == null) {
                return l10n.recipeCreationScreenBrewingMethodValidator;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.recipeCreationScreenCoffeeAmountLabel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _coffeeAmount.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _coffeeAmount = double.tryParse(value) ?? 0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.recipeCreationScreenRequiredValidator;
                    }
                    if (double.tryParse(value) == null) {
                      return l10n.recipeCreationScreenInvalidNumberValidator;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.recipeCreationScreenWaterAmountLabel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _waterAmount.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _waterAmount = double.tryParse(value) ?? 0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.recipeCreationScreenRequiredValidator;
                    }
                    if (double.tryParse(value) == null) {
                      return l10n.recipeCreationScreenInvalidNumberValidator;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.recipeCreationScreenWaterTempLabel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _waterTemp?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _waterTemp =
                          value.isEmpty ? null : double.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.recipeCreationScreenGrindSizeLabel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _grindSize,
                  onChanged: (value) {
                    setState(() {
                      _grindSize = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.recipeCreationScreenRequiredValidator;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(l10n.recipeCreationScreenTotalBrewTimeLabel),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.recipeCreationScreenMinutesLabel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _brewMinutes.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    setState(() {
                      _brewMinutes = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.recipeCreationScreenSecondsLabel,
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _brewSeconds.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    setState(() {
                      _brewSeconds = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onPressed: _isFirstPageValid
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            child: Text(l10n.recipeCreationScreenContinueButton),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPage() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollController: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _steps.length,
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex == 0) {
                  return;
                }
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                setState(() {
                  final BrewStepModel item = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, item);

                  // Update order of all steps
                  for (int i = 0; i < _steps.length; i++) {
                    _steps[i] = BrewStepModel(
                      order: i + 1,
                      description: _steps[i].description,
                      time: _steps[i].time,
                    );
                  }
                });
              },
              itemBuilder: (BuildContext context, int index) {
                final step = _steps[index];
                final isPreparationStep = index == 0;

                return StepCard(
                  key: ValueKey<int>(step.order),
                  step: step,
                  isPreparationStep: isPreparationStep,
                  l10n: l10n, // Pass l10n
                  onDescriptionChanged: (value) =>
                      _updateStepDescription(index, value),
                  onTimeChanged: isPreparationStep
                      ? null
                      : (value) => _updateStepTime(index, value),
                  onDelete: index > 1 ? () => _removeStep(index) : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.recipeCreationScreenAddStepButton),
                    onPressed: () {
                      _addStep();
                      // Scroll to the new card
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_steps.isNotEmpty) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    },
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                    // Disable button while saving
                    onPressed:
                        (_isSecondPageValid && !_isSaving) ? _saveRecipe : null,
                    child: _isSaving
                        ? SizedBox(
                            // Show progress indicator when saving
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : Text(l10n.recipeCreationScreenSaveRecipeButton),
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
  final AppLocalizations l10n; // Add l10n
  final Function(String) onDescriptionChanged;
  final Function(Duration)? onTimeChanged;
  final VoidCallback? onDelete;

  const StepCard({
    Key? key,
    required this.step,
    required this.isPreparationStep,
    required this.l10n, // Require l10n
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                    : Text(
                        l10n.recipeCreationScreenBrewStepTitle(
                            (step.order - 1).toString()),
                        style: Theme.of(context).textTheme.titleMedium,
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
              onChanged: onDescriptionChanged,
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
