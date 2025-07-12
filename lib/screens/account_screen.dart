import 'dart:io'; // For Platform checks if needed later
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:flutter/foundation.dart'; // Import for compute
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/l10n/app_localizations.dart'; // For localization
import 'dart:convert'; // For base64 encoding
import 'dart:typed_data'; // For Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img; // Use prefix to avoid conflicts
import 'package:onesignal_flutter/onesignal_flutter.dart'; // For sign out
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../utils/icon_utils.dart';
import '../app_router.gr.dart';

enum TimePeriod { today, thisWeek, thisMonth, custom }

// --- Top-level function for image processing in isolate ---
Future<Uint8List> _processImageIsolate(Uint8List imageBytes) async {
  img.Image? image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception("Failed to decode image");
  }
  // Resize
  img.Image resizedImage = img.copyResize(image, width: 200, height: 200);
  // Encode to JPG instead of WebP
  return Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: 85)); // Use encodeJpg
}
// --- End top-level function ---

@RoutePage()
class AccountScreen extends StatefulWidget {
  final String userId;
  const AccountScreen({super.key, @PathParam('userId') required this.userId});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _displayName;
  String? _profilePictureUrl;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditMode = false; // State variable for edit mode

  // Default avatar URL
  final String _defaultAvatarUrl =
      'https://mprokbemdullwezwwscn.supabase.co/storage/v1/object/public/user-profile-pictures//avatar_default.webp';

  // Stats functionality variables
  TimePeriod _selectedPeriod = TimePeriod.today;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  late DatabaseProvider db;
  double totalGlobalCoffeeBrewed = 0.0;
  double temporaryUpdates = 0.0;
  bool includesToday = true;
  bool _globalStatsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    db = Provider.of<DatabaseProvider>(context, listen: false);
    _updateTimePeriod(_selectedPeriod);
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final supabase = Supabase.instance.client;
    final userId = widget.userId;

    if (userId == null || userId.isEmpty) {
      // Should not happen if screen is protected, but handle defensively
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not found."; // TODO: Localize
        });
      }
      return;
    }

    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    try {
      // Ensure profile exists or create default (only for current user)
      // If you want to allow editing only for current user, check here
      await dbProvider.ensureUserProfileExists(userId);

      // Attempt to fetch from Supabase
      final response = await supabase
          .from('user_public_profiles')
          .select('display_name, profile_picture_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _displayName = response['display_name'] as String?;
        _profilePictureUrl = response['profile_picture_url'] as String?;

        // Save to SharedPreferences as fallback (only for current user)
        if (_displayName != null) {
          await prefs.setString('user_display_name', _displayName!);
        } else {
          await prefs.remove('user_display_name');
        }
        if (_profilePictureUrl != null) {
          await prefs.setString(
              'user_profile_picture_url', _profilePictureUrl!);
        } else {
          await prefs.remove('user_profile_picture_url');
        }
      } else {
        // Fetch failed, try loading from SharedPreferences (only for current user)
        _displayName = prefs.getString('user_display_name');
        _profilePictureUrl = prefs.getString('user_profile_picture_url');
      }
    } catch (e) {
      print("Error loading profile: $e");
      // Load from SharedPreferences on error (only for current user)
      _displayName = prefs.getString('user_display_name');
      _profilePictureUrl = prefs.getString('user_profile_picture_url');
      _errorMessage =
          "Failed to load profile. Showing cached data."; // TODO: Localize
    } finally {
      // Use default if still null
      // Format default display name as User-<first 5 chars of ID>
      _displayName ??= 'User-${userId.substring(0, 5)}';
      _profilePictureUrl ??= _defaultAvatarUrl; // Default avatar

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Edit Display Name ---
  Future<void> _showEditDisplayNameDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController nameController =
        TextEditingController(text: _displayName);
    final formKey = GlobalKey<FormState>(); // For validation

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.editDisplayNameTitle), // Use localization
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.displayNameHint, // Use localization
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.displayNameEmptyError; // Use localization
                }
                if (value.length > 50) {
                  // Example length limit
                  return l10n.displayNameTooLongError; // Use localization
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, nameController.text.trim());
                }
              },
              child: Text(l10n.save), // Use localization
            ),
          ],
        );
      },
    );

    if (newName != null && newName != _displayName) {
      await _updateDisplayName(newName);
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final supabase = Supabase.instance.client;
    final userId = widget.userId;

    if (userId.isEmpty) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.errorUserNotLoggedIn))); // Use localization
      return;
    }

    setState(() => _isLoading = true); // Show loading indicator

    try {
      // 1. Moderation Check
      print("Calling content moderation for display name...");
      final moderationResponse = await supabase.functions.invoke(
        'content-moderation-gemini',
        body: {'text': newName},
      );

      print("Moderation response status: ${moderationResponse.status}");
      print("Moderation response data: ${moderationResponse.data}");

      if (moderationResponse.status != 200 || moderationResponse.data == null) {
        throw Exception(l10n.moderationErrorFunction); // Use localization
      }

      final moderationResult = moderationResponse.data as Map<String, dynamic>;
      if (moderationResult['safe'] != true) {
        final reason = moderationResult['reason'] ??
            l10n.moderationReasonDefault; // Use localization
        throw Exception(l10n.moderationFailedBody(reason)); // Use localization
      }
      print("Moderation passed for display name.");

      // 2. Update Supabase
      await supabase
          .from('user_public_profiles')
          .update({'display_name': newName}).eq('user_id', userId);

      // 3. Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_display_name', newName);

      // 4. Update local state
      if (mounted) {
        setState(() {
          _displayName = newName;
          _errorMessage = null; // Clear previous errors
        });
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(l10n.displayNameUpdateSuccess))); // Use localization
      }
    } catch (e) {
      print("Error updating display name: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(l10n
                .displayNameUpdateError(e.toString())))); // Use localization
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loading indicator
      }
    }
  }
  // --- End Edit Display Name ---

  // --- Edit Profile Picture ---
  Future<void> _pickAndCropImage() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return; // User cancelled

      // Crop the image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Square
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: l10n.edit, // Use localization
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          IOSUiSettings(
            title: l10n.edit, // Use localization
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rectX: 1.0, // Ensure square aspect ratio
            rectY: 1.0,
          ),
          // Simplify WebUiSettings - remove problematic parameters
          WebUiSettings(context: context),
        ],
      );

      if (croppedFile == null) return; // User cancelled cropping

      // Process and upload
      await _processAndUploadImage(croppedFile);
    } catch (e) {
      print("Error picking/cropping image: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                l10n.updatePictureError(e.toString())))); // Use localization
      }
    }
  }

  Future<void> _processAndUploadImage(CroppedFile croppedFile) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final supabase = Supabase.instance.client;
    final userId = widget.userId;

    if (userId.isEmpty) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.errorUserNotLoggedIn))); // Use localization
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Read bytes
      final imageBytes = await croppedFile.readAsBytes();

      // Decode, Resize, Encode to JPG (using compute for heavy task)
      // Use the top-level function _processImageIsolate with compute
      final Uint8List jpgBytes =
          await compute(_processImageIsolate, imageBytes);

      // Encode to Base64 for moderation
      final String base64Image = base64Encode(jpgBytes);

      // Moderation Check
      print("Calling content moderation for profile picture...");
      final moderationResponse = await supabase.functions.invoke(
        'content-moderation-gemini',
        body: {'imageBase64': base64Image}, // Send base64 image
      );

      print("Moderation response status: ${moderationResponse.status}");
      print("Moderation response data: ${moderationResponse.data}");

      if (moderationResponse.status != 200 || moderationResponse.data == null) {
        throw Exception(l10n.moderationErrorFunction); // Use localization
      }

      final moderationResult = moderationResponse.data as Map<String, dynamic>;
      if (moderationResult['safe'] != true) {
        final reason = moderationResult['reason'] ??
            l10n.moderationReasonDefault; // Use localization
        throw Exception(l10n.moderationFailedBody(reason)); // Use localization
      }
      print("Moderation passed for profile picture.");

      // Upload JPG bytes to Supabase Storage
      final imagePath = '$userId'; // Use user ID as file name
      await supabase.storage.from('user-profile-pictures').uploadBinary(
            imagePath,
            jpgBytes, // Upload JPG bytes
            fileOptions: const FileOptions(
              cacheControl: '3600', // Optional: Cache control
              upsert: true, // Overwrite existing file
              contentType: 'image/jpeg', // Specify content type as JPEG
            ),
          );

      // Get Public URL
      final imageUrlResponse = supabase.storage
          .from('user-profile-pictures')
          .getPublicUrl(imagePath);
      final newImageUrl =
          imageUrlResponse; // Assuming getPublicUrl returns the string directly

      // Update Supabase DB
      await supabase
          .from('user_public_profiles')
          .update({'profile_picture_url': newImageUrl}).eq('user_id', userId);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_picture_url', newImageUrl);

      // Update local state
      if (mounted) {
        setState(() {
          _profilePictureUrl = newImageUrl;
          _errorMessage = null;
        });
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(l10n.updatePictureSuccess))); // Use localization
      }
    } catch (e) {
      print("Error processing/uploading image: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                l10n.updatePictureError(e.toString())))); // Use localization
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- End Edit Profile Picture ---

  // --- Delete Profile Picture ---
  Future<void> _confirmAndDeletePicture() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePictureConfirmationTitle), // Use localization
        content: Text(l10n.deletePictureConfirmationBody), // Use localization
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePicture();
    }
  }

  Future<void> _deletePicture() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final supabase = Supabase.instance.client;
    final userId = widget.userId;

    if (userId.isEmpty) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.errorUserNotLoggedIn))); // Use localization
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update Supabase DB - set URL to null
      await supabase
          .from('user_public_profiles')
          .update({'profile_picture_url': null}).eq('user_id', userId);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_picture_url');

      // Update local state
      if (mounted) {
        setState(() {
          _profilePictureUrl = _defaultAvatarUrl; // Revert to default
          _errorMessage = null;
        });
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(l10n.deletePictureSuccess))); // Use localization
      }
    } catch (e) {
      print("Error deleting picture: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                l10n.deletePictureError(e.toString())))); // Use localization
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- End Delete Profile Picture ---

  // --- Sign Out ---
  Future<void> _signOut() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = context.router; // Capture router before async gap

    setState(() => _isLoading = true); // Show loading indicator

    try {
      if (!kIsWeb) {
        await OneSignal.logout(); // Logout from OneSignal on mobile
      }
      await Supabase.instance.client.auth.signOut();
      await Supabase.instance.client.auth
          .signInAnonymously(); // Sign back in anonymously

      // Navigate back to the root or home screen after sign out
      router.popUntilRoot(); // Or specific route like HomeRoute()

      // Show success message (optional, as navigation might be enough)
      // scaffoldMessenger.showSnackBar(
      //   SnackBar(content: Text(l10n.signOutSuccessful)), // Use localization
      // );
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content:
                  Text(l10n.errorSigningOut(e.toString()))), // Use localization
        );
      }
    } finally {
      // No need to set isLoading to false if we are navigating away
      // if (mounted) {
      //   setState(() => _isLoading = false);
      // }
    }
  }
  // --- End Sign Out ---

  // --- Stats Helper Methods ---
  DateTime _getStartDate(UserStatProvider provider, TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return provider.getStartOfToday();
      case TimePeriod.thisWeek:
        return provider.getStartOfWeek();
      case TimePeriod.thisMonth:
        return provider.getStartOfMonth();
      case TimePeriod.custom:
        return _customStartDate ?? DateTime.now();
    }
  }

  Future<void> _showDatePickerDialog(BuildContext context) async {
    var results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: [_customStartDate, _customEndDate],
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.length == 2) {
      setState(() {
        _customStartDate = results[0];
        _customEndDate = results[1];
        _selectedPeriod = TimePeriod.custom;
        DateTime startDate = _customStartDate ?? DateTime.now();
        DateTime endDate = _customEndDate ?? DateTime.now();
        includesToday = startDate.isBefore(DateTime.now()) &&
            endDate.isAfter(DateTime.now());
        fetchInitialTotal(startDate, endDate);
      });
    }
  }

  bool _isDateWithinRange(DateTime date) {
    DateTime startDate = _getStartDate(
        Provider.of<UserStatProvider>(context, listen: false), _selectedPeriod);
    DateTime endDate = _selectedPeriod == TimePeriod.custom
        ? (_customEndDate ?? DateTime.now())
        : DateTime.now();
    return date.isAfter(startDate) && date.isBefore(endDate);
  }

  void initializeRealtimeSubscription() {
    final channel = Supabase.instance.client.channel('public:global_stats');
    channel
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'global_stats',
            callback: (payload) {
              print('Change received: ${payload.newRecord}');
              if (payload.newRecord != null &&
                  payload.newRecord['water_amount'] != null) {
                String recipeId = payload.newRecord['recipe_id'].toString();
                _showRecipeBrewedSnackbar(
                    recipeId, context); // Use correct context

                // Parse the created_at date from the payload to check if the update is within the current range
                DateTime createdAt =
                    DateTime.parse(payload.newRecord['created_at']);
                double updateAmount =
                    (payload.newRecord['water_amount'] as num) / 1000;

                // Check if the created_at date is within the selected period
                if (_isDateWithinRange(createdAt)) {
                  setState(() {
                    totalGlobalCoffeeBrewed += updateAmount;
                  });
                }
              }
            })
        .subscribe();
  }

  Future<void> _showRecipeBrewedSnackbar(
      String recipeId, BuildContext ctx) async {
    String recipeName = await Provider.of<RecipeProvider>(ctx, listen: false)
        .getLocalizedRecipeName(recipeId);
    ScaffoldMessenger.of(ctx)
        .hideCurrentSnackBar(); // Clear any existing snack bars
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(ctx)!.someoneJustBrewed(recipeName)),
        behavior: SnackBarBehavior.floating, // Make it floating
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
        ),
        duration: const Duration(seconds: 10), // Show it for 10 seconds
        showCloseIcon: true, // Automatically include a close icon
      ),
    );
  }

  void _updateTimePeriod(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    DateTime startDate = _getStartDate(
        Provider.of<UserStatProvider>(context, listen: false), period);
    DateTime endDate = _selectedPeriod == TimePeriod.custom
        ? (_customEndDate ?? DateTime.now())
        : DateTime.now();
    includesToday =
        DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
    fetchInitialTotal(startDate, endDate);
  }

  Future<void> fetchInitialTotal(DateTime start, DateTime end) async {
    double initialTotal = await db.fetchGlobalBrewedCoffeeAmount(start, end);
    setState(() {
      totalGlobalCoffeeBrewed =
          initialTotal + (includesToday ? temporaryUpdates : 0.0);
      temporaryUpdates = 0.0; // Discard temporary updates after applying
    });
  }

  String _formatTimePeriod(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return AppLocalizations.of(context)!.timePeriodToday;
      case TimePeriod.thisWeek:
        return AppLocalizations.of(context)!.timePeriodThisWeek;
      case TimePeriod.thisMonth:
        return AppLocalizations.of(context)!.timePeriodThisMonth;
      case TimePeriod.custom:
        return AppLocalizations.of(context)!.timePeriodCustom;
      default:
        return "";
    }
  }

  Widget _buildCombinedStatsSection(BuildContext context) {
    final provider = Provider.of<UserStatProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    DateTime startDate = _getStartDate(provider, _selectedPeriod);
    DateTime endDate = _selectedPeriod == TimePeriod.custom
        ? (_customEndDate ?? DateTime.now())
        : DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header with Time Period Selector
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(l10n.yourStats,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(l10n.statsFor, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                DropdownButton<TimePeriod>(
                  value: _selectedPeriod,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold),
                  onChanged: (TimePeriod? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPeriod = newValue;
                      });
                      if (newValue == TimePeriod.custom) {
                        _showDatePickerDialog(context);
                      } else {
                        DateTime startDate = _getStartDate(
                            Provider.of<UserStatProvider>(context,
                                listen: false),
                            newValue);
                        DateTime endDate = newValue == TimePeriod.custom
                            ? (_customEndDate ?? DateTime.now())
                            : DateTime.now();
                        includesToday = startDate.isBefore(DateTime.now()) &&
                            endDate.isAfter(DateTime.now());
                        fetchInitialTotal(startDate, endDate);
                      }
                    }
                  },
                  items: <TimePeriod>[
                    TimePeriod.today,
                    TimePeriod.thisWeek,
                    TimePeriod.thisMonth,
                    TimePeriod.custom
                  ].map<DropdownMenuItem<TimePeriod>>((TimePeriod value) {
                    return DropdownMenuItem<TimePeriod>(
                      value: value,
                      child: Text(_formatTimePeriod(value)),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Coffee Brewed
            Text(l10n.coffeeBrewed,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder<double>(
              future:
                  provider.fetchBrewedCoffeeAmountForPeriod(startDate, endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    final coffeeBrewed =
                        snapshot.data! / 1000; // Convert to liters
                    return Text(
                        '${coffeeBrewed.toStringAsFixed(2)} ${l10n.litersUnit}');
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 16.0),
            // Most Used Recipes
            Text(l10n.mostUsedRecipes,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            FutureBuilder<List<String>>(
              future: provider.fetchTopRecipeIdsForPeriod(startDate, endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!
                          .map((id) => FutureBuilder<RecipeModel?>(
                                future: Provider.of<RecipeProvider>(context,
                                        listen: false)
                                    .getRecipeById(id),
                                builder: (context, recipeSnapshot) {
                                  if (recipeSnapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (recipeSnapshot.hasData) {
                                      Icon brewingMethodIcon =
                                          getIconByBrewingMethod(recipeSnapshot
                                              .data!.brewingMethodId);
                                      return InkWell(
                                        onTap: () => context.router.push(
                                            RecipeDetailRoute(
                                                brewingMethodId: recipeSnapshot
                                                    .data!.brewingMethodId,
                                                recipeId:
                                                    recipeSnapshot.data!.id)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            children: [
                                              brewingMethodIcon,
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                    recipeSnapshot.data!.name,
                                                    style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Text(l10n.unknownRecipe);
                                    }
                                  }
                                  return const CircularProgressIndicator();
                                },
                              ))
                          .toList(),
                    );
                  } else {
                    return Text(l10n.noData);
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 24.0),
            // Global Stats Expandable Section
            ExpansionTile(
              leading: const Icon(Icons.public),
              title: Text(l10n.globalStats,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8.0),
              onExpansionChanged: (expanded) {
                setState(() {
                  _globalStatsExpanded = expanded;
                });
                if (expanded) {
                  // Initialize real-time subscription when expanded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    initializeRealtimeSubscription();
                  });
                } else {
                  // Remove subscription when collapsed
                  Supabase.instance.client.removeAllChannels();
                }
              },
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coffee Brewed
                    Text(l10n.coffeeBrewed,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '${totalGlobalCoffeeBrewed.toStringAsFixed(2)} ${l10n.litersUnit}'),
                    const SizedBox(height: 16.0),
                    // Most Used Recipes
                    Text(l10n.mostUsedRecipes,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    FutureBuilder<List<String>>(
                      future: db.fetchGlobalTopRecipes(startDate, endDate),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          } else if (snapshot.data!.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: snapshot.data!
                                  .map((id) => FutureBuilder<RecipeModel?>(
                                        future: Provider.of<RecipeProvider>(
                                                context,
                                                listen: false)
                                            .getRecipeById(id),
                                        builder: (context, recipeSnapshot) {
                                          if (recipeSnapshot.connectionState ==
                                              ConnectionState.done) {
                                            if (recipeSnapshot.hasData) {
                                              Icon brewingMethodIcon =
                                                  getIconByBrewingMethod(
                                                      recipeSnapshot.data!
                                                          .brewingMethodId);
                                              return InkWell(
                                                onTap: () => context.router
                                                    .push(RecipeDetailRoute(
                                                        brewingMethodId:
                                                            recipeSnapshot.data!
                                                                .brewingMethodId,
                                                        recipeId: recipeSnapshot
                                                            .data!.id)),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Row(
                                                    children: [
                                                      brewingMethodIcon,
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                            recipeSnapshot
                                                                .data!.name,
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .secondary,
                                                                fontSize: 14),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Text(l10n.unknownRecipe);
                                            }
                                          }
                                          return const CircularProgressIndicator();
                                        },
                                      ))
                                  .toList(),
                            );
                          } else {
                            return Text(l10n.noData);
                          }
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // --- End Stats Helper Methods ---

  @override
  void dispose() {
    Supabase.instance.client
        .removeAllChannels(); // Make sure to properly dispose of all subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Define l10n here

    // Use loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if any
    if (_errorMessage != null && _displayName == null) {
      // Only show full error if no data at all
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // Main content
    return Scaffold(
      appBar: AppBar(
        title: Row(
          // Wrap title in a Row
          mainAxisSize: MainAxisSize.min, // Keep content centered
          children: [
            const Icon(Icons.account_circle), // Add the icon
            const SizedBox(width: 8), // Add spacing
            Text(l10n.account), // Keep the original text
          ],
        ),
        actions: [
          // Add Edit/Done button to AppBar
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            tooltip: _isEditMode ? l10n.save : l10n.edit, // Use localization
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _profilePictureUrl ?? _defaultAvatarUrl,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey),
                        fit: BoxFit.cover,
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  // Edit Avatar Button - Conditionally visible
                  if (_isEditMode)
                    Container(
                      margin:
                          const EdgeInsets.all(4), // Add some margin if needed
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .cardColor
                            .withOpacity(0.7), // Semi-transparent background
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 20, // Smaller icon
                          color: Theme.of(context)
                              .iconTheme
                              .color, // Use theme color
                        ),
                        padding: EdgeInsets.zero, // Remove default padding
                        constraints:
                            const BoxConstraints(), // Remove default constraints
                        tooltip: l10n.edit, // Use localization
                        onPressed:
                            _pickAndCropImage, // Call the image picker method
                      ),
                    ),
                  // Delete Avatar Button - Conditionally visible
                  if (_isEditMode &&
                      _profilePictureUrl != null &&
                      _profilePictureUrl != _defaultAvatarUrl)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.red.withOpacity(0.8),
                          child: const Icon(Icons.delete,
                              size: 20, color: Colors.white),
                        ),
                        onPressed:
                            _confirmAndDeletePicture, // Call delete confirmation
                        tooltip: l10n.deletePictureTooltip, // Use localization
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Display Name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    // Allow name to wrap if very long
                    child: Text(
                      _displayName ?? 'Loading...', // Show actual name
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Edit Name Button - Conditionally visible
                  if (_isEditMode)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed:
                          _showEditDisplayNameDialog, // Call the dialog method
                    ),
                ],
              ),
              const SizedBox(height: 30),
              // Combined Stats Section
              _buildCombinedStatsSection(context),
              const SizedBox(height: 40),
              // Sign Out Button - Styled like RecipeCreationScreen
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut), // Use localization
                onPressed: _signOut, // Call the sign out method
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width
                  backgroundColor:
                      Theme.of(context).colorScheme.primary, // Match style
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimary, // Match style
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15), // Match style
                ),
              ),
              const SizedBox(height: 20), // Padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
