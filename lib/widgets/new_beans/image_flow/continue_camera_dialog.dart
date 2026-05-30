import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

class ContinueCameraDialog extends StatelessWidget {
  const ContinueCameraDialog({super.key, required this.lastPhoto});

  final XFile lastPhoto;

  static const double _previewSize = 160;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Text(loc.takeAdditionalPhoto),
      content: SizedBox(
        width: _previewSize,
        height: _previewSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: kIsWeb
              ? Image.network(
                  lastPhoto.path,
                  width: _previewSize,
                  height: _previewSize,
                  fit: BoxFit.cover,
                )
              : FutureBuilder<Uint8List>(
                  future: File(lastPhoto.path).readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        width: _previewSize,
                        height: _previewSize,
                        fit: BoxFit.cover,
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
        ),
      ),
      actions: [
        AppTextButton(
          label: loc.no,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
        ),
        AppElevatedButton(
          label: loc.yes,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
        ),
      ],
    );
  }
}
