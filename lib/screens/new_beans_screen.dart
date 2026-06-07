import 'dart:async';
import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coffee_timer/widgets/new_beans/loading_overlay.dart';
import 'package:coffee_timer/widgets/containers/sticky_action_bar.dart';
import 'package:coffee_timer/widgets/unsaved_changes_dialog.dart';
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
import 'package:coffee_timer/widgets/base_buttons.dart';
import '../utils/app_logger.dart'; // Import AppLogger
import '../services/onboarding_service.dart';
import '../services/bean_photo_service.dart';
import '../services/analytics_service.dart';
import '../services/authentication_service.dart';

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
  final TextEditingController _grindSizeController = TextEditingController();
  final Uuid _uuid = Uuid();

  // Store listener functions to properly remove them later
  late VoidCallback _roasterListener;
  late VoidCallback _nameListener;
  late VoidCallback _originListener;
  late VoidCallback _elevationListener;
  late VoidCallback _cuppingScoreListener;
  late VoidCallback _notesListener;
  late VoidCallback _farmerListener;
  late VoidCallback _farmListener;
  late VoidCallback _grindSizeListener;

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

  // Auth state listener — refreshes cover photo card when user signs in
  StreamSubscription<AuthState>? _authStateSubscription;

  // Photo cover state
  File? _pendingPhotoFile; // local file awaiting upload on save
  String? _photoUrl; // stored URL (loaded in edit mode or set after upload)
  List<XFile>?
  _lastOcrImages; // images from the last OCR scan (for cover prompt)
  bool _isSaving =
      false; // true while bean save + optional photo upload is in progress

  // Validation state
  bool _isFormValid = false;
  Map<String, String?> _fieldErrors = {};

  // Form change detection state
  bool _hasUnsavedChanges = false;

  // Initial values for change detection (used in edit mode)
  String? _initialRoaster;
  String? _initialName;
  String? _initialOrigin;
  String? _initialElevation;
  String? _initialCuppingScore;
  String? _initialNotes;
  String? _initialFarmer;
  String? _initialFarm;
  String? _initialGrindSize;
  List<String> _initialTastingNotes = [];
  String? _initialVariety;
  String? _initialProcessingMethod;
  String? _initialRoastLevel;
  String? _initialRegion;
  DateTime? _initialHarvestDate;
  DateTime? _initialRoastDate;
  double? _initialPackageWeightGrams;

  /// Updates the unsaved changes state without performing validation
  void _updateUnsavedChanges() {
    final bool hadUnsavedChanges = _hasUnsavedChanges;
    _hasUnsavedChanges = _checkForUnsavedChanges();

    // Only update state if unsaved changes status changed
    if (hadUnsavedChanges != _hasUnsavedChanges) {
      setState(() {});
    }
  }

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

    // Check for unsaved changes
    _hasUnsavedChanges = _checkForUnsavedChanges();

    // Only update state if validity or unsaved changes status changed
    if (wasValid != _isFormValid) {
      setState(() {});
    }
  }

  /// Checks if the form has unsaved changes
  bool _checkForUnsavedChanges() {
    // For new beans, consider any non-empty field as a change
    if (!isEditMode) {
      return _roasterController.text.trim().isNotEmpty ||
          _nameController.text.trim().isNotEmpty ||
          _originController.text.trim().isNotEmpty ||
          _elevationController.text.trim().isNotEmpty ||
          _cuppingScoreController.text.trim().isNotEmpty ||
          _notesController.text.trim().isNotEmpty ||
          _farmerController.text.trim().isNotEmpty ||
          _farmController.text.trim().isNotEmpty ||
          _grindSizeController.text.trim().isNotEmpty ||
          _tastingNotes.isNotEmpty ||
          variety != null ||
          processingMethod != null ||
          roastLevel != null ||
          region != null ||
          harvestDate != null ||
          roastDate != null ||
          packageWeightGrams != null;
    }

    // For editing beans, compare with initial values
    return _roasterController.text.trim() != (_initialRoaster ?? '') ||
        _nameController.text.trim() != (_initialName ?? '') ||
        _originController.text.trim() != (_initialOrigin ?? '') ||
        _elevationController.text.trim() != (_initialElevation ?? '') ||
        _cuppingScoreController.text.trim() != (_initialCuppingScore ?? '') ||
        _notesController.text.trim() != (_initialNotes ?? '') ||
        _farmerController.text.trim() != (_initialFarmer ?? '') ||
        _farmController.text.trim() != (_initialFarm ?? '') ||
        _grindSizeController.text.trim() != (_initialGrindSize ?? '') ||
        !_listsEqual(_tastingNotes, _initialTastingNotes) ||
        variety != _initialVariety ||
        processingMethod != _initialProcessingMethod ||
        roastLevel != _initialRoastLevel ||
        region != _initialRegion ||
        !(_datesEqual(harvestDate, _initialHarvestDate)) ||
        !(_datesEqual(roastDate, _initialRoastDate)) ||
        packageWeightGrams != _initialPackageWeightGrams;
  }

  /// Helper method to compare two lists for equality
  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper method to compare two DateTime objects for equality
  bool _datesEqual(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }

  /// Getter to expose the unsaved changes state
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Shows error message for a specific field
  void _showFieldError(String fieldName) {
    if (_fieldErrors.containsKey(fieldName) &&
        _fieldErrors[fieldName] != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_fieldErrors[fieldName]!)));
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
    _imageController = NewBeansImageController(
      supabaseClient: Supabase.instance.client,
    );
    _imageController.setAskTakeAnotherPhotoCallback((lastPhoto) async {
      final res = await showDialog<bool>(
        context: context,
        builder: (_) => ContinueCameraDialog(lastPhoto: lastPhoto),
      );
      return res ?? false;
    });

    _checkFirstTimePopup();

    // Initialize listener functions
    _roasterListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _nameListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _originListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _elevationListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _cuppingScoreListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _notesListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _farmerListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _farmListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };
    _grindSizeListener = () {
      _updateUnsavedChanges();
      _validateForm();
    };

    // Add listeners to all text controllers for validation and change detection
    _roasterController.addListener(_roasterListener);
    _nameController.addListener(_nameListener);
    _originController.addListener(_originListener);
    _elevationController.addListener(_elevationListener);
    _cuppingScoreController.addListener(_cuppingScoreListener);
    _notesController.addListener(_notesListener);
    _farmerController.addListener(_farmerListener);
    _farmController.addListener(_farmListener);
    _grindSizeController.addListener(_grindSizeListener);

    // Initial validation
    _validateForm();

    // Refresh cover photo card when auth state changes (e.g. after sign-in)
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    _roasterController.removeListener(_roasterListener);
    _nameController.removeListener(_nameListener);
    _originController.removeListener(_originListener);
    _elevationController.removeListener(_elevationListener);
    _cuppingScoreController.removeListener(_cuppingScoreListener);
    _notesController.removeListener(_notesListener);
    _farmerController.removeListener(_farmerListener);
    _farmController.removeListener(_farmListener);
    _grindSizeController.removeListener(_grindSizeListener);

    // Dispose controllers
    _roasterController.dispose();
    _nameController.dispose();
    _originController.dispose();
    _elevationController.dispose();
    _cuppingScoreController.dispose();
    _notesController.dispose();
    _farmerController.dispose();
    _farmController.dispose();
    _grindSizeController.dispose();
    _authStateSubscription?.cancel();

    super.dispose();
  }

  Future<void> _loadBeanDetails(String uuid) async {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
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
        _grindSizeController.text = bean.grindSize ?? '';
        _tastingNotes = bean.tastingNotes?.split(', ') ?? [];
        variety = bean.variety;
        processingMethod = bean.processingMethod;
        roastLevel = bean.roastLevel;
        region = bean.region;
        harvestDate = bean.harvestDate;
        roastDate = bean.roastDate;
        packageWeightGrams = bean.packageWeightGrams;

        // Store initial values for change detection
        _initialRoaster = bean.roaster;
        _initialName = bean.name;
        _initialOrigin = bean.origin;
        _initialElevation = bean.elevation?.toString() ?? '';
        _initialCuppingScore = bean.cuppingScore?.toString() ?? '';
        _initialNotes = bean.notes ?? '';
        _initialFarmer = bean.farmer ?? '';
        _initialFarm = bean.farm ?? '';
        _initialGrindSize = bean.grindSize ?? '';
        _initialTastingNotes = bean.tastingNotes?.split(', ') ?? [];
        _initialVariety = bean.variety;
        _initialProcessingMethod = bean.processingMethod;
        _initialRoastLevel = bean.roastLevel;
        _initialRegion = bean.region;
        _initialHarvestDate = bean.harvestDate;
        _initialRoastDate = bean.roastDate;
        _initialPackageWeightGrams = bean.packageWeightGrams;
        _photoUrl = bean.photoUrl;

        // Trigger validation after loading bean details
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _validateForm();
        });
      });
    }
  }

  /// Saves the coffee beans data
  Future<void> _saveCoffeeBeans() async {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );

    try {
      // Generate (or reuse) the bean UUID once — used for both photo path and bean record
      final beansUuid = widget.uuid ?? _uuid.v7();

      // If user selected a new photo, upload it now (before saving the bean)
      String? resolvedPhotoUrl = _photoUrl;
      if (_pendingPhotoFile != null) {
        final photoService = BeanPhotoService(Supabase.instance.client);
        final uploaded = await photoService.uploadPhoto(
          _pendingPhotoFile!,
          beansUuid,
        );
        if (uploaded != null) {
          resolvedPhotoUrl = uploaded;
        }
      }

      final bean = CoffeeBeansModel(
        id: 0, // This will be ignored for new beans
        beansUuid: beansUuid,
        roaster: _roasterController.text.trim(),
        name: _nameController.text.trim(),
        origin: _originController.text.trim(),
        variety: variety,
        tastingNotes: _tastingNotes.isNotEmpty
            ? _tastingNotes.join(', ')
            : null,
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
        grindSize: _grindSizeController.text.trim().isNotEmpty
            ? _grindSizeController.text.trim()
            : null,
        packageWeightGrams: packageWeightGrams,
        isFavorite: false,
        versionVector: isEditMode
            ? (await coffeeBeansProvider.fetchCoffeeBeansByUuid(
                    widget.uuid!,
                  ))?.versionVector ??
                  VersionVector.initial(coffeeBeansProvider.deviceId).toString()
            : VersionVector.initial(coffeeBeansProvider.deviceId).toString(),
        photoUrl: resolvedPhotoUrl,
      );

      String resultUuid;
      if (isEditMode) {
        await coffeeBeansProvider.updateCoffeeBeans(bean);
        resultUuid = widget.uuid!; // Use the existing UUID for edit mode

        // Update initial values after successful save in edit mode
        if (mounted) {
          setState(() {
            _initialRoaster = bean.roaster;
            _initialName = bean.name;
            _initialOrigin = bean.origin;
            _initialElevation = bean.elevation?.toString() ?? '';
            _initialCuppingScore = bean.cuppingScore?.toString() ?? '';
            _initialNotes = bean.notes;
            _initialFarmer = bean.farmer;
            _initialFarm = bean.farm;
            _initialGrindSize = bean.grindSize ?? '';
            _initialTastingNotes = bean.tastingNotes?.split(', ') ?? [];
            _initialVariety = bean.variety;
            _initialProcessingMethod = bean.processingMethod;
            _initialRoastLevel = bean.roastLevel;
            _initialRegion = bean.region;
            _initialHarvestDate = bean.harvestDate;
            _initialRoastDate = bean.roastDate;
            _initialPackageWeightGrams = bean.packageWeightGrams;
            _hasUnsavedChanges = false;
          });
        }
      } else {
        resultUuid = await coffeeBeansProvider.addCoffeeBeans(bean);
        await _insertBeansDataToSupabase(bean);
        AnalyticsService.instance.track(
          'beans_added',
          properties: {
            'has_roaster': _roasterController.text.trim().isNotEmpty,
            'has_origin': _originController.text.trim().isNotEmpty,
            'used_ocr': _lastOcrImages != null,
          },
        );
        if (mounted) {
          Provider.of<OnboardingService>(
            context,
            listen: false,
          ).completeMilestoneAddBeans();
        }
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
        setState(() => _isSaving = false);
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

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Show the data confirmation dialog first
          if (mounted) {
            await showDialog(
              context: context,
              builder: (_) => CollectedDataDialog(
                data: collectedData!,
                humanizeKey: _humanReadableFieldName,
              ),
            );
          }
          // After user dismisses, offer to save one of the OCR images as cover photo
          // (only if no cover photo already selected and we have images)
          if (mounted &&
              _pendingPhotoFile == null &&
              _photoUrl == null &&
              _lastOcrImages != null &&
              _lastOcrImages!.isNotEmpty) {
            await _showCoverPhotoPrompt(_lastOcrImages!);
          }
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
          builder: (_) =>
              ImagePickerSheet(onPick: (src) => Navigator.pop(context, src)),
        );
      },
      onShowPreview: (images, onConfirm, onBackToSelection) async {
        // Capture images for the cover photo prompt shown after OCR
        _lastOcrImages = images;
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

  /// Shows a dialog asking the user if they want to save one of the OCR images
  /// as the bean's cover photo.
  Future<void> _showCoverPhotoPrompt(List<XFile> images) async {
    if (!mounted || images.isEmpty || kIsWeb) return;
    final loc = AppLocalizations.of(context)!;

    final selected = await showDialog<XFile>(
      context: context,
      builder: (ctx) {
        XFile? dialogSelected;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(loc.beanCoverPhotoSavePromptTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.beanCoverPhotoSavePromptBody),
                const SizedBox(height: AppSpacing.base),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: images.map((xfile) {
                    final isSelected = dialogSelected?.path == xfile.path;
                    return GestureDetector(
                      onTap: () => setDialogState(() => dialogSelected = xfile),
                      child: Container(
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(ctx).colorScheme.primary,
                                  width: AppStroke.focus,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          child: Image.file(
                            File(xfile.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              AppTextButton(
                label: loc.cancel,
                onPressed: () => Navigator.pop(ctx),
                isFullWidth: false,
                height: AppButton.heightMedium,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
              ),
              AppElevatedButton(
                label: loc.done,
                onPressed: dialogSelected != null
                    ? () => Navigator.pop(ctx, dialogSelected)
                    : null,
                isFullWidth: false,
                height: AppButton.heightMedium,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.sm,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _pendingPhotoFile = File(selected.path);
        _photoUrl = null; // clear any existing stored URL
      });
    }
  }

  /// Picks a single photo from camera or gallery for the bean cover.
  Future<void> _pickCoverPhoto() async {
    if (kIsWeb) return;
    final loc = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.selectFromPhotos),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null && mounted) {
      setState(() {
        _pendingPhotoFile = File(picked.path);
        _photoUrl = null;
      });
    }
  }

  void _removeCoverPhoto() {
    setState(() {
      _pendingPhotoFile = null;
      _photoUrl = null;
    });
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
              child: AppElevatedButton(
                label: loc.ok,
                onPressed: () async {
                  Navigator.pop(context);
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool('hasShownPopup', true);
                  hasShownPopup = true;
                  await _startImageFlow();
                },
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 0,
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
        AppLogger.error('Supabase request timed out', errorObject: e);
        // Optionally, handle the timeout, e.g., by retrying or queuing the request
      } catch (e) {
        AppLogger.error(
          'Error inserting beans data to Supabase',
          errorObject: e,
        );
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

    AppLogger.debug('🏗️ BUILDING NewBeansScreen with locale: $locale');

    // Print cache stats for debugging (only in debug mode)
    if (!kReleaseMode) {
      coffeeBeansProvider.printCacheStats();
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_hasUnsavedChanges) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (_) => const UnsavedChangesDialog(),
          );

          if (shouldDiscard == true) {
            if (mounted) {
              context.router.pop();
            }
          }
        } else {
          // When there are no unsaved changes, allow navigation
          if (mounted) {
            context.router.pop();
          }
        }
      },
      child: Scaffold(
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
          actions: const [],
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
                  final boxRect = renderObject.paintBounds.shift(
                    renderObject.localToGlobal(Offset.zero),
                  );
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
                            coffeeBeansProvider,
                            locale,
                            loc,
                            cardSpacing,
                          )
                        : _buildNarrowLayout(
                            coffeeBeansProvider,
                            locale,
                            loc,
                            cardSpacing,
                          ),
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
            if (_isSaving)
              Semantics(
                identifier: 'savingOverlay',
                label: loc.saving,
                child: LoadingOverlay(label: loc.saving),
              ),
          ],
        ),
        bottomNavigationBar: KeyboardAwareStickyActionBar(
          child: StickyActionBar(
            primaryLabel: isEditMode ? loc.save : loc.addCoffeeBeans,
            primaryDisabled: !_isFormValid,
            isLoading: isLoading || _isSaving,
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

                    setState(() => _isSaving = true);
                    _saveCoffeeBeans();
                  }
                : null,
            semanticIdentifier: 'saveButton',
          ),
        ),
      ),
    );
  }

  Widget _buildAiScanButton(AppLocalizations loc) {
    return Semantics(
      identifier: 'showImagePickerButton',
      label: loc.showImagePicker,
      child: AppElevatedButton(
        label: loc.aiScanLabel,
        onPressed: _showImagePickerOptions,
        iconWidget: SizedBox(
          width: 30,
          height: 22,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                right: 0,
                child: Icon(
                  Icons.camera_alt,
                  size: 22,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Positioned(
                top: -4,
                left: 2,
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPhotoCard(AppLocalizations loc) {
    final user = Supabase.instance.client.auth.currentUser;
    final isSignedIn = user != null && !user.isAnonymous;
    final hasPhoto = _pendingPhotoFile != null || _photoUrl != null;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPhoto)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: _pendingPhotoFile != null
                        ? Image.file(
                            _pendingPhotoFile!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            SupabaseEndpointResolver.localizeStorageUrl(_photoUrl!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 160,
                              child: Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                  ),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _photoActionChip(
                          icon: Icons.edit,
                          label: loc.beanCoverPhotoChange,
                          onTap: _pickCoverPhoto,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _photoActionChip(
                          icon: Icons.delete_outline,
                          label: loc.beanCoverPhotoRemove,
                          onTap: _removeCoverPhoto,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (isSignedIn)
              GestureDetector(
                onTap: _pickCoverPhoto,
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        loc.beanCoverPhotoAdd,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => AuthenticationService.promptSignIn(context),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        loc.beanCoverPhotoSignInPrompt,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.small, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Build layout for narrow screens (single column)
  Widget _buildNarrowLayout(
    CoffeeBeansProvider coffeeBeansProvider,
    String locale,
    AppLocalizations loc,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!kIsWeb) ...[_buildAiScanButton(loc), SizedBox(height: spacing)],
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

        // Cover photo card (hidden on web)
        if (!kIsWeb) _buildCoverPhotoCard(loc),
        if (!kIsWeb) SizedBox(height: spacing),

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
            processingMethodOptions: coffeeBeansProvider
                .fetchCombinedProcessingMethods(locale),
            roastLevelOptions: coffeeBeansProvider
                .fetchAllDistinctRoastLevels(),
            tastingNotesOptions: coffeeBeansProvider.fetchCombinedTastingNotes(
              locale,
            ),
            // callbacks
            onVarietyChanged: (v) {
              variety = v;
              _updateUnsavedChanges();
              _validateForm();
            },
            onRegionChanged: (v) {
              region = v;
              _updateUnsavedChanges();
              _validateForm();
            },
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
            onProcessingMethodChanged: (v) {
              processingMethod = v;
              _updateUnsavedChanges();
              _validateForm();
            },
            onRoastLevelChanged: (v) {
              roastLevel = v;
              _updateUnsavedChanges();
              _validateForm();
            },
            onTastingNotesChanged: (tags) {
              _tastingNotes = tags;
              _updateUnsavedChanges();
              _validateForm();
            },
            onElevationChanged: (val) {
              final newText = val != null ? val.toString() : '';
              if (_elevationController.text != newText) {
                _elevationController.value = _elevationController.value
                    .copyWith(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: newText.length,
                      ),
                      composing: TextRange.empty,
                    );
              }
            },
            onCuppingScoreChanged: (val) {
              final newText = val != null ? val.toString() : '';
              if (_cuppingScoreController.text != newText) {
                _cuppingScoreController.value = _cuppingScoreController.value
                    .copyWith(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: newText.length,
                      ),
                      composing: TextRange.empty,
                    );
              }
            },
            packageWeightGrams: packageWeightGrams,
            onPackageWeightGramsChanged: (value) {
              packageWeightGrams = value;
              _updateUnsavedChanges();
              _validateForm();
            },
          ),
        ),
        SizedBox(height: spacing),

        // Dates Card
        DatesCard(
          harvestDate: harvestDate,
          roastDate: roastDate,
          onHarvestDateChanged: (d) {
            harvestDate = d;
            _updateUnsavedChanges();
            _validateForm();
          },
          onRoastDateChanged: (d) {
            roastDate = d;
            _updateUnsavedChanges();
            _validateForm();
          },
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
          grindSize: _grindSizeController.text,
          grindSizeOptions: coffeeBeansProvider.fetchAllDistinctGrindSizes(),
          onGrindSizeChanged: (v) {
            final newText = v ?? '';
            if (_grindSizeController.text != newText) {
              _grindSizeController.value = _grindSizeController.value.copyWith(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
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
  Widget _buildWideLayout(
    CoffeeBeansProvider coffeeBeansProvider,
    String locale,
    AppLocalizations loc,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!kIsWeb) ...[_buildAiScanButton(loc), SizedBox(height: spacing)],
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

        // Cover photo card (hidden on web)
        if (!kIsWeb) _buildCoverPhotoCard(loc),
        if (!kIsWeb) SizedBox(height: spacing),

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
                      varietyOptions: coffeeBeansProvider
                          .fetchAllDistinctVarieties(),
                      regionOptions: coffeeBeansProvider
                          .fetchAllDistinctRegions(),
                      farmerOptions: coffeeBeansProvider
                          .fetchAllDistinctFarmers(),
                      farmOptions: coffeeBeansProvider.fetchAllDistinctFarms(),
                      processingMethodOptions: coffeeBeansProvider
                          .fetchCombinedProcessingMethods(locale),
                      roastLevelOptions: coffeeBeansProvider
                          .fetchAllDistinctRoastLevels(),
                      tastingNotesOptions: coffeeBeansProvider
                          .fetchCombinedTastingNotes(locale),
                      // callbacks
                      onVarietyChanged: (v) {
                        variety = v;
                        _updateUnsavedChanges();
                        _validateForm();
                      },
                      onRegionChanged: (v) {
                        region = v;
                        _updateUnsavedChanges();
                        _validateForm();
                      },
                      onFarmerChanged: (v) {
                        final newText = v ?? '';
                        if (_farmerController.text != newText) {
                          _farmerController.value = _farmerController.value
                              .copyWith(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                                composing: TextRange.empty,
                              );
                        }
                      },
                      onFarmChanged: (v) {
                        final newText = v ?? '';
                        if (_farmController.text != newText) {
                          _farmController.value = _farmController.value
                              .copyWith(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                                composing: TextRange.empty,
                              );
                        }
                      },
                      onProcessingMethodChanged: (v) {
                        processingMethod = v;
                        _updateUnsavedChanges();
                        _validateForm();
                      },
                      onRoastLevelChanged: (v) {
                        roastLevel = v;
                        _updateUnsavedChanges();
                        _validateForm();
                      },
                      onTastingNotesChanged: (tags) {
                        _tastingNotes = tags;
                        _updateUnsavedChanges();
                        _validateForm();
                      },
                      onElevationChanged: (val) {
                        final newText = val != null ? val.toString() : '';
                        if (_elevationController.text != newText) {
                          _elevationController.value = _elevationController
                              .value
                              .copyWith(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
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
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                                composing: TextRange.empty,
                              );
                        }
                      },
                      packageWeightGrams: packageWeightGrams,
                      onPackageWeightGramsChanged: (value) {
                        packageWeightGrams = value;
                        _updateUnsavedChanges();
                        _validateForm();
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
                    onHarvestDateChanged: (d) {
                      harvestDate = d;
                      _updateUnsavedChanges();
                      _validateForm();
                    },
                    onRoastDateChanged: (d) {
                      roastDate = d;
                      _updateUnsavedChanges();
                      _validateForm();
                    },
                  ),
                  SizedBox(height: spacing),
                  // Additional Notes Card
                  AdditionalNotesCard(
                    notes: _notesController.text,
                    onNotesChanged: (v) {
                      if (_notesController.text != v) {
                        _notesController.value = _notesController.value
                            .copyWith(
                              text: v,
                              selection: TextSelection.collapsed(
                                offset: v.length,
                              ),
                              composing: TextRange.empty,
                            );
                      }
                    },
                    grindSize: _grindSizeController.text,
                    grindSizeOptions:
                        coffeeBeansProvider.fetchAllDistinctGrindSizes(),
                    onGrindSizeChanged: (v) {
                      final newText = v ?? '';
                      if (_grindSizeController.text != newText) {
                        _grindSizeController.value = _grindSizeController.value
                            .copyWith(
                              text: newText,
                              selection: TextSelection.collapsed(
                                offset: newText.length,
                              ),
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
