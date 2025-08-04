import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class ImagePickerSheet extends StatelessWidget {
  final void Function(ImageSource) onPick;

  const ImagePickerSheet({
    super.key,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(loc.takePhoto),
            onTap: () => onPick(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(loc.selectFromPhotos),
            onTap: () => onPick(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
