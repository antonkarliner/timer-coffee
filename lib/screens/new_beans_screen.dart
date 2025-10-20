import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coffee_timer/widgets/new_beans/loading_overlay.dart';
import 'package:coffee_timer/widgets/containers/sticky_action_bar.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coffee_beans_model.dart';
import '../providers/coffee_beans_provider.dart';
import 'package:coffee_timer/widgets/new_beans/optional_details/optional_details_card.dart';
import 'package:coffee_timer/widgets/new_beans/required_info_card.dart';
import 'package:coffee_timer/widgets/new_beans/dates_card.dart';
import 'package:coffee_timer/widgets/new_beans/additional_notes_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:uuid/uuid.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

// Image flow controller and widgets
import 'package:coffee_timer/controllers/new_beans_image_controller.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/image_picker_sheet.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/selected_images_sheet.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/continue_camera_dialog.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/error_dialog.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/collected_data_dialog.dart';

@RoutePage()
class NewBeansScreen extends StatefulWidget {
  final String? uuid;

  const NewBeansScreen({Key? key, this.uuid}) : super(key: key);

  @override
  _NewBeansScreenState createState() => _NewBeansScreenState();
}

class _NewBeansScreenState extends State<NewBeansScreen> {
  final TextEditingController _roasterController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _elevationController = TextEditingController();
  final TextEditingController _cuppingScoreController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  double? packageWeightGrams;
  final TextEditingController _farmerController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();
  final Uuid _uuid = Uuid();

  List<String> _tastingNotes = [];
  String? variety;
  String? processingMethod;
  String? roastLevel;
  String? region;
  DateTime? harvestDate;
  DateTime? roastDate;
  bool isEditMode = false;
  bool isLoading = false;
  Map<String, dynamic>? collectedData;
  bool hasShownPopup = false;
  bool hasCompletedFirstImageRecognition = false;

  // New: image flow controller
  late final NewBeansImageController _imageController;

  // Validation state
  bool _isFormValid = false;
  Map<String, String?> _fieldErrors = {};

  /// Validates the form and updates the validation state
  void _validateForm() {
    final bool wasValid = _isFormValid;

    // Clear previous errors
    final Map<String, String?> newErrors = {};

    // Validate required fields
    if (_roasterController.text.trim().isEmpty) {
      newErrors['roaster'] = 'Roaster is required';
    }

    if (_nameController.text.trim().isEmpty) {
      newErrors['name'] = 'Name is required';
    }

    if (_originController.text.trim().isEmpty) {
      newErrors['origin'] = 'Origin is required';
    }

    // Form is valid if there are no errors
    _isFormValid = newErrors.isEmpty;
    _fieldErrors = newErrors;

    // Only update state if validity changed to avoid unnecessary rebuilds
    if (wasValid != _isFormValid) {
      setState(() {});
    }
  }

  /// Shows error message for a specific field
  void _showFieldError(String fieldName) {
    if (_fieldErrors.containsKey(fieldName) &&
        _fieldErrors[fieldName] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_fieldErrors[fieldName]!)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.uuid != null) {
      isEditMode = true;
      _loadBeanDetails(widget.uuid!);
    }

    // Init image controller and multi-shot callback
    _imageController =
        NewBeansImageController(supabaseClient: Supabase.instance.client);
    _imageController.setAskTakeAnotherPhotoCallback(() async {
      final res = await showDialog<bool>(
        context: context,
        builder: (_) => const ContinueCameraDialog(),
      );
      return res ?? false;
    });

    _checkFirstTimePopup();

    // Add listeners to text controllers for validation
    _roasterController.addListener(_validateForm);
    _nameController.addListener(_validateForm);
    _originController.addListener(_validateForm);

    // Initial validation
    _validateForm();
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    _roasterController.removeListener(_validateForm);
    _nameController.removeListener(_validateForm);
    _originController.removeListener(_validateForm);

    // Dispose controllers
    _roasterController.dispose();
    _nameController.dispose();
    _originController.dispose();
    _elevationController.dispose();
    _cuppingScoreController.dispose();
    _notesController.dispose();
    _farmerController.dispose();
    _farmController.dispose();

    super.dispose();
  }

  Future<void> _loadBeanDetails(String uuid) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

    if (bean != null) {
      setState(() {
        _roasterController.text = bean.roaster;
        _nameController.text = bean.name;
        _originController.text = bean.origin;
        _elevationController.text = bean.elevation?.toString() ?? '';
        _cuppingScoreController.text = bean.cuppingScore?.toString() ?? '';
        _notesController.text = bean.notes ?? '';
        _farmerController.text = bean.farmer ?? '';
        _farmController.text = bean.farm ?? '';
        _tastingNotes = bean.tastingNotes?.split(', ') ?? [];
        variety = bean.variety;
        processingMethod = bean.processingMethod;
        roastLevel = bean.roastLevel;
        region = bean.region;
        harvestDate = bean.harvestDate;
        roastDate = bean.roastDate;
        packageWeightGrams = bean.packageWeightGrams;

        // Trigger validation after loading bean details
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validateForm();
        });
      });
    }
  }

  /// Saves the coffee beans data
  Future<void> _saveCoffeeBeans() async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    try {
      final bean = CoffeeBeansModel(
        id: 0, // This will be ignored for new beans
        beansUuid:
            widget.uuid ?? _uuid.v7(), // Generate new UUID if not provided
        roaster: _roasterController.text.trim(),
        name: _nameController.text.trim(),
        origin: _originController.text.trim(),
        variety: variety,
        tastingNotes:
            _tastingNotes.isNotEmpty ? _tastingNotes.join(', ') : null,
        processingMethod: processingMethod,
        elevation: _elevationController.text.isNotEmpty
            ? int.tryParse(_elevationController.text)
            : null,
        harvestDate: harvestDate,
        roastDate: roastDate,
        region: region,
        roastLevel: roastLevel,
        cuppingScore: _cuppingScoreController.text.isNotEmpty
            ? double.tryParse(_cuppingScoreController.text)
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        farmer: _farmerController.text.isNotEmpty
            ? _farmerController.text.trim()
            : null,
        farm: _farmController.text.isNotEmpty
            ? _farmController.text.trim()
            : null,
        packageWeightGrams: packageWeightGrams,
        isFavorite: false,
        versionVector: isEditMode
            ? (await coffeeBeansProvider.fetchCoffeeBeansByUuid(widget.uuid!))
                    ?.versionVector ??
                VersionVector.initial(coffeeBeansProvider.deviceId).toString()
            : VersionVector.initial(coffeeBeansProvider.deviceId).toString(),
      );

      String resultUuid;
      if (isEditMode) {
        await coffeeBeansProvider.updateCoffeeBeans(bean);
        resultUuid = widget.uuid!; // Use the existing UUID for edit mode
      } else {
        resultUuid = await coffeeBeansProvider.addCoffeeBeans(bean);
        await _insertBeansDataToSupabase(bean);
      }

      if (mounted) {
        context.router.pop(resultUuid); // Return the UUID of the beans record
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving coffee beans: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showImagePickerOptions() async {
    if (!hasShownPopup) {
      await _showFirstTimePopup();
    } else {
      await _startImageFlow();
    }
  }

  Future<void> _checkFirstTimePopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    hasShownPopup = prefs.getBool('hasShownPopup') ?? false;
    hasCompletedFirstImageRecognition =
        prefs.getBool('hasCompletedFirstImageRecognition') ?? false;
  }

  // Entry point to start the controller-driven image flow
  Future<void> _startImageFlow() async {
    final locale = Localizations.localeOf(context).toString();
    final user = Supabase.instance.client.auth.currentUser;

    // Determine if this is first-time image recognition
    final bool isFirstTime = !hasCompletedFirstImageRecognition;

    await _imageController.start(
      context: context,
      locale: locale,
      userId: user?.id,
      isFirstTime: isFirstTime,
      onLoading: (v) => setState(() => isLoading = v),
      onData: (data) async {
        // If server accidentally returns a wrapped payload like { "0": { ... } }, unwrap it.
        Map<String, dynamic> normalized = data;
        if (data.length == 1 && data.values.first is Map) {
          final onlyKey = data.keys.first;
          if (onlyKey == '0' || onlyKey == 'data' || onlyKey == 'result') {
            normalized = Map<String, dynamic>.from(data.values.first as Map);
          }
        }

        // Remove meta from the data used to fill fields
        normalized.remove('meta');

        _fillFields(normalized);
        collectedData = normalized;

        // Mark first-time image recognition as completed
        if (isFirstTime) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasCompletedFirstImageRecognition', true);
          setState(() {
            hasCompletedFirstImageRecognition = true;
          });
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => CollectedDataDialog(
              data: collectedData!,
              humanizeKey: _humanReadableFieldName,
            ),
          );
        });
      },
      onError: (msg) {
        final loc = AppLocalizations.of(context)!;
        String errorMessage;
        if (msg.contains('Invocation limit reached')) {
          errorMessage = loc.tokenLimitReached;
        } else if (msg.contains('No coffee labels detected')) {
          errorMessage = loc.noCoffeeLabelsDetected;
        } else {
          errorMessage = '${loc.unexpectedErrorOccurred}: $msg';
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => ErrorDialog(message: errorMessage),
          );
        });
      },
      onChooseSource: () async {
        return await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (_) => ImagePickerSheet(
            onPick: (src) => Navigator.pop(context, src),
          ),
        );
      },
      onShowPreview: (images, onConfirm, onBackToSelection) async {
        await showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
          ),
          builder: (_) => SelectedImagesSheet(
            initialImages: images,
            onConfirm: onConfirm,
            onBackToSelection: onBackToSelection,
          ),
        );
      },
    );
  }

  Future<void> _showFirstTimePopup() async {
    final loc = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.pleaseNote),
          content: Text(loc.firstTimePopupMessage),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool('hasShownPopup', true);
                  hasShownPopup = true;
                  await _startImageFlow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  loc.ok,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _fillFields(Map<String, dynamic> data) {
    // Normalize any wrapped shape again just in case
    Map<String, dynamic> d = data;
    if (d.length == 1 && d.values.first is Map) {
      final onlyKey = d.keys.first;
      if (onlyKey == '0' || onlyKey == 'data' || onlyKey == 'result') {
        d = Map<String, dynamic>.from(d.values.first as Map);
      }
    }
    d.remove('meta');

    // Sanitize Unknown -> null/empty handling, and coerce types
    String _str(dynamic v) =>
        (v == null || v == 'Unknown') ? '' : (v is String ? v : v.toString());
    String? _nullableStr(dynamic v) =>
        (v == null || v == 'Unknown') ? null : (v is String ? v : v.toString());
    int? _toInt(dynamic v) {
      if (v == null || v == 'Unknown') return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
      return null;
    }

    double? _toDouble(dynamic v) {
      if (v == null || v == 'Unknown') return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null || v == 'Unknown') return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _roasterController.text = _str(d['roaster']);
        _nameController.text = _str(d['name']);
        _originController.text = _str(d['origin']);

        final elev = _toInt(d['elevation']);
        _elevationController.text = elev?.toString() ?? '';

        final cup = _toDouble(d['cuppingScore']);
        _cuppingScoreController.text = cup?.toString() ?? '';

        _notesController.text = _str(d['notes']);
        _farmerController.text = _str(d['farmer']);
        _farmController.text = _str(d['farm']);

        final tn = _nullableStr(d['tastingNotes']);
        _tastingNotes = (tn == null || tn.trim().isEmpty)
            ? []
            : tn
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty && e != 'Unknown')
                .toList();

        variety = _nullableStr(d['variety']);
        processingMethod = _nullableStr(d['processingMethod']);
        roastLevel = _nullableStr(d['roastLevel']);
        region = _nullableStr(d['region']);

        harvestDate = _toDate(d['harvestDate']);
        roastDate = _toDate(d['roastDate']);
        packageWeightGrams = _toDouble(d['packageWeightGrams']);

        // Trigger validation after filling fields from image flow
        // Note: The listeners will automatically trigger validation
        // when the text controllers are updated
      });
    });
  }

  Future<void> _insertBeansDataToSupabase(CoffeeBeansModel bean) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = {
        'roaster': bean.roaster,
        'name': bean.name,
        'origin': bean.origin,
        'variety': bean.variety,
        'tasting_notes': bean.tastingNotes,
        'processing_method': bean.processingMethod,
        'region': bean.region,
        'cupping_score': bean.cuppingScore,
      };

      try {
        await Supabase.instance.client
            .from('global_coffee_beans')
            .insert(data)
            .timeout(const Duration(seconds: 3));
      } on TimeoutException catch (e) {
        print('Supabase request timed out: $e');
        // Optionally, handle the timeout, e.g., by retrying or queuing the request
      } catch (e) {
        print('Error inserting beans data to Supabase: $e');
        // Handle other exceptions as needed
      }
    }
  }

  String _humanReadableFieldName(String fieldName) {
    final loc = AppLocalizations.of(context)!;

    switch (fieldName) {
      case 'roaster':
        return loc.roaster;
      case 'name':
        return loc.name;
      case 'origin':
        return loc.origin;
      case 'variety':
        return loc.variety;
      case 'processingMethod':
        return loc.processingMethod;
      case 'elevation':
        return loc.elevation;
      case 'harvestDate':
        return loc.harvestDate;
      case 'roastDate':
        return loc.roastDate;
      case 'region':
        return loc.region;
      case 'roastLevel':
        return loc.roastLevel;
      case 'cuppingScore':
        return loc.cuppingScore;
      case 'tastingNotes':
        return loc.tastingNotes;
      case 'notes':
        return loc.notes;
      case 'farmer':
        return loc.farmer;
      case 'farm':
        return loc.farm;
      case 'packageWeightGrams':
        return loc.amountLeft;
      default:
        return fieldName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);
    final locale = Localizations.localeOf(context).toString();
    final loc = AppLocalizations.of(context)!;

    print('🏗️ BUILDING NewBeansScreen with locale: $locale');

    // Print cache stats for debugging (only in debug mode)
    if (!kReleaseMode) {
      coffeeBeansProvider.printCacheStats();
    }

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'newBeansAppBar',
          label: isEditMode ? loc.editCoffeeBeans : loc.addCoffeeBeans,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Coffeico.bean), // Add your desired icon here
              const SizedBox(width: 8), // Adjust spacing as needed
              Text(isEditMode ? loc.editCoffeeBeans : loc.addCoffeeBeans),
            ],
          ),
        ),
        actions: [
          if (!kIsWeb) // Hide camera button on web
            Semantics(
              identifier: 'showImagePickerButton',
              label: loc.showImagePicker,
              child: GestureDetector(
                onTap: _showImagePickerOptions, // Make badge also clickable
                child: Badge(
                  backgroundColor: Colors.transparent,
                  alignment: Alignment.topLeft,
                  offset: const Offset(0.5, 5.5), // Adjust the offset as needed
                  label: Icon(
                    Icons.auto_awesome,
                    size: 16, // Adjust the size as needed
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _showImagePickerOptions,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Tap outside to dismiss keyboard and any autocomplete overlays.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              // Only unfocus if tap is outside the currently focused render box.
              final currentFocus = FocusManager.instance.primaryFocus;
              if (currentFocus == null) return;
              final renderObject = currentFocus.context?.findRenderObject();
              if (renderObject is RenderBox) {
                final tapPos = details.globalPosition;
                final boxRect = renderObject.paintBounds
                    .shift(renderObject.localToGlobal(Offset.zero));
                final tappedInsideFocused = boxRect.contains(tapPos);
                if (!tappedInsideFocused) {
                  currentFocus.unfocus();
                }
              } else {
                // Fallback to safe unfocus check
                final scope = FocusScope.of(context);
                if (!scope.hasPrimaryFocus && scope.focusedChild != null) {
                  scope.unfocus();
                }
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use responsive layout for wider screens
                final isWideScreen = constraints.maxWidth > 800;
                final cardSpacing = isWideScreen ? 24.0 : 16.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
                  child: isWideScreen
                      ? _buildWideLayout(
                          coffeeBeansProvider, locale, loc, cardSpacing)
                      : _buildNarrowLayout(
                          coffeeBeansProvider, locale, loc, cardSpacing),
                );
              },
            ),
          ),
          if (isLoading)
            Semantics(
              identifier: 'analyzingOverlay',
              label: loc.analyzing,
              child: LoadingOverlay(label: loc.analyzing),
            ),
        ],
      ),
      bottomNavigationBar: KeyboardAwareStickyActionBar(
        child: StickyActionBar(
          primaryLabel: isEditMode ? loc.save : loc.addCoffeeBeans,
          primaryDisabled: !_isFormValid,
          isLoading: isLoading,
          onPrimaryPressed: _isFormValid
              ? () {
                  // Double-check validation before saving
                  if (!_isFormValid) {
                    // Show specific error for the first invalid field
                    if (_fieldErrors.containsKey('roaster')) {
                      _showFieldError('roaster');
                    } else if (_fieldErrors.containsKey('name')) {
                      _showFieldError('name');
                    } else if (_fieldErrors.containsKey('origin')) {
                      _showFieldError('origin');
                    }
                    return;
                  }

                  setState(() => isLoading = true);
                  _saveCoffeeBeans();
                }
              : null,
          semanticIdentifier: 'saveButton',
        ),
      ),
    );
  }

  // Build layout for narrow screens (single column)
  Widget _buildNarrowLayout(CoffeeBeansProvider coffeeBeansProvider,
      String locale, AppLocalizations loc, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Required Fields Card
        RequiredInfoCard(
          roaster: _roasterController.text,
          name: _nameController.text,
          origin: _originController.text,
          roasterOptions: coffeeBeansProvider.fetchCombinedRoasters(locale),
          nameOptions: coffeeBeansProvider.fetchAllDistinctNames(),
          originOptions: coffeeBeansProvider.fetchCombinedOrigins(locale),
          onRoasterChanged: (v) {
            if (_roasterController.text != v) {
              _roasterController.value = _roasterController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
              // Validation is automatically triggered by the listener
            }
          },
          onNameChanged: (v) {
            if (_nameController.text != v) {
              _nameController.value = _nameController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
              // Validation is automatically triggered by the listener
            }
          },
          onOriginChanged: (v) {
            if (_originController.text != v) {
              _originController.value = _originController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
              // Validation is automatically triggered by the listener
            }
          },
        ),
        SizedBox(height: spacing),

        // Optional Details Card
        Semantics(
          identifier: 'optionalSectionTitle',
          label: loc.optional,
          child: OptionalDetailsCard(
            // initial values
            variety: variety,
            region: region,
            farmer: _farmerController.text,
            farm: _farmController.text,
            processingMethod: processingMethod,
            roastLevel: roastLevel,
            tastingNotes: _tastingNotes,
            elevation: _elevationController.text.isNotEmpty
                ? int.tryParse(_elevationController.text)
                : null,
            cuppingScore: _cuppingScoreController.text.isNotEmpty
                ? double.tryParse(_cuppingScoreController.text)
                : null,
            // options (as Futures)
            varietyOptions: coffeeBeansProvider.fetchAllDistinctVarieties(),
            regionOptions: coffeeBeansProvider.fetchAllDistinctRegions(),
            farmerOptions: coffeeBeansProvider.fetchAllDistinctFarmers(),
            farmOptions: coffeeBeansProvider.fetchAllDistinctFarms(),
            processingMethodOptions:
                coffeeBeansProvider.fetchCombinedProcessingMethods(locale),
            roastLevelOptions:
                coffeeBeansProvider.fetchAllDistinctRoastLevels(),
            tastingNotesOptions:
                coffeeBeansProvider.fetchCombinedTastingNotes(locale),
            // callbacks
            onVarietyChanged: (v) => variety = v,
            onRegionChanged: (v) => region = v,
            onFarmerChanged: (v) {
              final newText = v ?? '';
              if (_farmerController.text != newText) {
                _farmerController.value = _farmerController.value.copyWith(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                  composing: TextRange.empty,
                );
              }
            },
            onFarmChanged: (v) {
              final newText = v ?? '';
              if (_farmController.text != newText) {
                _farmController.value = _farmController.value.copyWith(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                  composing: TextRange.empty,
                );
              }
            },
            onProcessingMethodChanged: (v) => processingMethod = v,
            onRoastLevelChanged: (v) => roastLevel = v,
            onTastingNotesChanged: (tags) => _tastingNotes = tags,
            onElevationChanged: (val) {
              final newText = val != null ? val.toString() : '';
              if (_elevationController.text != newText) {
                _elevationController.value =
                    _elevationController.value.copyWith(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                  composing: TextRange.empty,
                );
              }
            },
            onCuppingScoreChanged: (val) {
              final newText = val != null ? val.toString() : '';
              if (_cuppingScoreController.text != newText) {
                _cuppingScoreController.value =
                    _cuppingScoreController.value.copyWith(
                  text: newText,
                  selection: TextSelection.collapsed(offset: newText.length),
                  composing: TextRange.empty,
                );
              }
            },
            packageWeightGrams: packageWeightGrams,
            onPackageWeightGramsChanged: (value) {
              packageWeightGrams = value;
            },
          ),
        ),
        SizedBox(height: spacing),

        // Dates Card
        DatesCard(
          harvestDate: harvestDate,
          roastDate: roastDate,
          onHarvestDateChanged: (d) => harvestDate = d,
          onRoastDateChanged: (d) => roastDate = d,
        ),
        SizedBox(height: spacing),

        // Additional Notes Card
        AdditionalNotesCard(
          notes: _notesController.text,
          onNotesChanged: (v) {
            if (_notesController.text != v) {
              _notesController.value = _notesController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
            }
          },
        ),
        // Add extra padding at bottom to account for sticky action bar
        const SizedBox(height: 100),
      ],
    );
  }

  // Build layout for wide screens (two columns where appropriate)
  Widget _buildWideLayout(CoffeeBeansProvider coffeeBeansProvider,
      String locale, AppLocalizations loc, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Required Fields Card - always full width
        RequiredInfoCard(
          roaster: _roasterController.text,
          name: _nameController.text,
          origin: _originController.text,
          roasterOptions: coffeeBeansProvider.fetchCombinedRoasters(locale),
          nameOptions: coffeeBeansProvider.fetchAllDistinctNames(),
          originOptions: coffeeBeansProvider.fetchCombinedOrigins(locale),
          onRoasterChanged: (v) {
            if (_roasterController.text != v) {
              _roasterController.value = _roasterController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
              // Validation is automatically triggered by the listener
            }
          },
          onNameChanged: (v) {
            if (_nameController.text != v) {
              _nameController.value = _nameController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
              // Validation is automatically triggered by the listener
            }
          },
          onOriginChanged: (v) {
            if (_originController.text != v) {
              _originController.value = _originController.value.copyWith(
                text: v,
                selection: TextSelection.collapsed(offset: v.length),
                composing: TextRange.empty,
              );
              // Validation is automatically triggered by the listener
            }
          },
        ),
        SizedBox(height: spacing),

        // Two column layout for remaining cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: [
                  // Optional Details Card
                  Semantics(
                    identifier: 'optionalSectionTitle',
                    label: loc.optional,
                    child: OptionalDetailsCard(
                      // initial values
                      variety: variety,
                      region: region,
                      farmer: _farmerController.text,
                      farm: _farmController.text,
                      processingMethod: processingMethod,
                      roastLevel: roastLevel,
                      tastingNotes: _tastingNotes,
                      elevation: _elevationController.text.isNotEmpty
                          ? int.tryParse(_elevationController.text)
                          : null,
                      cuppingScore: _cuppingScoreController.text.isNotEmpty
                          ? double.tryParse(_cuppingScoreController.text)
                          : null,
                      // options (as Futures)
                      varietyOptions:
                          coffeeBeansProvider.fetchAllDistinctVarieties(),
                      regionOptions:
                          coffeeBeansProvider.fetchAllDistinctRegions(),
                      farmerOptions:
                          coffeeBeansProvider.fetchAllDistinctFarmers(),
                      farmOptions: coffeeBeansProvider.fetchAllDistinctFarms(),
                      processingMethodOptions: coffeeBeansProvider
                          .fetchCombinedProcessingMethods(locale),
                      roastLevelOptions:
                          coffeeBeansProvider.fetchAllDistinctRoastLevels(),
                      tastingNotesOptions:
                          coffeeBeansProvider.fetchCombinedTastingNotes(locale),
                      // callbacks
                      onVarietyChanged: (v) => variety = v,
                      onRegionChanged: (v) => region = v,
                      onFarmerChanged: (v) {
                        final newText = v ?? '';
                        if (_farmerController.text != newText) {
                          _farmerController.value =
                              _farmerController.value.copyWith(
                            text: newText,
                            selection:
                                TextSelection.collapsed(offset: newText.length),
                            composing: TextRange.empty,
                          );
                        }
                      },
                      onFarmChanged: (v) {
                        final newText = v ?? '';
                        if (_farmController.text != newText) {
                          _farmController.value =
                              _farmController.value.copyWith(
                            text: newText,
                            selection:
                                TextSelection.collapsed(offset: newText.length),
                            composing: TextRange.empty,
                          );
                        }
                      },
                      onProcessingMethodChanged: (v) => processingMethod = v,
                      onRoastLevelChanged: (v) => roastLevel = v,
                      onTastingNotesChanged: (tags) => _tastingNotes = tags,
                      onElevationChanged: (val) {
                        final newText = val != null ? val.toString() : '';
                        if (_elevationController.text != newText) {
                          _elevationController.value =
                              _elevationController.value.copyWith(
                            text: newText,
                            selection:
                                TextSelection.collapsed(offset: newText.length),
                            composing: TextRange.empty,
                          );
                        }
                      },
                      onCuppingScoreChanged: (val) {
                        final newText = val != null ? val.toString() : '';
                        if (_cuppingScoreController.text != newText) {
                          _cuppingScoreController.value =
                              _cuppingScoreController.value.copyWith(
                            text: newText,
                            selection:
                                TextSelection.collapsed(offset: newText.length),
                            composing: TextRange.empty,
                          );
                        }
                      },
                      packageWeightGrams: packageWeightGrams,
                      onPackageWeightGramsChanged: (value) {
                        packageWeightGrams = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing),
            // Right column
            Expanded(
              child: Column(
                children: [
                  // Dates Card
                  DatesCard(
                    harvestDate: harvestDate,
                    roastDate: roastDate,
                    onHarvestDateChanged: (d) => harvestDate = d,
                    onRoastDateChanged: (d) => roastDate = d,
                  ),
                  SizedBox(height: spacing),
                  // Additional Notes Card
                  AdditionalNotesCard(
                    notes: _notesController.text,
                    onNotesChanged: (v) {
                      if (_notesController.text != v) {
                        _notesController.value =
                            _notesController.value.copyWith(
                          text: v,
                          selection: TextSelection.collapsed(offset: v.length),
                          composing: TextRange.empty,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        // Add extra padding at bottom to account for sticky action bar
        const SizedBox(height: 100),
      ],
    );
  }
}
