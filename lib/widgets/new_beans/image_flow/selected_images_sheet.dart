import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class SelectedImagesSheet extends StatefulWidget {
  final List<XFile> initialImages;
  final Future<void> Function(List<XFile> confirmed) onConfirm;
  final Future<void> Function() onBackToSelection;

  const SelectedImagesSheet({
    super.key,
    required this.initialImages,
    required this.onConfirm,
    required this.onBackToSelection,
  });

  @override
  State<SelectedImagesSheet> createState() => _SelectedImagesSheetState();
}

class _SelectedImagesSheetState extends State<SelectedImagesSheet> {
  late List<XFile> _images;

  @override
  void initState() {
    super.initState();
    _images = List<XFile>.from(widget.initialImages);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                loc.selectedImages,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _images.map((image) {
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
                                return const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                            },
                          ),
                    Positioned(
                      right: -10,
                      top: -10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _images.remove(image);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
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
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onBackToSelection();
                  },
                  child: Text(loc.backToSelection),
                ),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onConfirm(_images);
                  },
                  child: Text(loc.next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
