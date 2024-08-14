import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coffee_beans_model.dart';
import '../providers/coffee_beans_provider.dart';
import '../widgets/autocomplete_input_field.dart';
import '../widgets/autocomplete_tag_input_field.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';

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
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, dynamic>? collectedData;
  bool hasShownPopup = false;

  @override
  void initState() {
    super.initState();
    if (widget.uuid != null) {
      isEditMode = true;
      _loadBeanDetails(widget.uuid!);
    }
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
      _showImagePickerModal();
    }
  }

  Future<void> _checkFirstTimePopup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    hasShownPopup = prefs.getBool('hasShownPopup') ?? false;
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
                _showImagePickerModal();
              },
              child: Text(loc.ok),
            ),
          ],
        );
      },
    );
  }

  void _showImagePickerModal() {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(loc.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(loc.selectFromPhotos),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    if (source == ImageSource.camera) {
      await _takePhotosWithCamera();
    } else {
      List<XFile>? images;
      if (kIsWeb) {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          images = [image];
        }
      } else {
        images = await _picker.pickMultiImage(imageQuality: 50);
      }

      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages = images!.take(2).toList(); // Limit to 2 images
        });
        _showSelectedImagesModal();
      }
    }
  }

  Future<void> _takePhotosWithCamera() async {
    while (_selectedImages.length < 2) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
      if (_selectedImages.length < 2) {
        bool continueTakingPhotos = await _showContinueTakingPhotosDialog();
        if (!continueTakingPhotos) break;
      }
    }
    _showSelectedImagesModal();
  }

  Future<bool> _showContinueTakingPhotosDialog() async {
    final loc = AppLocalizations.of(context)!;

    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.takeAdditionalPhoto),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.no),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.yes),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _showSelectedImagesModal() {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(loc.selectedImages,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _selectedImages.map((image) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            kIsWeb
                                ? Image.network(
                                    image.path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : FutureBuilder<Uint8List>(
                                    future: File(image.path).readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.hasData) {
                                        return Semantics(
                                          identifier: 'selectedImage',
                                          label: loc.selectedImage,
                                          child: Image.memory(
                                            snapshot.data!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    },
                                  ),
                            Positioned(
                              right: -10,
                              top: -10,
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedImages.remove(image);
                                  });
                                  setState(() {
                                    _selectedImages.remove(image);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showImagePickerOptions();
                          },
                          child: Text(loc.backToSelection),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _processSelectedImages();
                          },
                          child: Text(loc.next),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _processSelectedImages() async {
    setState(() {
      isLoading = true;
    });

    List<String> base64Images = [];
    for (var image in _selectedImages) {
      final resizedImage = await _resizeImage(File(image.path));
      final base64Image = base64Encode(resizedImage.readAsBytesSync());
      base64Images.add(base64Image);
    }

    if (base64Images.isNotEmpty) {
      await _invokeEdgeFunction(base64Images);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<File> _resizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    final resized = img.copyResize(
      image!,
      width: image.width > image.height ? 1024 : null,
      height: image.height > image.width ? 1024 : null,
    );

    final resizedImageFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(resized));

    return resizedImageFile;
  }

  Future<void> _invokeEdgeFunction(List<String> base64Images) async {
    final supabaseClient = Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    final locale = Localizations.localeOf(context).toString();
    final loc = AppLocalizations.of(context)!;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabaseClient.functions
          .invoke('parse-coffee-label-gemini', body: {
        'imagesBase64': base64Images,
        'locale': locale,
        'userId': user?.id,
      });

      print('Raw response data: ${response.data}');

      if (response.status != 200) {
        throw Exception('Error: Unexpected status code ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      print('Parsed data: $data');

      if (data.isNotEmpty) {
        if (data.containsKey('error')) {
          print('Error from Edge Function: ${data['error']}');
          String errorMessage;
          if (data['error'] == 'Invocation limit reached') {
            errorMessage = loc.tokenLimitReached;
          } else if (data['error'] == 'No coffee labels detected') {
            errorMessage = loc.noCoffeeLabelsDetected;
          } else {
            errorMessage = data['message'] ?? loc.unexpectedErrorOccurred;
          }
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorPopup(errorMessage);
            });
          }
        } else {
          print('Data entry: $data');
          _fillFields(data);
          collectedData = data;
          if (mounted) {
            setState(() {
              isLoading = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCollectedDataPopup();
            });
          }
        }
      } else {
        print('No data received from Edge Function');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        String errorMessage;
        if (error.toString().contains('Invocation limit reached')) {
          errorMessage = loc.tokenLimitReached;
        } else if (error.toString().contains('No coffee labels detected')) {
          errorMessage = loc.noCoffeeLabelsDetected;
        } else {
          errorMessage = '${loc.unexpectedErrorOccurred}: ${error.toString()}';
        }
        setState(() {
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorPopup(errorMessage);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showErrorPopup(String errorMessage) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.errorMessage), // Use a generic error message key
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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

  void _showCollectedDataPopup() {
    if (collectedData != null) {
      final loc = AppLocalizations.of(context)!;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(loc.collectedInformation),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: collectedData!.entries.map((entry) {
                  return Text(
                    '${_humanReadableFieldName(entry.key)}: ${entry.value ?? 'N/A'}',
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(loc.ok),
                ),
              ],
            );
          },
        );
      });
    }
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

      await Supabase.instance.client.from('global_coffee_beans').insert(data);
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Semantics(
                  identifier: 'roasterInputField',
                  label: loc.roaster,
                  child: AutocompleteInputField(
                    label: loc.roaster,
                    hintText: loc.enterRoaster,
                    initialOptions: coffeeBeansProvider.fetchCombinedRoasters(),
                    onSelected: (value) {
                      _roasterController.text = value;
                    },
                    initialValue: _roasterController.text,
                  ),
                ),
                Semantics(
                  identifier: 'nameInputField',
                  label: loc.name,
                  child: AutocompleteInputField(
                    label: loc.name,
                    hintText: loc.enterName,
                    initialOptions: coffeeBeansProvider.fetchAllDistinctNames(),
                    onSelected: (value) {
                      _nameController.text = value;
                    },
                    initialValue: _nameController.text,
                  ),
                ),
                Semantics(
                  identifier: 'originInputField',
                  label: loc.origin,
                  child: AutocompleteInputField(
                    label: loc.origin,
                    hintText: loc.enterOrigin,
                    initialOptions:
                        coffeeBeansProvider.fetchCombinedOrigins(locale),
                    onSelected: (value) {
                      _originController.text = value;
                    },
                    initialValue: _originController.text,
                  ),
                ),
                ExpansionTile(
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Semantics(
                      identifier: 'optionalSectionTitle',
                      label: loc.optional,
                      child: Text(
                        loc.optional,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  children: [
                    Semantics(
                      identifier: 'varietyInputField',
                      label: loc.variety,
                      child: AutocompleteInputField(
                        label: loc.variety,
                        hintText: loc.enterVariety,
                        initialOptions:
                            coffeeBeansProvider.fetchAllDistinctVarieties(),
                        onSelected: (value) {
                          variety = value;
                        },
                        initialValue: variety,
                      ),
                    ),
                    Semantics(
                      identifier: 'processingMethodInputField',
                      label: loc.processingMethod,
                      child: AutocompleteInputField(
                        label: loc.processingMethod,
                        hintText: loc.enterProcessingMethod,
                        initialOptions: coffeeBeansProvider
                            .fetchCombinedProcessingMethods(locale),
                        onSelected: (value) {
                          processingMethod = value;
                        },
                        initialValue: processingMethod,
                      ),
                    ),
                    Semantics(
                      identifier: 'roastLevelInputField',
                      label: loc.roastLevel,
                      child: AutocompleteInputField(
                        label: loc.roastLevel,
                        hintText: loc.enterRoastLevel,
                        initialOptions:
                            coffeeBeansProvider.fetchAllDistinctRoastLevels(),
                        onSelected: (value) {
                          roastLevel = value;
                        },
                        initialValue: roastLevel,
                      ),
                    ),
                    Semantics(
                      identifier: 'regionInputField',
                      label: loc.region,
                      child: AutocompleteInputField(
                        label: loc.region,
                        hintText: loc.enterRegion,
                        initialOptions:
                            coffeeBeansProvider.fetchAllDistinctRegions(),
                        onSelected: (value) {
                          region = value;
                        },
                        initialValue: region,
                      ),
                    ),
                    Semantics(
                      identifier: 'tastingNotesInputField',
                      label: loc.tastingNotes,
                      child: AutocompleteTagInputField(
                        label: loc.tastingNotes,
                        hintText: loc.enterTastingNotes,
                        initialOptions: coffeeBeansProvider
                            .fetchCombinedTastingNotes(locale),
                        onSelected: (tags) {
                          _tastingNotes = tags;
                        },
                        initialValues: _tastingNotes,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Semantics(
                          identifier: 'elevationTitle',
                          label: loc.elevation,
                          child: Text(loc.elevation,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ),
                    ),
                    Semantics(
                      identifier: 'elevationInputField',
                      label: loc.enterElevation,
                      child: TextFormField(
                        controller: _elevationController,
                        decoration:
                            InputDecoration(hintText: loc.enterElevation),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Semantics(
                          identifier: 'cuppingScoreTitle',
                          label: loc.cuppingScore,
                          child: Text(loc.cuppingScore,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ),
                    ),
                    Semantics(
                      identifier: 'cuppingScoreInputField',
                      label: loc.enterCuppingScore,
                      child: TextFormField(
                        controller: _cuppingScoreController,
                        decoration:
                            InputDecoration(hintText: loc.enterCuppingScore),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(
                        child: Semantics(
                          identifier: 'notesTitle',
                          label: loc.notes,
                          child: Text(loc.notes,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ),
                    ),
                    Semantics(
                      identifier: 'notesInputField',
                      label: loc.enterNotes,
                      child: TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(hintText: loc.enterNotes),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  identifier: 'harvestDateTitle',
                                  label: loc.harvestDate,
                                  child: Text(loc.harvestDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ),
                                Semantics(
                                  identifier: 'harvestDatePickerButton',
                                  label: loc.selectHarvestDate,
                                  child: TextButton(
                                    onPressed: () async {
                                      var results =
                                          await showCalendarDatePicker2Dialog(
                                        context: context,
                                        config:
                                            CalendarDatePicker2WithActionButtonsConfig(),
                                        dialogSize: const Size(325, 400),
                                        value: [harvestDate],
                                        borderRadius: BorderRadius.circular(15),
                                      );

                                      if (results != null &&
                                          results.isNotEmpty) {
                                        setState(() {
                                          harvestDate = results[0];
                                        });
                                      }
                                    },
                                    child: Text(harvestDate != null
                                        ? DateFormat.yMd().format(harvestDate!)
                                        : loc.selectDate),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  identifier: 'roastDateTitle',
                                  label: loc.roastDate,
                                  child: Text(loc.roastDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ),
                                Semantics(
                                  identifier: 'roastDatePickerButton',
                                  label: loc.selectRoastDate,
                                  child: TextButton(
                                    onPressed: () async {
                                      var results =
                                          await showCalendarDatePicker2Dialog(
                                        context: context,
                                        config:
                                            CalendarDatePicker2WithActionButtonsConfig(),
                                        dialogSize: const Size(325, 400),
                                        value: [roastDate],
                                        borderRadius: BorderRadius.circular(15),
                                      );

                                      if (results != null &&
                                          results.isNotEmpty) {
                                        setState(() {
                                          roastDate = results[0];
                                        });
                                      }
                                    },
                                    child: Text(roastDate != null
                                        ? DateFormat.yMd().format(roastDate!)
                                        : loc.selectDate),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Semantics(
                  identifier: 'saveButton',
                  label: isEditMode ? loc.save : loc.addCoffeeBeans,
                  child: ElevatedButton(
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
                          cuppingScore: _cuppingScoreController.text.isNotEmpty
                              ? double.tryParse(_cuppingScoreController.text)
                              : null,
                          notes: _notesController.text.isNotEmpty
                              ? _notesController.text
                              : null,
                          isFavorite: false,
                          versionVector: isEditMode
                              ? (await coffeeBeansProvider
                                          .fetchCoffeeBeansByUuid(widget.uuid!))
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
                    child: Text(isEditMode ? loc.save : loc.addCoffeeBeans),
                  ),
                )
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Semantics(
                  identifier: 'analyzingOverlay',
                  label: loc.analyzing,
                  child: Card(
                    color: Theme.of(context).colorScheme.background,
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.analyzing,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
