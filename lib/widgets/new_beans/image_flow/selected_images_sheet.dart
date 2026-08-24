import 'dart:io';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SelectedImagesSheet extends StatefulWidget {
  const SelectedImagesSheet({
    super.key,
    required this.initialImages,
    required this.onConfirm,
    required this.onBackToSelection,
    this.onAddPhoto,
  });

  final List<XFile> initialImages;
  final Future<void> Function(List<XFile> confirmed) onConfirm;
  final Future<void> Function() onBackToSelection;
  final Future<XFile?> Function()? onAddPhoto;

  @override
  State<SelectedImagesSheet> createState() => _SelectedImagesSheetState();
}

class _SelectedImagesSheetState extends State<SelectedImagesSheet> {
  static const int _maxImages = 2;
  static const double _previewHeight = 220;

  late List<XFile> _images;
  bool _isAddingPhoto = false;

  @override
  void initState() {
    super.initState();
    _images = List<XFile>.from(widget.initialImages.take(_maxImages));
  }

  Future<void> _addPhoto() async {
    final addPhoto = widget.onAddPhoto;
    if (addPhoto == null || _images.length >= _maxImages || _isAddingPhoto) {
      return;
    }

    setState(() => _isAddingPhoto = true);
    try {
      final image = await addPhoto();
      if (!mounted || image == null) return;
      if (_images.every((existing) => existing.path != image.path)) {
        setState(() => _images.add(image));
      }
    } finally {
      if (mounted) setState(() => _isAddingPhoto = false);
    }
  }

  Future<void> _confirm() async {
    if (_images.isEmpty) return;

    // Let the tap feedback render before replacing the sheet with the loading
    // overlay owned by NewBeansScreen.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!mounted) return;

    Navigator.pop(context);
    await widget.onConfirm(List<XFile>.unmodifiable(_images));
  }

  Future<void> _backToSelection() async {
    Navigator.pop(context);
    await widget.onBackToSelection();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canAddPhoto =
        widget.onAddPhoto != null && _images.length < _maxImages;
    final analyzeLabel = _images.length < _maxImages
        ? loc.aiScanAnalyzePhoto
        : loc.aiScanAnalyzeTwoPhotos;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.base + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.aiScanPhotosTitle,
                    style: AppTextStyles.sectionHeader,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    '${_images.length}/$_maxImages',
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _images.length; index++) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PhotoPreview(
                      image: _images[index],
                      onRemove: () => setState(() => _images.removeAt(index)),
                    ),
                  ),
                ],
                if (canAddPhoto) ...[
                  if (_images.isNotEmpty) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _AddPhotoTile(
                      isLoading: _isAddingPhoto,
                      onTap: _addPhoto,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              loc.aiScanPhotoGuidance,
              style: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppIconSize.small,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    loc.aiScanTokenNote,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              identifier: 'analyzeSelectedPhotosButton',
              child: AppElevatedButton(
                label: analyzeLabel,
                onPressed: _images.isEmpty ? null : _confirm,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextButton(
              label: loc.backToSelection,
              onPressed: _backToSelection,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.image, required this.onRemove});

  final XFile image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SizedBox(
      height: _SelectedImagesSheetState._previewHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              identifier: 'selectedImage',
              label: loc.selectedImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: kIsWeb
                      ? Image.network(image.path, fit: BoxFit.contain)
                      : Image.file(File(image.path), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Semantics(
              button: true,
              label: loc.beanCoverPhotoRemove,
              child: Material(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.close, size: AppIconSize.medium),
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

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      identifier: 'addAnotherScanPhotoButton',
      label: loc.aiScanAddAnotherPhoto,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppStroke.border,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: isLoading ? null : onTap,
          child: SizedBox(
            height: _SelectedImagesSheetState._previewHeight,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: AppIconSize.large,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            loc.aiScanAddAnotherPhoto,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.fieldLabel.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
