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
import '../app_router.gr.dart';
import '../theme/design_tokens.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
          // Persist which user this URL belongs to so we don't show it after sign-out
          await prefs.setString('user_profile_picture_user_id', userId);
        } else {
          await prefs.remove('user_profile_picture_url');
          await prefs.remove('user_profile_picture_user_id');
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
      // Persist the user id alongside the URL to avoid showing another user's avatar
      await prefs.setString('user_profile_picture_user_id', userId);

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
      await prefs.remove('user_profile_picture_user_id');

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

      // Sign out the user
      await Supabase.instance.client.auth.signOut();

      // Clear cached user-specific avatar info so it does not persist after sign-out
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_profile_picture_url');
        await prefs.remove('user_profile_picture_user_id');
      } catch (e) {
        // Ignore SharedPreferences errors, sign-out should still proceed
        print('Error clearing profile cache on sign out: $e');
      }

      // Sign back in anonymously
      await Supabase.instance.client.auth.signInAnonymously();

      // Navigate back to the root or home screen after sign out
      router.popUntilRoot(); // Or specific route like HomeRoute()
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

  @override
  void dispose() {
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
              // Sign Out Button - Styled like new_beans_screen.dart
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(
                    l10n.signOut, // Use localization
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _signOut, // Call the sign out method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    elevation: 2,
                  ),
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
