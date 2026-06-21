import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../models/brew_step_model.dart';
import '../models/brewing_method_model.dart';
import '../database/database.dart';
import '../widgets/recipe_creation/recipe_details_form.dart';
import '../widgets/recipe_creation/recipe_steps_form.dart';
import '../services/recipe_expression_service.dart';
import '../services/recipe_save_service.dart';
import '../services/recipe_navigation_service.dart';
import '../services/recipe_verification_client.dart';
import '../services/authentication_service.dart';
import '../widgets/unsaved_changes_dialog.dart';
import '../utils/app_logger.dart'; // Import AppLogger
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../services/analytics_service.dart';

@RoutePage()
class RecipeCreationScreen extends StatefulWidget {
  final RecipeModel? recipe;
  final String? brewingMethodId;
  final bool redirectToNewDetailOnSave;
  final bool popWithResultOnSave;

  const RecipeCreationScreen({
    Key? key,
    this.recipe,
    this.brewingMethodId,
    this.redirectToNewDetailOnSave = false,
    this.popWithResultOnSave = false,
  }) : super(key: key);

  @override
  State<RecipeCreationScreen> createState() => _RecipeCreationScreenState();
}

class _RecipeCreationScreenState extends State<RecipeCreationScreen>
    with AutomaticKeepAliveClientMixin {
  static const _aiReviewConsentPreferenceKey =
      'recipe_ai_review_consent_accepted';
  static const _aiReviewEnabledPreferenceKey = 'recipe_ai_review_enabled';

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
  bool _useAiReview = false;
  bool _aiReviewConsentAccepted = false;

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
                  step.description,
                  _coffeeAmount,
                  _waterAmount,
                ),
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
    _loadAiReviewConsent();

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
        bool preselectedIdIsValid =
            _selectedBrewingMethodId != null &&
            methods.any((m) => m.brewingMethodId == _selectedBrewingMethodId);

        if (!preselectedIdIsValid && methods.isNotEmpty) {
          _selectedBrewingMethodId = methods.first.brewingMethodId;
        } else if (methods.isEmpty) {
          _selectedBrewingMethodId = null;
        }
      } else if (widget.brewingMethodId != null) {
        // If creating and brewingMethodId is provided, use it if valid
        final found = methods.any(
          (m) => m.brewingMethodId == widget.brewingMethodId,
        );
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

  Future<void> _loadAiReviewConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final consentAccepted =
        prefs.getBool(_aiReviewConsentPreferenceKey) ?? false;
    final aiReviewEnabled =
        prefs.getBool(_aiReviewEnabledPreferenceKey) ?? false;
    if (!mounted) return;

    setState(() {
      _aiReviewConsentAccepted = consentAccepted;
      _useAiReview = consentAccepted && aiReviewEnabled;
    });
  }

  void _validateFirstPage() {
    setState(() {
      _isFirstPageValid =
          _recipeNameController.text.isNotEmpty &&
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

  bool _isAiReviewAvailable() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return currentUser != null && !currentUser.isAnonymous;
  }

  Future<void> _handleAiReviewChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (!value) {
      setState(() => _useAiReview = false);
      await prefs.setBool(_aiReviewEnabledPreferenceKey, false);
      _trackChanges();
      return;
    }

    if (!_isAiReviewAvailable()) {
      final l10n = AppLocalizations.of(context)!;
      final signedIn = await AuthenticationService.promptSignIn(
        context,
        bodyText: l10n.recipeCreationAiReviewUnavailable,
      );
      if (!mounted || !signedIn || !_isAiReviewAvailable()) {
        return;
      }
    }

    if (!_aiReviewConsentAccepted) {
      final accepted = await _showAiReviewConsentDialog();
      if (accepted != true) {
        return;
      }

      await prefs.setBool(_aiReviewConsentPreferenceKey, true);
      if (!mounted) return;
    }

    setState(() {
      _aiReviewConsentAccepted = true;
      _useAiReview = true;
    });
    await prefs.setBool(_aiReviewEnabledPreferenceKey, true);
    _trackChanges();
  }

  Future<bool?> _showAiReviewConsentDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.recipeCreationAiReviewConsentTitle),
        content: Text(l10n.recipeCreationAiReviewConsentBody),
        actions: [
          AppTextButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
          AppElevatedButton(
            label: l10n.recipeCreationAiReviewConsentAgree,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showAiReviewInfoDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.recipeCreationAiReviewConsentTitle),
        content: Text(l10n.recipeCreationAiReviewConsentBody),
        actions: [
          AppTextButton(
            label: l10n.ok,
            onPressed: () => Navigator.of(dialogContext).pop(),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  /// Returns true when the user chose to save without converting the
  /// problematic amounts ("Save as is").
  Future<bool> _showExpressionIssuesDialog(
    RecipeExpressionProcessingResult processing,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // _steps[0] is the always-present preparation step (order 1); visible
    // brew steps are numbered from order 2.
    String stepLabel(RecipeExpressionStepResult result) =>
        result.step.order == 1
        ? l10n.recipeCreationScreenPreparationStepTitle
        : l10n.recipeCreationScreenBrewStepTitle('${result.step.order - 1}');
    final issueRows = processing.stepResults
        .where((result) => result.issues.isNotEmpty)
        .map(
          (result) =>
              '${stepLabel(result)}: '
              '${result.issues.map((issue) => _localizedExpressionIssue(l10n, issue)).join(' ')}',
        )
        .join('\n\n');

    final saveAsIs = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.recipeCreationFormatIssuesTitle),
        content: SingleChildScrollView(
          child: Text(
            [
              l10n.recipeCreationFormatIssuesBody,
              if (issueRows.isNotEmpty) issueRows,
              l10n.recipeCreationFormatIssuesFixHint,
              l10n.recipeCreationFormatIssuesSaveAsIsHint,
            ].join('\n\n'),
          ),
        ),
        actions: [
          AppTextButton(
            label: l10n.recipeCreationFormatIssuesSaveAsIs,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
          SizedBox(
            height: 56,
            child: AppElevatedButton(
              label: l10n.recipeCreationFormatIssuesEditSteps,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              isFullWidth: false,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
    return saveAsIs ?? false;
  }

  String _localizedExpressionIssue(
    AppLocalizations l10n,
    RecipeExpressionIssue issue,
  ) {
    switch (issue.code) {
      case 'unsupported_placeholder':
        return l10n.recipeCreationFormatIssueUnsupportedPlaceholder;
      case 'invalid_scalable_expression':
        return l10n.recipeCreationFormatIssueInvalidExpression;
      case 'unbalanced_parentheses':
        return l10n.recipeCreationFormatIssueUnbalancedParentheses;
      case 'ambiguous_amount':
        final amount = issue.amount;
        return amount != null
            ? l10n.recipeCreationFormatIssueAmbiguousAmountValue(amount)
            : l10n.recipeCreationFormatIssueAmbiguousAmount;
      default:
        return l10n.recipeCreationFormatIssueUnknown;
    }
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

    final navigationContext = context;
    final confirmed = await _showDuplicateConfirmationDialog();

    if (confirmed != true) return; // User cancelled
    if (!navigationContext.mounted) return;

    try {
      await RecipeNavigationService.navigateToCopyRecipe(
        context: navigationContext,
        recipeToCopy: widget.recipe!,
      );
    } catch (e) {
      AppLogger.error("Error duplicating recipe", errorObject: e);
      if (navigationContext.mounted) {
        final l10n = AppLocalizations.of(navigationContext)!;
        ScaffoldMessenger.of(navigationContext).showSnackBar(
          SnackBar(content: Text(l10n.recipeCopyError(e.toString()))),
        );
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (!_isFirstPageValid || !_isSecondPageValid || _isSaving) {
      return;
    }
    final selectedBrewingMethodId = _selectedBrewingMethodId;
    if (selectedBrewingMethodId == null) {
      return;
    }
    // Update the order based on list index to reflect UI order
    for (int i = 0; i < _steps.length; i++) {
      _steps[i] = _steps[i].copyWith(order: i + 1);
    }

    setState(() => _isSaving = true);

    final saveContext = context;
    final l10n = AppLocalizations.of(saveContext)!;
    final scaffoldMessenger = ScaffoldMessenger.of(saveContext);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentLocale = Localizations.localeOf(saveContext);
    final appLocale = currentLocale.toLanguageTag();
    final sourceLanguageHint = currentLocale.languageCode;

    final totalBrewTime = Duration(
      minutes: _brewMinutes,
      seconds: _brewSeconds,
    );

    try {
      final bool isUpdate = widget.recipe != null;
      final String recipeId = isUpdate
          ? widget.recipe!.id
          : 'usr-${currentUser?.id ?? 'anonymous'}-${DateTime.now().millisecondsSinceEpoch}';

      final rawRecipeData = RecipeModel(
        id: recipeId,
        name: _recipeNameController.text,
        brewingMethodId: selectedBrewingMethodId,
        coffeeAmount: _coffeeAmount,
        waterAmount: _waterAmount,
        waterTemp: _waterTemp,
        grindSize: _grindSize,
        brewTime: totalBrewTime,
        shortDescription: _shortDescriptionController.text,
        steps: _steps,
        vendorId: isUpdate
            ? widget.recipe!.vendorId
            : 'usr-${currentUser?.id ?? 'anonymous'}',
        importId: isUpdate ? widget.recipe!.importId : null,
        isImported: isUpdate ? widget.recipe!.isImported : false,
        originalAuthorId: isUpdate ? widget.recipe!.originalAuthorId : null,
      );

      RecipeExpressionProcessingResult processing =
          RecipeExpressionService.processStepsForSavingDetailed(
            rawRecipeData.steps,
            _coffeeAmount,
            _waterAmount,
          );

      if (_useAiReview && _isAiReviewAvailable()) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.recipeCreationAiReviewRunning)),
        );
        try {
          final verified =
              await RecipeVerificationClient(
                Supabase.instance.client,
              ).verifyRecipe(
                recipe: rawRecipeData,
                appLocale: appLocale,
                sourceLanguageHint: sourceLanguageHint,
                consentToDiagnostics: _aiReviewConsentAccepted,
              );
          processing = RecipeExpressionService.processStepsForSavingDetailed(
            verified.steps,
            _coffeeAmount,
            _waterAmount,
          );
          if (!processing.hasBlockingIssues && mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(l10n.recipeCreationAiReviewApplied)),
            );
          }
        } catch (e) {
          AppLogger.warning(
            'AI recipe review failed; falling back to local validation: ${AppLogger.sanitize(e)}',
          );
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(l10n.recipeCreationAiReviewFailed)),
            );
          }
        }
      }

      if (processing.hasBlockingIssues) {
        if (!mounted) return;
        // Ambiguous amounts were left unconverted, so "save as is" stores
        // them as plain numbers that won't scale with servings.
        final saveAsIs = await _showExpressionIssuesDialog(processing);
        if (!saveAsIs) return;
      }

      final recipeData = rawRecipeData.copyWith(steps: processing.steps);

      if (!saveContext.mounted) {
        return;
      }
      await RecipeSaveService.save(
        recipeData,
        saveContext,
        isUpdate: isUpdate,
        redirectToNewDetailOnSave: widget.redirectToNewDetailOnSave,
        popWithResultOnSave: widget.popWithResultOnSave,
      );

      AnalyticsService.instance.track(
        'recipe_created',
        properties: {
          'brewing_method_id': _selectedBrewingMethodId,
          'steps_count': _steps.length,
        },
      );

      // Reset unsaved changes flag after successful save
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        // Milestone trigger removed — replaced by Pulse milestone.
      }
    } catch (e) {
      AppLogger.error("Error in _saveRecipe", errorObject: e);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.recipeCreationScreenSaveError(e.toString())),
          ),
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
              Text(
                _currentPage == 0
                    ? (widget.recipe != null
                          ? l10n.recipeCreationScreenEditRecipeTitle
                          : l10n.recipeCreationScreenCreateRecipeTitle)
                    : l10n.recipeCreationScreenRecipeStepsTitle,
              ),
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
                        aiReviewEnabled: _useAiReview,
                        aiReviewAvailable: _isAiReviewAvailable(),
                        onAiReviewChanged: _handleAiReviewChanged,
                        onAiReviewInfoPressed: _showAiReviewInfoDialog,
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
