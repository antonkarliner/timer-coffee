import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coffee_timer/widgets/new_beans/loading_overlay.dart';
import 'package:coffee_timer/widgets/new_beans/save_button.dart';
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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';

// Image flow controller and widgets
import 'package:coffee_timer/utils/new_beans/new_beans_image_controller.dart';
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

  // New: image flow controller
  late final NewBeansImageController _imageController;

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
      });
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
  }

  // Entry point to start the controller-driven image flow
  Future<void> _startImageFlow() async {
    final locale = Localizations.localeOf(context).toString();
    final user = Supabase.instance.client.auth.currentUser;
    await _imageController.start(
      context: context,
      locale: locale,
      userId: user?.id,
      onLoading: (v) => setState(() => isLoading = v),
      onData: (data) {
        _fillFields(data);
        collectedData = data;
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
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool('hasShownPopup', true);
                hasShownPopup = true;
                await _startImageFlow();
              },
              child: Text(loc.ok),
            ),
          ],
        );
      },
    );
  }

  void _fillFields(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _roasterController.text =
              data['roaster'] != 'Unknown' ? data['roaster'] ?? '' : '';
          _nameController.text =
              data['name'] != 'Unknown' ? data['name'] ?? '' : '';
          _originController.text =
              data['origin'] != 'Unknown' ? data['origin'] ?? '' : '';
          _elevationController.text = data['elevation'] != 'Unknown'
              ? data['elevation']?.toString() ?? ''
              : '';
          _cuppingScoreController.text = data['cuppingScore'] != 'Unknown'
              ? data['cuppingScore']?.toString() ?? ''
              : '';
          _notesController.text =
              data['notes'] != 'Unknown' ? data['notes'] ?? '' : '';
          _farmerController.text =
              data['farmer'] != 'Unknown' ? data['farmer'] ?? '' : '';
          _farmController.text =
              data['farm'] != 'Unknown' ? data['farm'] ?? '' : '';
          _tastingNotes = (data['tastingNotes'] as String?)
                  ?.split(', ')
                  .where((note) => note != 'Unknown')
                  .toList() ??
              [];
          variety = data['variety'] != 'Unknown' ? data['variety'] : null;
          processingMethod = data['processingMethod'] != 'Unknown'
              ? data['processingMethod']
              : null;
          roastLevel =
              data['roastLevel'] != 'Unknown' ? data['roastLevel'] : null;
          region = data['region'] != 'Unknown' ? data['region'] : null;
          harvestDate =
              data['harvestDate'] != 'Unknown' && data['harvestDate'] != null
                  ? DateTime.tryParse(data['harvestDate'])
                  : null;
          roastDate =
              data['roastDate'] != 'Unknown' && data['roastDate'] != null
                  ? DateTime.tryParse(data['roastDate'])
                  : null;
        });
      }
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
      default:
        return fieldName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);
    final locale = Localizations.localeOf(context).toString();
    final loc = AppLocalizations.of(context)!;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Required Fields Card
                  RequiredInfoCard(
                    roaster: _roasterController.text,
                    name: _nameController.text,
                    origin: _originController.text,
                    roasterOptions: coffeeBeansProvider.fetchCombinedRoasters(),
                    nameOptions: coffeeBeansProvider.fetchAllDistinctNames(),
                    originOptions:
                        coffeeBeansProvider.fetchCombinedOrigins(locale),
                    // Updating controller.text does not require setState; the field
                    // will reflect changes via its controller without rebuilding parent.
                    onRoasterChanged: (v) {
                      if (_roasterController.text != v) {
                        _roasterController.value =
                            _roasterController.value.copyWith(
                          text: v,
                          selection: TextSelection.collapsed(offset: v.length),
                          composing: TextRange.empty,
                        );
                      }
                    },
                    onNameChanged: (v) {
                      if (_nameController.text != v) {
                        _nameController.value = _nameController.value.copyWith(
                          text: v,
                          selection: TextSelection.collapsed(offset: v.length),
                          composing: TextRange.empty,
                        );
                      }
                    },
                    onOriginChanged: (v) {
                      if (_originController.text != v) {
                        _originController.value =
                            _originController.value.copyWith(
                          text: v,
                          selection: TextSelection.collapsed(offset: v.length),
                          composing: TextRange.empty,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),

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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates Card
                  DatesCard(
                    harvestDate: harvestDate,
                    roastDate: roastDate,
                    onHarvestDateChanged: (d) => harvestDate = d,
                    onRoastDateChanged: (d) => roastDate = d,
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 24),

                  // Save Button
                  Semantics(
                    identifier: 'saveButton',
                    label: isEditMode ? loc.save : loc.addCoffeeBeans,
                    child: SaveButton(
                      label: isEditMode ? loc.save : loc.addCoffeeBeans,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      onPressed: () async {
                        if (_roasterController.text.isNotEmpty &&
                            _nameController.text.isNotEmpty &&
                            _originController.text.isNotEmpty) {
                          final bean = CoffeeBeansModel(
                            id: 0, // This will be ignored for new beans
                            beansUuid: widget.uuid ??
                                _uuid.v7(), // Generate new UUID if not provided
                            roaster: _roasterController.text,
                            name: _nameController.text,
                            origin: _originController.text,
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
                            cuppingScore: _cuppingScoreController
                                    .text.isNotEmpty
                                ? double.tryParse(_cuppingScoreController.text)
                                : null,
                            notes: _notesController.text.isNotEmpty
                                ? _notesController.text
                                : null,
                            farmer: _farmerController.text.isNotEmpty
                                ? _farmerController.text
                                : null,
                            farm: _farmController.text.isNotEmpty
                                ? _farmController.text
                                : null,
                            isFavorite: false,
                            versionVector: isEditMode
                                ? (await coffeeBeansProvider
                                            .fetchCoffeeBeansByUuid(
                                                widget.uuid!))
                                        ?.versionVector ??
                                    VersionVector.initial(
                                            coffeeBeansProvider.deviceId)
                                        .toString()
                                : VersionVector.initial(
                                        coffeeBeansProvider.deviceId)
                                    .toString(),
                          );

                          String resultUuid;
                          if (isEditMode) {
                            await coffeeBeansProvider.updateCoffeeBeans(bean);
                            resultUuid = widget
                                .uuid!; // Use the existing UUID for edit mode
                          } else {
                            resultUuid =
                                await coffeeBeansProvider.addCoffeeBeans(bean);
                            await _insertBeansDataToSupabase(bean);
                          }

                          context.router.pop(
                              resultUuid); // Return the UUID of the beans record
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.fillRequiredFields)),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
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
    );
  }
}
